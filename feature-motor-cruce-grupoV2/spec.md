# Especificación Funcional: Motor de Cruce Automático de Ingresantes UNMSM

**PO**: Samuel Cisneros
**Equipo**: Grupo V2 (Vonex)
**Versión**: 2.2.0

## Resumen ejecutivo (≤150 palabras)

El motor de cruce automatiza la validación de identidades de los ingresantes de la UNMSM contra la base de datos de la academia Vonex (PostgreSQL). El sistema procesa un archivo CSV subido por el administrador, aplicando un filtro estricto sobre el campo `OBSERVACION` para importar solo a quienes alcanzaron vacante. Luego, normaliza nombres y realiza un cruce en dos fases: un cruce automático exacto (2 apellidos + 1 nombre) y una fase de coincidencia asistida por interfaz web (React) para registros con discrepancias leves (cabos sueltos). Finalmente, se genera un reporte consolidado en Excel con data enriquecida y un dashboard interactivo de analítica.

## 1. Contexto de negocio (qué y por qué)

- **Problema que resuelve:** El cruce manual de ingresantes a la UNMSM contra la base de alumnos inscritos en Vonex consume muchas horas operativas y es propenso a errores humanos (falsos positivos o ingresantes no identificados por errores de tipeo).
- **Por qué ahora / a quién impacta:** Impacta directamente al área de administración y marketing de la academia. Automatizar esto permite identificar en minutos a nuestros ingresantes reales, optimizar la publicidad del logro de la academia y asegurar reportes analíticos precisos sin sobrecargar al equipo.

## 2. User stories y criterios de aceptación

### US-1 (P1): Carga, Normalización y Filtrado de CSV

Como administrador, quiero subir el CSV de ingresantes para que el sistema filtre, normalice y agrupe los registros por fecha de examen.

- **AC-1.1 (Carga e Ignorado de Duplicados):** Dado un archivo CSV con múltiples fechas de examen, cuando se sube al sistema, entonces se divide en lotes independientes por fecha y se ignoran las fechas de examen que ya fueron procesadas previamente.
- **AC-1.2 (Normalización Forzada):** Dado un registro del CSV, cuando se normaliza el texto, entonces se convierte todo a MAYÚSCULAS, se eliminan las tildes y se reemplaza estrictamente la "Ñ" por "N".
- **AC-1.3 (Separación de Cadenas):** Dado un nombre normalizado, cuando se procesa, entonces se separan lógicamente los apellidos paterno, materno y nombres, reconociendo apellidos compuestos (ej. "DE LA CRUZ").
- **AC-1.4 (Filtrado por Observación):** Dado el archivo CSV, cuando se importa el lote, entonces el sistema conserva únicamente los registros cuyo campo `OBSERVACION` contenga exactamente `ALCANZO VACANTE`, descartando todos los demás.

### US-2 (P1): Consulta Directa a Base de Datos Academia

Como sistema, quiero consultar directamente la base de datos academia en PostgreSQL para validar a los alumnos 1. MATRICULADO, 2. PAGADO, 3. FINALIZADO, 4. SUSPENDIDO, 5. RETIRADO, 6. TRASLADADO, 7. STAND BY, 8. ANULADO.

- **AC-2.1 (Conexión Directa):** Dado un lote de ingresantes importados, cuando se inicia el cruce, entonces el sistema realiza consultas directas y eficientes a la base de datos `academia` en PostgreSQL para traer la información de matrícula histórica y vigente de los alumnos.
- **AC-2.2 (Jerarquía de Estados):** Dado un alumno que tiene múltiples registros históricos en la base de datos, cuando se cruza, entonces se resuelve su estado eligiendo el de mayor prioridad según la jerarquía inmutable: 1. MATRICULADO, 2. PAGADO, 3. FINALIZADO, 4. SUSPENDIDO, 5. RETIRADO, 6. TRASLADADO, 7. STAND BY, 8. ANULADO.

### US-3 (P2): Motor de Coincidencia (Match Engine)

Como administrador, quiero que el sistema realice un cruce en dos fases para emparejar ingresantes con precisión.

- **AC-3.1 (Match Exacto):** Dado un ingresante, cuando coincide exactamente en sus 2 apellidos y al menos 1 nombre con un alumno de la academia, entonces se asocia de forma automática en la base de datos con el estado `confirmado_automatico` de forma silenciosa.
- **AC-3.2 (Cabos Sueltos y Búsqueda Difusa):** Dado un ingresante que no tiene match exacto, cuando el motor calcula la similitud analizando la frecuencia de letras y distancia (como Levenshtein) con alumnos matriculados, entonces genera una lista ordenada de hasta 5 candidatos potenciales de la academia y marca al ingresante como `pendiente`.

### US-4 (P2): Interfaz de Validación Asistida (React)

Como administrador, quiero ver los cabos sueltos y seleccionar manualmente el alumno correcto mediante una interfaz interactiva.

- **AC-4.1 (Componente de Selección):** Dado un ingresante en estado `pendiente`, cuando se visualiza en la interfaz de React, entonces se muestra una fila con sus datos y un selector (`<select>`) ordenado de mayor a menor probabilidad con los alumnos similares sugeridos.
- **AC-4.2 (Confirmación y Persistencia):** Dado un candidato seleccionado del menú, cuando el administrador presiona confirmar, entonces el sistema guarda la asociación en la base de datos, cambiando el estado a `confirmado_manual` y actualizando la base de datos analítica.

### US-5 (P3): Exportación de Reporte Consolidado

Como usuario de negocio, quiero descargar un archivo Excel con la información unificada y analítica básica.

- **AC-5.1 (Estructura de Hoja 1 - Datos):** Dado un lote procesado, cuando se exporta a Excel, entonces las columnas A hasta M contienen los datos del CSV crudo original de ingresantes, y de la columna N en adelante se inserta la data enriquecida (Sede, Ciclo, Año, Estado).
- **AC-5.2 (Dashboard de Analítica - Hoja 2):** Dado el archivo Excel descargado, cuando se abre en la Hoja 2, entonces muestra gráficos analíticos pre-construidos y segmentadores dinámicos que filtran métricas por fecha de examen.

## 3. Requisitos no funcionales (NFR)

- **NFR-1 (Rendimiento de Carga):** El procesamiento completo de un CSV con 10,000 registros (filtrado, normalización y agrupación en lote) debe completarse en menos de 5 segundos.
- **NFR-2 (Tiempo de Respuesta API):** La consulta de candidatos (fuzzy match) para un ingresante en la interfaz interactiva debe responder en menos de 300 ms.
- **NFR-3 (Volumen de Carga):** El sistema debe soportar la subida de archivos CSV de hasta 20 MB sin fallar por límite de memoria (memory limit).

## 4. Casos borde

- **CB-1 (Campos Vacíos en CSV):** Si una fila del CSV tiene el campo de nombre o apellidos vacío, el sistema debe registrar el error en el log del lote y continuar procesando las siguientes filas.
- **CB-2 (Columnas Mapeadas Incorrectamente):** Si el CSV subido no cuenta con las columnas requeridas (`NOMBRES`, `OBSERVACION`, `FECHA_EXAMEN`), el sistema debe rechazar la carga de inmediato notificando al usuario.
- **CB-3 (Sin Candidatos Sugeridos):** Si el motor de coincidencia difusa no encuentra ningún alumno con similitud superior al 30%, el selector de React debe mostrar la opción "Sin coincidencias encontradas - Marcar como No Ingresado".

## 5. Assumptions

- **Asumimos que:** El formato de codificación del CSV es siempre UTF-8 o ISO-8859-1 (el backend convertirá a UTF-8 para evitar problemas de caracteres especiales).
- **Asumimos que:** La base de datos `academia` tiene índices creados sobre los campos de apellidos y nombres para garantizar tiempos de respuesta óptimos durante el cruce.

## 6. [NEEDS_CLARIFICATION] (máx 3)

- **[NC-1]:** ¿El filtrado por la palabra `ALCANZO VACANTE` en la observación debe ser estrictamente exacto y sensible a mayúsculas/minúsculas en el CSV crudo, o se normaliza el campo antes de aplicar el filtro?

## 7. Scope

- **DENTRO:**
  - Carga de archivos CSV, división en lotes por fecha de examen e ignorado de duplicados.
  - Normalización, separación de nombres y filtrado por observación `ALCANZO VACANTE`.
  - Cruce automático (match exacto) y cálculo de candidatos (match difuso).
  - Pantalla web en React para resolución manual de cabos sueltos.
  - Generación de reporte final en Excel con Hoja de Datos y Hoja de Dashboard.
- **FUERA (explícito):**
  - Descarga automática o scraping del CSV desde la página de admisión de la UNMSM.
  - Sincronización o actualización del estado del alumno directamente en la base de datos original de la academia (el reporte consolidado y los matches viven en tablas analíticas separadas).
