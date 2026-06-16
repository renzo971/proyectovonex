# Plan de Implementación: Motor de Cruce de Ingresantes UNMSM

**Rama**: `feature/motor-cruce-ingresantes` | **Fecha**: 2026-06-16 | **Especificación**: [spec-Diego.md](file:///c:/Users/rsantos_vonex/develop/proyectovonex/spec-Diego.md)

**Entrada**: Especificación de características de `/spec-Diego.md` y `constitution.md` (v2.0.0).

## Resumen

Desarrollar un sistema de cruce automático e interactivo que permita subir un archivo CSV de ingresantes a la UNMSM, normalizar los datos, realizar un cruce inicial exacto contra los alumnos matriculados en la base de datos `academia` (PostgreSQL) usando Laravel 13, calcular similitudes para los registros no coincidentes (cabos sueltos), permitir al usuario validar y enlazar estos registros mediante una interfaz asistida de React con selectores de alumnos similares, e ignorar fechas de examen ya procesadas en cargas subsecuentes. Finalmente, exportar un reporte unificado en Excel.

## Contexto Técnico

- **Lenguaje/Versión**: PHP ^8.4 (Tipado estricto, constructor property promotion, readonly clases)
- **Framework**: Laravel 13 (Modo API REST)
- **Base de Datos**: PostgreSQL (Base de datos: `academia`)
- **Interfaz**: React (Vite + TypeScript o ES6) consumiendo la API de Laravel
- **Pruebas**: Pest PHP (Última versión)
- **Metas de Rendimiento**: Procesar y cruzar lotes de hasta 5,000 ingresantes de forma fluida.

## Verificación de Constitución (Constitution Check)

- **Art. 2 · Preservación de Patrones**:
  - Toda la lógica de negocio del backend se encapsulará en clases de Acción en `app/Actions/`.
  - El frontend se desarrollará en React utilizando componentes funcionales y Hooks reactivos.
- **Art. 3 · Estándares de Calidad**:
  - Normalización forzada (MAYÚSCULAS, sin tildes, Ñ -> N).
  - Coincidencia inicial exacta estricta (`2 apellidos exactos + 1 nombre exacto`).
  - Cabos sueltos analizados mediante match difuso (fuzzy matching) interactivo.
  - Nombres técnicos en inglés; base de datos e interfaz de usuario en español.
- **Art. 7 · Límites (SIEMPRE HACER / NUNCA HACER)**:
  - Validar conexión a la DB `academia`.
  - Ignorar fechas ya cargadas.
  - No guardar coincidencias no exactas sin confirmación del usuario mediante la pantalla de React.
  - No escribir lógica compleja en controladores de Laravel 13 ni SQL directo en el frontend.

## Estructura del Proyecto

### Código Fuente

Modificaremos o crearemos los siguientes archivos bajo el patrón de Acciones:

```text
backend/ (Laravel 13)
├── app/
│   ├── Actions/
│   │   └── Cruce/
│   │       ├── NormalizarTextoAction.php (NUEVO - Quita tildes, convierte a mayúsculas, Ñ->N, separa apellidos/nombres)
│   │       ├── ProcesarCargaCsvAction.php (NUEVO - Lee CSV, extrae fecha de examen, crea lote, filtra fechas ya existentes)
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

## Flujo de Implementación Detallado

### Paso 1: Migración y Modelos en Laravel 13

Crear las tablas de migración y modelos para:

- `lotes_cruce`: id, fecha_examen, total_registros, estado, created_at.
- `ingresantes_cruce`: id, lote_cruce_id, alumno_id (nullable, FK academia), datos_csv (jsonb/campos individuales), estado_match (confirmado_automatico, confirmado_manual, no_ingresado, pendiente), porcentaje_similitud.

### Paso 2: Importación y Normalización (Acciones)

- `NormalizarTextoAction`: Implementa la limpieza de tildes, mayúsculas y la conversión estricta de "Ñ" a "N". Separa apellidos paterno/materno y nombres.
- `ProcesarCargaCsvAction`: Lee el archivo. Detecta la fecha del examen. Si la fecha ya existe en `lotes_cruce`, aborta o ignora para evitar duplicidad. Inserta los registros en `ingresantes_cruce` con estado `pendiente`.

### Paso 3: Cruce Automático (Paso 1)

- `RealizarCruceExactoAction`: Busca en la tabla de alumnos de la base `academia` registros vigentes donde coincidan exactamente los dos apellidos y al menos un nombre.
- Si hay coincidencia, vincula `alumno_id`, cambia estado a `confirmado_automatico` y enriquece los datos.

### Paso 4: Análisis de Cabos Sueltos (Similitud)

- `CalcularSimilitudesCabosAction`: Para cada registro que quedó `pendiente`, busca alumnos en la base de datos de la academia cuyos apellidos/nombres tengan coincidencia parcial.
- **Algoritmo de Similitud**: Se calculará un ranking de similitud utilizando comparación de coincidencia de frecuencia de caracteres, ordenando a los alumnos candidatos de mayor a menor probabilidad.

### Paso 5: Interfaz Web Interactiva en React

- Pantalla para listar los ingresantes del lote que están en estado `pendiente`.
- Cada fila del ingresante mostrará sus datos del CSV y a su lado un componente `<select>` con los top 5 alumnos candidatos ordenados por porcentaje de similitud.
- El usuario podrá seleccionar un candidato y presionar "Confirmar Match" (invocando a `GuardarCruceConfirmadoAction` vía API) o marcarlo como "No Ingresado".

### Paso 6: Exportación a Excel

- `ExportarExcelCruceAction`: Genera el archivo final uniendo los campos del CSV y los enriquecidos del alumno matriculado de la academia.
