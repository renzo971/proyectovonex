# Plan de Implementación: Motor de Cruce de Ingresantes UNMSM

**Rama**: `feature/motor-cruce-ingresantes` | **Fecha**: 2026-06-16 | **Especificación**: [spec.md](file:///c:/Users/rsantos_vonex/develop/proyectovonex/feature-motor-cruce-grupoV2/spec.md)

## Resumen ejecutivo (≤150 palabras)
Este plan define la implementación técnica del motor de cruce de ingresantes UNMSM en Laravel 13 y React. El objetivo es procesar cargas de CSV filtrando los estudiantes con vacante, normalizar nombres y realizar un cruce analítico en base de datos. La decisión técnica principal es el cruce en dos fases: un match automático exacto y un listado de cabos sueltos procesados mediante similitud de Levenshtein expuesto en un frontend reactivo para confirmación manual. No hay dudas abiertas críticas por el momento.

## 1. Enfoque técnico (alto nivel)
El motor se implementará mediante clases de Acción en Laravel 13 para leer, filtrar y normalizar nombres del CSV. Un proceso por lotes consultará la base PostgreSQL `academia` buscando coincidencias exactas. Aquellos sin match pasarán por un algoritmo difuso y se expondrán vía API REST a una interfaz React para validación asistida por el usuario.

## 2. Componentes / archivos afectados

Modificaremos o crearemos los siguientes archivos bajo el patrón de Acciones:

```text
backend/ (Laravel 13)
├── app/
│   ├── Actions/
│   │   └── Cruce/
│   │       ├── NormalizarTextoAction.php (NUEVO - Quita tildes, convierte a mayúsculas, Ñ->N, separa apellidos/nombres)
│   │       ├── ProcesarCargaCsvAction.php (NUEVO - Lee CSV, extrae fecha de examen, crea lote, filtra fechas ya existentes y filtra por campo OBSERVACION)
│   │       ├── RealizarCruceExactoAction.php (NUEVO - Cruza lote por 2 apellidos + 1 nombre contra alumnos matriculados)
│   │       ├── CalcularSimilitudesCabosAction.php (NUEVO - Ejecuta análisis exhaustivo de similitud de letras/Levenshtein)
│   │       ├── GuardarCruceConfirmadoAction.php (NUEVO - Registra coincidencias confirmadas manualmente por el usuario)
│   │       └── ExportarExcelCruceAction.php (NUEVO - Genera el reporte final de ingresantes confirmados)
│   ├── Models/
│   │   ├── IngresanteCruce.php (NUEVO - Modelo para registrar los ingresos y su estado de match)
│   │   ├── LoteCruce.php (NUEVO - Modelo para agrupar cargas por fecha de examen)
│   │   └── Alumno.php (MODIFICAR - si requiere relaciones de cruce)
│   └── Http/
│       └── Controllers/
│           └── CruceIngresantesController.php (NUEVO - Controlador delgado para subir CSV, listar cabos sueltos, guardar y exportar)
└── tests/ (Pruebas unitarias y funcionales en Pest)

frontend/ (React SPA con Vite)
├── src/
│   ├── components/
│   │   ├── FileUpload.jsx (NUEVO - Componente de carga de CSV)
│   │   ├── ExactMatchList.jsx (NUEVO - Componente para mostrar coincidencias automáticas)
│   │   └── UnmatchedRow.jsx (NUEVO - Fila interactiva para cabo suelto con select y confirmación)
│   ├── App.jsx (NUEVO - Coordinador de interfaz y layouts)
│   └── services/
│       └── api.js (NUEVO - Capa de comunicación con Laravel 13 API)
```

## 3. Decisiones de arquitectura (mini-ADR)

- **DECISIÓN:** Separar la lógica de negocio en clases de Acción independientes (`app/Actions/Cruce/`).
  - **POR QUÉ:** Cumple con el Art. 2 de la Constitución del Proyecto, facilita las pruebas unitarias aisladas y desacopla los controladores de Laravel.
  - **ALTERNATIVA DESCARTADA:** Escribir la lógica directamente en `CruceIngresantesController`, descartada porque infla el controlador y dificulta la reutilización o prueba aislada del motor analítico.
- **DECISIÓN:** Procesar la coincidencia en dos fases separando el cruce exacto y el difuso (fuzzy).
  - **POR QUÉ:** Garantiza cero falsos positivos en la base de datos para los matches obvios y permite la intervención humana asistida únicamente para los casos con discrepancias ortográficas.
  - **ALTERNATIVA DESCARTADA:** Forzar un auto-match difuso con un umbral alto, descartada por el riesgo de emparejar alumnos distintos con nombres similares de forma errónea.

## 4. Riesgos y dependencias

- **Riesgo:** Cuello de botella en el rendimiento al procesar lotes grandes de ingresantes en la búsqueda difusa.
  - **Mitigación:** Se limitará el ranking difuso a un número reducido de candidatos candidatos (top 5) utilizando índices en apellidos/nombres en PostgreSQL.
- **Dependencia:** Conexión y estabilidad de la base de datos externa de la academia en PostgreSQL. Si esta conexión falla, el lote debe pausarse limpiamente sin perder consistencia (marcando en pausa).

## 5. Trazabilidad: cada US del spec -> dónde se implementa en este plan

- **US-1** (Carga, Normalización y Filtrado de CSV) $\rightarrow$ Implementado en `ProcesarCargaCsvAction.php` y `NormalizarTextoAction.php`.
- **US-2** (Consulta Directa a BD) $\rightarrow$ Implementado en `LoteCruce` y `Alumno.php`.
- **US-3** (Motor de Coincidencia) $\rightarrow$ Implementado en `RealizarCruceExactoAction.php` y `CalcularSimilitudesCabosAction.php`.
- **US-4** (Interfaz React) $\rightarrow$ Implementado en `FileUpload.jsx`, `UnmatchedRow.jsx` y `GuardarCruceConfirmadoAction.php`.
- **US-5** (Reporte Excel) $\rightarrow$ Implementado en `ExportarExcelCruceAction.php`.

---

## Detalles Técnicos de Implementación

### Paso 1: Migración y Modelos en Laravel 13
Crear las tablas de migración y modelos para:
- `lotes_cruce`: id, fecha_examen, total_registros, estado, created_at.
- `ingresantes_cruce`: id, lote_cruce_id, alumno_id (nullable, FK academia), datos_csv (jsonb/campos individuales), estado_match (confirmado_automatico, confirmado_manual, no_ingresado, pendiente), porcentaje_similitud.

### Paso 2: Importación y Normalización (Acciones)
- `NormalizarTextoAction`: Implementa la limpieza de tildes, mayúsculas y la conversión estricta de "Ñ" a "N". Separa apellidos paterno/materno y nombres.
- `ProcesarCargaCsvAction`: Lee el archivo. Detecta la fecha del examen. Si la fecha ya existe en `lotes_cruce`, aborta o ignora para evitar duplicidad. Filtra los registros manteniendo únicamente los que en el campo `OBSERVACION` contengan exactamente `ALCANZO VACANTE`. Inserta los registros filtrados en `ingresantes_cruce` con estado `pendiente`.

### Paso 3: Cruce Automático (Paso 1)
- `RealizarCruceExactoAction`: Busca en la tabla de alumnos de la base `academia` registros vigentes donde coincidan exactamente los dos apellidos y al menos un nombre.
- Si hay coincidencia, vincula `alumno_id`, cambia estado a `confirmado_automatico` y enriquece los datos.

### Paso 4: Análisis de Cabos Sueltos (Similitud)
- `CalcularSimilitudesCabosAction`: Para cada registro que quedó `pendiente`, busca alumnos en la base de datos de la academia cuyos apellidos/nombres tengan coincidencia parcial.
- **Algoritmo de Similitud**: Se calculará un ranking de similitud utilizando comparación de coincidencia de frecuencia de caracteres y distancia de Levenshtein, ordenando a los alumnos candidatos de mayor a menor probabilidad.

### Paso 5: Interfaz Web Interactiva en React
- Pantalla para listar los ingresantes del lote que están en estado `pendiente`.
- Cada fila del ingresante mostrará sus datos del CSV y a su lado un componente `<select>` con los top 5 alumnos candidatos ordenados por porcentaje de similitud.
- El usuario podrá seleccionar un candidato y presionar "Confirmar Match" (invocando a `GuardarCruceConfirmadoAction` vía API) o marcarlo como "No Ingresado".

### Paso 6: Exportación a Excel
- `ExportarExcelCruceAction`: Genera el archivo final uniendo los campos del CSV y los enriquecidos del alumno matriculado de la academia.
