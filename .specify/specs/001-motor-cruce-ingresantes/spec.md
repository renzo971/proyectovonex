# Feature Specification: Motor de Cruce Automático de Ingresantes UNMSM

**Feature ID:** 001-motor-cruce-ingresantes
**Created:** 2026-06-16
**Business Context:** [business-context.md](business-context.md)
**PO:** Samuel Cisneros
**Equipo:** Grupo V2 (Vonex)
**Status:** Under Review
**Versión:** 2.5.0

---

## Executive Summary (≤150 palabras)

El motor de cruce automatiza la validación de identidades de los ingresantes de la UNMSM contra la base de datos de la academia Vonex (PostgreSQL). El sistema procesa un CSV (~27,000 filas × 12 columnas) subido por el administrador mediante un job asíncrono en cola Redis. Normaliza los campos y aplica el filtro `ALCANZO VACANTE`: los registros que lo cumplen se persisten en la tabla `ingresantes`; los demás, en `no_ingresantes`. Luego realiza un cruce en dos fases: un match exacto automático (2 apellidos + 1 nombre) y una fase de coincidencia difusa asistida por interfaz React para los cabos sueltos. Finalmente, genera un reporte consolidado en Excel con data enriquecida y un dashboard interactivo de analítica.

---

## User Stories

### US-001: Carga, Normalización y Filtrado de CSV

**As a** Administrador de la academia Vonex
**I want** subir el CSV oficial de ingresantes UNMSM con los campos estructurados (CODIGO, APELLIDOS, NOMBRES, EAP, PUNTAJE, MERITO, OBSERVACION, TIPO, MODALIDAD, UNIVERSIDAD, PERIODO, FECHA) para que el sistema filtre, normalice y agrupe los registros por fecha de examen
**So that** solo los ingresantes con vacante confirmada sean procesados, eliminando errores de carga manual y duplicados

**Priority:** P1 (Must Have)
**Story Points:** 5

#### Acceptance Criteria

- [ ] **AC-001:** Dado un archivo CSV con múltiples fechas de examen, cuando se sube al sistema, entonces se divide en lotes independientes por fecha de examen, se eliminan automáticamente las filas idénticas duplicadas dentro del lote, y se ignoran silenciosamente las fechas que ya fueron procesadas previamente, registrando el salto en el log del lote.
- [ ] **AC-001a:** El archivo CSV debe contener exactamente las siguientes 12 columnas: `CODIGO`, `APELLIDOS`, `NOMBRES`, `EAP`, `PUNTAJE`, `MERITO`, `OBSERVACION`, `TIPO`, `MODALIDAD`, `UNIVERSIDAD`, `PERIODO`, `FECHA`. Si falta alguna columna o tiene nombres incorrectos, se aborta la importación.
- [ ] **AC-001b:** El sistema valida la codificación del archivo CSV y acepta únicamente UTF-8 o ISO-8859-1; en caso contrario la importación se aborta con error descriptivo.
- [ ] **AC-001c:** El endpoint de carga rechaza archivos mayores a 20 MB con HTTP 413 y registra el motivo en el log del lote.
- [ ] **AC-001d:** Si `ProcessCsvBatchJob` falla de forma no recuperable, el job se registra en `failed_jobs`, el `lote_cruce` se marca con estado `error`, y no se duplican registros ya persistidos.
- [ ] **AC-001e:** El procesamiento en cola (Redis) tolera reinicios del worker: jobs fallidos quedan en `failed_jobs` y el lote mantiene consistencia para reintentos posteriores.
- [ ] **AC-001f:** El procesamiento completo de un lote en entorno de producción sintético (≈27,000 filas × 12 columnas) debe completarse en menos de 50 segundos desde `Job::dispatch()` hasta `lotes_cruce.estado = 'completado'.`
- [ ] **AC-002:** Dado un registro del CSV, cuando se aplica la normalización, entonces el texto se convierte íntegramente a MAYÚSCULAS, se eliminan todas las tildes (á→A, é→E, í→I, ó→O, ú→U) y se reemplaza estrictamente la "Ñ" por "N" sin excepción alguna.
- [ ] **AC-003:** Dado un nombre normalizado, cuando se procesa la cadena de texto, entonces el sistema separa lógicamente el apellido paterno, el apellido materno y los nombres, reconociendo correctamente apellidos compuestos de dos o más palabras (ej. "DE LA CRUZ", "DEL AGUILA").
- [ ] **AC-004:** Dado el archivo CSV, cuando se importa el lote, entonces el sistema normaliza primero el campo `OBSERVACION` (mayúsculas, sin tildes) y luego aplica el filtro: los registros cuyo valor normalizado sea exactamente `ALCANZO VACANTE` se persisten en la tabla `ingresantes`; todos los demás registros se persisten en la tabla `no_ingresantes` para trazabilidad. Ambas inserciones quedan vinculadas al mismo `lote_cruce_id` y se registran los totales de cada grupo en el log del lote.

#### UI/UX Notes

- El componente de carga (`FileUpload`) debe mostrar un indicador de progreso durante el procesamiento.
- Al finalizar, mostrar resumen: total de registros del CSV, registros filtrados por OBSERVACION, registros cargados al lote, fechas ignoradas por duplicado.

#### Technical Notes

- La normalización (AC-002) es responsabilidad de `NormalizarTextoAction.php`.
- El filtrado de duplicados por fecha (AC-001) compara contra la tabla `lotes_cruce` antes de insertar.
- **De-duplicación de filas (AC-001):** El job de importación remueve las filas idénticas duplicadas en el archivo CSV antes de procesar las inserciones.
- El filtro de OBSERVACION (AC-004) se aplica **después** de la normalización del campo, no sobre el valor crudo. *(NC-1 — Resuelto. Ver Open Questions.)*
- **Persistencia dual (AC-004):** los registros que cumplen el filtro van a la tabla `ingresantes`; los que no lo cumplen van a la tabla `no_ingresantes`. Ambas tablas llevan el mismo `lote_cruce_id` como clave de trazabilidad.
- **Redis + Colas (Laravel Queue):** dado que el CSV real alcanza ~27,000 filas × 12 columnas (específicamente `CODIGO`, `APELLIDOS`, `NOMBRES`, `EAP`, `PUNTAJE`, `MERITO`, `OBSERVACION`, `TIPO`, `MODALIDAD`, `UNIVERSIDAD`, `PERIODO`, `FECHA`), la importación, normalización y enrutamiento a `ingresantes`/`no_ingresantes` se despachan como un job en cola (`ProcessCsvBatchJob`) a través de Redis. El endpoint de carga responde inmediatamente con el `lote_id` y el estado `procesando`; el frontend consulta el progreso vía polling o WebSocket. Esto evita timeouts HTTP y permite procesar el volumen real dentro del SLA de NFR-001.

---

### US-002: Consulta Directa a Base de Datos Academia

**As a** Sistema (motor de cruce)
**I want** consultar directamente la base de datos `academia` en PostgreSQL para obtener los registros de matrícula de los alumnos
**So that** el cruce se realice siempre contra datos actualizados sin depender de exportaciones o archivos intermedios

**Priority:** P1 (Must Have)
**Story Points:** 3

#### Acceptance Criteria

- [ ] **AC-005:** Dado un lote de ingresantes importados, cuando se inicia el proceso de cruce, entonces el sistema valida la conexión con la base de datos `academia` en PostgreSQL antes de ejecutar cualquier consulta, abortando limpiamente con alerta si la conexión falla.
- [ ] **AC-005a:** La consulta a la base de datos `academia` debe recuperar exactamente los campos de matrícula: `dni_alumno`, `apellidos`, `nombres`, `anio`, `local`, `periodo`, `aula`, `fecha`, `cel_alumno`, `dni_responsable`, `cel_responsable`, `estado_matricula`, `fecha_registro`.
- [ ] **AC-006:** Dado que la conexión está disponible, cuando se consultan los alumnos, entonces el sistema trae registros en todos los estados válidos: MATRICULADO, PAGADO, FINALIZADO, SUSPENDIDO, RETIRADO, TRASLADADO, STAND BY, ANULADO — sin filtrar ningún estado en la consulta de extracción (obtenido del campo `estado_matricula`).
- [ ] **AC-007:** Dado un alumno con múltiples registros históricos en la base de datos `academia`, cuando se determina su estado para el reporte, entonces se resuelve eligiendo el estado de mayor prioridad según la jerarquía inmutable: 1. MATRICULADO → 2. PAGADO → 3. FINALIZADO → 4. SUSPENDIDO → 5. RETIRADO → 6. TRASLADADO → 7. STAND BY → 8. ANULADO.

#### Technical Notes

- La validación de conexión (AC-005) se ejecuta al inicio de `RealizarCruceExactoAction.php`.
- **Extracción de Alumnos (AC-005a):** La consulta SQL/Eloquent debe seleccionar explícitamente las columnas `dni_alumno`, `apellidos`, `nombres`, `anio`, `local`, `periodo`, `aula`, `fecha`, `cel_alumno`, `dni_responsable`, `cel_responsable`, `estado_matricula`, `fecha_registro` de la base de datos `academia`.
- La jerarquía de estados (AC-007) es inmutable según INV-06 del Context Bridge (constitution.md Art. IV §4.7); cualquier cambio requiere enmienda constitucional documentada.
- Las credenciales de conexión se gestionan exclusivamente mediante variables de entorno (`.env`) — Art. 4 de la Constitución.

---

### US-003: Motor de Coincidencia en Dos Fases (Match Engine)

**As a** Administrador de la academia Vonex
**I want** que el sistema empareje automáticamente los ingresantes con alumnos de la academia en dos fases (exacta y difusa)
**So that** se minimicen los falsos positivos en el cruce automático y se reduzca la carga operativa de revisión manual

**Priority:** P1 (Must Have)
**Story Points:** 8

#### Acceptance Criteria

- [ ] **AC-008:** Dado un ingresante en el lote, cuando sus 2 apellidos (paterno y materno) y al menos 1 nombre coinciden exactamente con un alumno de la academia tras la normalización, entonces el sistema asocia automáticamente al ingresante con el `alumno_id` correspondiente, establece el estado `confirmado_automatico` y continúa sin intervención del usuario.
- [ ] **AC-009:** Dado un ingresante que no obtiene match exacto, cuando el motor calcula la similitud comparando la frecuencia de letras y la distancia de Levenshtein contra los alumnos de la academia, entonces genera una lista ordenada de mayor a menor probabilidad con hasta 5 candidatos potenciales y marca al ingresante como `pendiente`.
- [ ] **AC-010:** Dado un ingresante en estado `pendiente`, cuando ningún alumno supera el umbral de similitud del 30%, entonces la lista de candidatos estará vacía y el sistema expondrá la opción "Sin coincidencias encontradas — Marcar como No Ingresado" en la interfaz.

- [ ] **AC-003a:** El sistema debe procesar lotes grandes con tiempos de ejecución medibles; ver AC-001f para el objetivo de rendimiento de procesamiento por lote.

#### Technical Notes

- El cruce exacto (AC-008) es responsabilidad de `RealizarCruceExactoAction.php`.
- El cálculo de similitud (AC-009) es responsabilidad de `CalcularSimilitudesCabosAction.php`. La similitud compuesta se calcula como:

  ```
  similitud(ingresante, alumno) = (levenshtein_normalizado × 0.6) + (dice_bigramas × 0.4)
  ```

  Definiciones:
  - **Cadena de comparación:** concatenación normalizada `apellidos + ' ' + nombres` de ambos registros (post-`NormalizarTextoAction`).
  - **`levenshtein_normalizado(a, b)`** = `1 - (levenshtein_distance(a, b) / max(length(a), length(b)))` — rango [0.0, 1.0].
  - **`dice_bigramas(a, b)`** = `(2 × |bigramas_comunes(a, b)|) / (|bigramas(a)| + |bigramas(b)|)` (Dice coefficient sobre bigramas de caracteres) — rango [0.0, 1.0].
  - El resultado final multiplicado por 100 es el **porcentaje de similitud** almacenado en `porcentaje_similitud`.
  - Ejemplo de referencia obligatorio para TC-007: `similitud("JHON RAMOS LOPEZ", "JOHN RAMOS LOPEZ")` debe producir un valor **≥ 85%**; `similitud("GARCIA TORRES LUIS", "PEREZ MENDOZA ANA")` debe producir un valor **< 30%**.

- El umbral del 30% (AC-010) es un supuesto revisable — ver **Assumption A-03**.

---

### US-004: Interfaz de Validación Asistida (React)

**As a** Administrador de la academia Vonex
**I want** visualizar los ingresantes en estado `pendiente` y seleccionar manualmente el alumno correcto desde una interfaz interactiva
**So that** los cabos sueltos se resuelvan con criterio humano sin requerir herramientas externas ni hojas de cálculo

**Priority:** P2 (Should Have)
**Story Points:** 5

#### Acceptance Criteria

- [ ] **AC-011:** Dado un ingresante en estado `pendiente`, cuando se visualiza en la interfaz React, entonces se muestra una fila con sus datos del CSV (apellido paterno, materno, nombres, fecha de examen) y un selector `<select>` con los candidatos ordenados de mayor a menor probabilidad, mostrando para cada uno el nombre completo y el porcentaje de similitud.
- [ ] **AC-012:** Dado que el administrador selecciona un candidato del menú y presiona "Confirmar Match", cuando el sistema procesa la acción, entonces guarda la asociación invocando `GuardarCruceConfirmadoAction`, cambia el estado del ingresante a `confirmado_manual` y actualiza los datos enriquecidos en la base de datos analítica.
- [ ] **AC-013:** Dado que ningún candidato corresponde al ingresante, cuando el administrador selecciona "Sin coincidencias encontradas — Marcar como No Ingresado" y confirma, entonces el estado del ingresante se actualiza a `no_ingresado` en la base de datos analítica.

- [ ] **AC-004a:** El endpoint `GET /api/cruce/ingresantes/{id}/candidatos` debe responder con latencia p95 < 300 ms en condiciones representativas.
- [ ] **AC-004b:** Cuando la confirmación se envía con un `alumno_id` inexistente, el endpoint retorna HTTP 404 y el estado del ingresante no cambia.

#### UI/UX Notes

- El selector (AC-011) debe incluir como primera opción un placeholder no seleccionable: "Selecciona un alumno...".
- Mostrar un badge con el porcentaje de similitud junto al nombre de cada candidato en el `<select>`.
- La confirmación (AC-012) debe mostrar feedback visual inmediato (spinner + mensaje de éxito/error) sin recargar la página.
- La opción "No Ingresado" (AC-013) debe estar visualmente diferenciada (color rojo o icono de advertencia) para evitar clics accidentales.

#### Technical Notes

- La API REST expone los cabos sueltos del lote vía `GET /api/cruce/lotes/{lote_id}/pendientes` (ver openapi.yaml — fuente autoritativa de paths).
- Los candidatos se obtienen vía `GET /api/cruce/ingresantes/{ingresante_id}/candidatos`.
- La confirmación se envía vía `POST /api/cruce/ingresantes/{ingresante_id}/confirmar`.
- El componente principal es `UnmatchedRow.jsx`; el orquestador de la vista es `App.jsx`.

---

### US-005: Exportación de Reporte Consolidado en Excel

**As a** Usuario de negocio (administración/marketing)
**I want** descargar un archivo Excel con los datos de ingresantes procesados y analítica visual incorporada
**So that** pueda distribuir resultados y analizar métricas por fecha de examen sin herramientas adicionales

**Priority:** P3 (Nice to Have)
**Story Points:** 5

#### Acceptance Criteria

- [ ] **AC-014:** Dado un lote procesado (con matches confirmados), cuando el usuario descarga el reporte Excel, entonces la **Hoja 1** contiene exactamente 24 columnas en el siguiente orden estricto (de la A a la X):
  - **A: CODIGO** (del CSV `CODIGO`)
  - **B: DNI** (de la BD `dni_alumno`)
  - **C: APELLIDOS** (del CSV `APELLIDOS`)
  - **D: NOMBRES** (del CSV `NOMBRES`)
  - **E: EAP** (del CSV `EAP`)
  - **F: PUNTAJE** (del CSV `PUNTAJE`)
  - **G: MERITO** (del CSV `MERITO`)
  - **H: OBSERVACION** (del CSV `OBSERVACION`)
  - **I: TIPO** (del CSV `TIPO`)
  - **J: MODALIDAD** (del CSV `MODALIDAD`)
  - **K: UNIVERSIDAD** (del CSV `UNIVERSIDAD`)
  - **L: PERIODO** (del CSV `PERIODO`)
  - **M: FECHA** (del CSV `FECHA`)
  - **N: ANIO** (de la BD `anio`)
  - **O: SEDE** (de la BD `local`)
  - **P: CICLO** (de la BD `periodo`)
  - **Q: F-MATRICULA** (de la BD `fecha_registro`)
  - **R: CEL-ALUMNO** (de la BD `cel_alumno`)
  - **S: CEL-APODERADO** (de la BD `cel_responsable`)
  - **T: ESTADO** (de la BD `estado_matricula` resuelto por jerarquía)
  - **U: LISTA - 1** (L1: `1` si el alumno está matriculado desde el ciclo Verano 2024 hasta la actualidad, presencial y virtual; `0` si no)
  - **V: LISTA - 2** (L2: `1` si el alumno está matriculado en cualquier ciclo activo a febrero 2026, verano 2026 (verano/repaso) o ciclos OCTUBRE 2025, incluyendo retirados/suspendidos, presencial y virtual; `0` si no)
  - **W: LISTA - 3** (L3: `1` si el alumno está activo al 27 de febrero de 2026 en ciclos presenciales y virtuales; `0` si no)
  - **X: AREA** (Área UNMSM resuelta a partir del campo `EAP`)
- [ ] **AC-015:** Dado el archivo Excel descargado, cuando el usuario abre la **Hoja 2**, entonces encuentra gráficos analíticos pre-construidos (distribución por estado, por sede, por ciclo) y segmentadores dinámicos que filtran todas las métricas por fecha de examen.

#### Technical Notes

- La exportación es responsabilidad de `ExportarExcelCruceAction.php`.
- Utilizar una librería PHP compatible con Excel (ej. PhpSpreadsheet) para generar ambas hojas y los gráficos dinámicos.
- **Cálculo de Listas (AC-014):**
  - **L1 (LISTA - 1):** Valida si el registro de matrícula en `academia` tiene un ciclo (`periodo`) igual o posterior a "Verano 2024".
  - **L2 (LISTA - 2):** Valida si el ciclo (`periodo`) del alumno es un ciclo activo a febrero 2026, o bien un ciclo de verano 2026 (ej. "VERANO 2026", "REPASO 2026") o de octubre 2025 (ej. "OCTUBRE 2025"), sin importar si el estado es `RETIRADO` o `SUSPENDIDO`.
  - **L3 (LISTA - 3):** Valida si al 27 de febrero de 2026 el estado de matrícula (`estado_matricula`) corresponde a un alumno activo (por jerarquía: `MATRICULADO`, `PAGADO`, `FINALIZADO` y no retirado/suspendido/anulado) en ciclos presenciales o virtuales.
- **Mapeo de AREA (AC-014):** La resolución del campo `AREA` mapea la columna `EAP` a las áreas académicas de la UNMSM:
  - **Área A (Ciencias de la Salud):** Carreras que contienen MEDICINA, OBSTETRICIA, ENFERMERIA, TECNOLOGIA MEDICA, ODONTOLOGIA, FARMACIA, VETERINARIA, PSICOLOGIA.
  - **Área B (Ciencias Básicas):** Carreras que contienen QUIMICA, BIOLOGICAS, FISICA, MATEMATICA, ESTADISTICA.
  - **Área C (Ingenierías):** Carreras que contienen INGENIERIA, SOFTWARE, SISTEMAS, INDUSTRIAL, CIVIL.
  - **Área D (Ciencias Económicas y de la Gestión):** Carreras que contienen ADMINISTRACION, NEGOCIOS, CONTABILIDAD, ECONOMIA.
  - **Área E (Humanidades y Ciencias Jurídicas y Sociales):** Carreras que contienen DERECHO, POLITICA, LITERATURA, FILOSOFIA, COMUNICACION, ARTE, ARQUEOLOGIA, EDUCACION, HISTORIA, TRABAJO SOCIAL.
  - Si no se encuentra correspondencia exacta, se deja vacío.

---

## Non-Functional Requirements

### NFR-001: Rendimiento de Carga (Procesamiento Asíncrono en Cola)

- **Requirement:** El procesamiento completo de un CSV con hasta ~27,000 filas × 12 columnas (filtrado, normalización, enrutamiento a `ingresantes`/`no_ingresantes` y agrupación en lote) debe completarse en menos de **50 segundos** medidos desde que el job es despachado a la cola Redis hasta que el lote queda en estado `completado` en base de datos.
- **Context:** El endpoint HTTP de carga responde en < 2 s retornando el `lote_id` y el estado `procesando`; el SLA de 50 s aplica exclusivamente al procesamiento asíncrono del job en cola, no a la respuesta HTTP inicial.
- **Traces to:** Art. 4 de la Constitución — Pipeline sin intervención manual; NFR-006 (Redis Queue); Assumption A-05 (disponibilidad de Redis).
- **Verification:** Test de rendimiento con un CSV sintético de ~27,000 filas × 12 columnas: medir el tiempo desde `Job::dispatch()` hasta que `lotes_cruce.estado = 'completado'` vía worker de cola Redis activo.

### NFR-002: Tiempo de Respuesta API (Fuzzy Match)

- **Requirement:** La consulta de candidatos (fuzzy match) para un ingresante individual en la interfaz interactiva debe responder en menos de 300 ms (percentil 95).
- **Traces to:** Art. 4 de la Constitución — Pruebas automatizadas; Assumption A-02 (índices en BD).
- **Verification:** Test de integración midiendo el tiempo de respuesta del endpoint `GET /api/cruce/{ingresante}/candidatos` con carga representativa.

### NFR-003: Volumen de Carga de Archivo

- **Requirement:** El sistema debe soportar la subida de archivos CSV de hasta 20 MB sin error de límite de memoria en el proceso HTTP inicial de recepción del archivo.
- **Traces to:** Art. 3 de la Constitución — Integridad de Normalización; necesidad operativa del equipo de admisiones. El procesamiento posterior corre en worker Redis (NFR-006), por lo que el límite de memoria HTTP no aplica a la normalización.
- **Verification:** Subir un CSV de 20 MB y confirmar: (a) respuesta HTTP exitosa con `lote_id`, (b) sin error `memory_limit` en el proceso HTTP, (c) job encolado correctamente visible en Redis.

### NFR-004: Seguridad de Credenciales

- **Requirement:** Las credenciales de conexión a la base de datos `academia` no deben almacenarse en el repositorio; deben gestionarse exclusivamente mediante variables de entorno.
- **Traces to:** Art. 4 de la Constitución — Seguridad de credenciales.
- **Verification:** Revisión de código automatizada (git-secrets o equivalente) + revisión manual en Pull Request.

### NFR-005: Trazabilidad de Lotes

- **Requirement:** Cada lote procesado debe registrar en base de datos: fecha de examen, total de registros del CSV, total enrutados a `ingresantes`, total enrutados a `no_ingresantes`, total con match exacto, total pendientes, total no ingresados y timestamp de inicio/fin del job.
- **Traces to:** Art. 4 de la Constitución — Auditoría y trazabilidad.
- **Verification:** Query de verificación en la tabla `lotes_cruce` después de procesar un lote de prueba; confirmar que los totales suman el 100% de filas del CSV.

### NFR-006: Procesamiento Asíncrono con Redis

- **Requirement:** La importación y normalización del CSV debe ejecutarse fuera del ciclo de vida HTTP, utilizando **Redis** como driver de colas de Laravel. El sistema debe soportar al menos 1 worker concurrente y tolerar reinicios del worker sin pérdida de datos (jobs fallidos deben quedar en la cola `failed_jobs` para reintento manual).
- **Traces to:** Art. 4 de la Constitución — Pipeline sin intervención manual; Gestión de Errores Silenciosos; NFR-001 (SLA de 50 s); volumen real de ~27,000 filas × 12 columnas que excede los límites prácticos de procesamiento síncrono en HTTP.
- **Verification:** (a) Verificar con `php artisan queue:work --queue=cruce` que el job `ProcessCsvBatchJob` se despacha y completa correctamente. (b) Simular fallo de worker a mitad de procesamiento y confirmar que el lote queda en estado `paused` (no corruptible). (c) Confirmar que `QUEUE_CONNECTION=redis` está configurado en `.env`.

---

## Edge Cases

| ID | Scenario | Expected Behavior | Story Reference |
|----|----------|-------------------|-----------------:|
| EC-001 | Fila del CSV con campo de nombre o apellido vacío | Registrar el error en el log del lote con número de fila e identificador del registro; continuar procesando las filas siguientes sin abortar el lote | US-001 |
| EC-002 | CSV sin las columnas requeridas (`NOMBRES`, `OBSERVACION`, `FECHA_EXAMEN`) | Rechazar la carga inmediatamente con mensaje de error descriptivo indicando qué columnas faltan; no insertar ningún registro | US-001 |
| EC-003 | Motor de coincidencia difusa sin candidatos con similitud ≥ 30% | Mostrar en el selector React la opción "Sin coincidencias encontradas — Marcar como No Ingresado"; no bloquear el flujo | US-003 / US-004 |
| EC-004 | Fecha de examen del CSV ya procesada previamente | Ignorar silenciosamente los registros de esa fecha; registrar el salto en el log con la fecha omitida y la razón | US-001 |
| EC-005 | Alumno con más de 5 registros históricos de igual similitud | Tomar solo los 5 de mayor similitud; en caso de empate exacto, desempatar por orden alfabético del apellido paterno | US-003 |
| EC-006 | CSV con codificación distinta de UTF-8 o ISO-8859-1 (ej. UTF-16) | Detectar la codificación al inicio de la carga; si no es soportada, rechazar con error descriptivo de codificación sin insertar ningún registro | US-001 |
| EC-007 | Timeout o error de conexión a la BD `academia` durante el cruce | Marcar el lote como `paused` (recuperable); conservar los registros ya procesados con su estado actual; los registros no procesados quedan en `pendiente` para reintento manual. Ver CQ-003. | US-002 / NFR-006 |
| EC-008 | Worker Redis caído o reiniciado durante el procesamiento del job | El job queda en la cola `failed_jobs`; el lote permanece en estado `procesando` hasta que el administrador reintente el job manualmente; no se pierden ni duplican registros ya insertados | US-001 / NFR-006 |

---

## Error Scenarios

| ID | Error Condition | User Message | System Behavior | Story Reference |
|----|-----------------|:------------:|-----------------|----------------:|
| ERR-001 | CSV con formato de columnas incorrecto | "El archivo CSV no contiene las columnas requeridas: {lista}. Verifique el formato e intente nuevamente." | Rechazar carga; no insertar registros; log con detalle técnico | US-001 |
| ERR-002 | Codificación de archivo no soportada | "El archivo no puede leerse con la codificación detectada ({encoding}). Se acepta UTF-8 o ISO-8859-1." | Rechazar carga; retornar HTTP 422 con detalle de codificación detectada | US-001 |
| ERR-003 | Fallo de conexión a BD `academia` | "No se pudo establecer conexión con la base de datos de la academia. Contacte al administrador del sistema." | Marcar lote como `paused` (fallo recuperable); registrar stack trace en log del servidor. Ver CQ-003. | US-002 |
| ERR-004 | CSV vacío (0 registros tras filtro OBSERVACION) | "El archivo no contiene registros con observación 'ALCANZO VACANTE'. Verifique el contenido del CSV." | Retornar HTTP 422; no crear lote en BD | US-001 |
| ERR-005 | Archivo mayor a 20 MB | "El archivo supera el tamaño máximo permitido (20 MB). Divídalo en partes y vuelva a intentarlo." | Rechazar antes de procesar; retornar HTTP 413 | US-001 |
| ERR-006 | Confirmación de match con `alumno_id` inválido | "El alumno seleccionado no existe en la base de datos. Recargue la página e intente nuevamente." | Retornar HTTP 404; no actualizar estado del ingresante | US-004 |
| ERR-007 | Job `ProcessCsvBatchJob` falla y mueve a `failed_jobs` | "El procesamiento del lote encontró un error inesperado. El lote quedó en pausa. Contacte al administrador para reintentarlo." | Marcar `lotes_cruce.estado = 'error'`; registrar excepción completa en `failed_jobs`; no borrar registros ya insertados | US-001 / NFR-006 |

---

## Related or Duplicate Work

| Type | Target | Reason |
|------|--------|--------|
| `implementsTogether` | US-001, US-002 | Comparten el modelo `LoteCruce` y la lógica de conexión a la BD; deben implementarse en el mismo sprint como unidad cohesiva |
| `blocks` | US-003 | Depende de US-001 (registros normalizados en `ingresantes_cruce`) y US-002 (pool de alumnos de la academia disponible) |
| `blocks` | US-004 | Depende de US-003 para tener candidatos calculados en estado `pendiente` |
| `blocks` | US-005 | Depende de US-003 y US-004 para tener datos enriquecidos y estados resueltos |

---

## Glossary

| Term | Definition | Context |
|------|------------|---------:|
| Ingresante | Estudiante que alcanzó una vacante en el examen de admisión de la UNMSM | Dominio de negocio |
| Lote | Conjunto de registros del CSV agrupados por una misma `FECHA_EXAMEN` | Dominio técnico y de negocio |
| Match exacto | Coincidencia de 2 apellidos + al menos 1 nombre entre un ingresante y un alumno de la academia, tras normalización | Motor de cruce |
| Cabo suelto | Ingresante sin match exacto pero con similitud ≥ 30% con algún alumno de la academia | Motor de cruce |
| `confirmado_automatico` | Estado asignado cuando el cruce exacto establece la asociación sin intervención humana | Estado del sistema |
| `confirmado_manual` | Estado asignado cuando el administrador valida manualmente la asociación en la interfaz React | Estado del sistema |
| `pendiente` | Estado inicial de un ingresante que no obtuvo match exacto; requiere revisión manual | Estado del sistema |
| `no_ingresado` | Estado final cuando el administrador descarta todos los candidatos sugeridos | Estado del sistema |
| Jerarquía de estados | Orden de prioridad inmutable para resolver el estado de un alumno con múltiples registros históricos (INV-06 Context Bridge) | Regla de negocio |
| Normalización | Proceso de convertir texto a MAYÚSCULAS, eliminar tildes y sustituir "Ñ" por "N" | Motor de normalización |
| Levenshtein | Algoritmo de distancia de edición usado para calcular la similitud entre cadenas de texto en el motor difuso | Técnico |
| `ingresantes` | Tabla de BD que almacena los registros del CSV cuyo campo `OBSERVACION` normalizado equivale a `ALCANZO VACANTE` | Schema analítico |
| `no_ingresantes` | Tabla de BD que almacena los registros del CSV que **no** cumplen el filtro de `OBSERVACION`; conservados para auditoría y trazabilidad del lote | Schema analítico |
| `ProcessCsvBatchJob` | Job de Laravel despachado a la cola Redis que orquesta la importación, normalización y enrutamiento dual del CSV | Técnico |
| `Redis Queue` | Servicio de cola basado en Redis usado como driver de `QUEUE_CONNECTION` en Laravel para procesar jobs asíncronos fuera del ciclo HTTP | Técnico |
| `LISTA - 1` | Indicador binario en el reporte Excel para alumnos Vonex matriculados desde el ciclo Verano 2024 hasta la actualidad. | Dominio de negocio |
| `LISTA - 2` | Indicador binario en el reporte Excel para alumnos matriculados en ciclos activos a febrero 2026, verano 2026 o ciclos de octubre 2025 (incluye retirados/suspendidos). | Dominio de negocio |
| `LISTA - 3` | Indicador binario en el reporte Excel para alumnos con matrícula activa al 27 de febrero de 2026. | Dominio de negocio |
| `AREA` | Clasificación de la carrera profesional (EAP) según la distribución oficial de áreas académicas de la UNMSM (Áreas A, B, C, D, E). | Dominio de negocio |

---

## Assumptions

| ID | Assumption | If False, Then… |
|----|------------|-----------------|
| A-01 | El formato de codificación del CSV es siempre UTF-8 o ISO-8859-1 | Si se sube un CSV con otra codificación (ej. UTF-16), la carga fallará con ERR-002, evitando caracteres corruptos en la BD |
| A-02 | La base de datos `academia` tiene índices creados sobre los campos de apellidos y nombres | Sin índices, las consultas de cruce exacto y difuso degradarán el rendimiento, incumpliendo NFR-001 y NFR-002 |
| A-03 | Un umbral de similitud del 30% es el valor óptimo para filtrar candidatos relevantes de coincidencia difusa | Si el umbral óptimo es mayor, se listarán candidatos irrelevantes (ruido en UI); si es menor, se omitirán candidatos con variaciones severas que sí corresponden al ingresante |
| A-04 | Un máximo de 5 candidatos potenciales es suficiente para cubrir los errores de digitación más frecuentes | Si existen más de 5 homónimos con la misma similitud, el candidato correcto podría quedar excluido de la lista, obligando a búsqueda manual extendida |
| A-05 | El servicio Redis está disponible y accesible desde el servidor Laravel en el entorno de producción | Si Redis no está disponible, el job no podrá encolarse, el procesamiento del CSV fallará inmediatamente tras la recepción del archivo y el SLA de NFR-001 no podrá cumplirse. Mitigación: configurar un health-check de Redis en el startup de la aplicación |

---

## Open Questions

> Estas preguntas se identificaron durante la especificación y requieren resolución en la fase de clarificación. Las marcadas con 🔴 son bloqueantes para implementación.

1. [x] ✅ **[NC-1 — RESUELTO]:** ¿El filtro por `ALCANZO VACANTE` se aplica sobre el valor normalizado (mayúsculas, sin tildes) o sobre el valor crudo del CSV?
   - **Decisión confirmada por PO (2026-06-24):** El filtro se aplica **siempre sobre el valor normalizado** (mayúsculas, sin tildes). No existe caso de uso donde el valor crudo sea preferido.
   - **Consecuencia en datos:** los registros que no cumplan el filtro normalizado se persisten en la tabla `no_ingresantes` (no se descartan). Ver AC-004 y Technical Notes de US-001.
   - **Impacto en schema:** se requieren dos tablas diferenciadas: `ingresantes` y `no_ingresantes`, ambas con `lote_cruce_id` como FK.

---

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-06-01 | Samuel Cisneros | Especificación funcional inicial (formato libre) |
| 2.0 | 2026-06-10 | Renzo Fabián | Incorporación de match difuso (cabos sueltos) y React UI |
| 2.2.0 | 2026-06-16 | Samuel Cisneros / Equipo V2 | Alineación con Constitución v2.2.0; ignorado de fechas duplicadas; supresión de match difuso automático sin revisión |
| 2.3.0 | 2026-06-24 | Equipo V2 (refactor por Antigravity) | Adaptación completa al modelo Enterprise SDD: US-XXX H3, AC como checkboxes, NFR con trazabilidad, tablas de EC/ERR, Story Linking, Glosario, Assumptions formalizados |
| 2.4.0 | 2026-06-24 | Samuel Cisneros (PO) | Correcciones post-revisión: NFR-001 ajustado de 5 s → 50 s; NC-1 resuelto (filtro post-normalización); persistencia dual ingresantes/no_ingresantes en AC-004; NFR-006 Redis Queue añadido; volumen real documentado (~27,000 filas × 12 columnas) |
| 2.5.0 | 2026-06-24 | Equipo V2 (revisión elite Antigravity) | Revisión final: Executive Summary actualizado con dual-table + Redis; NFR-001 título y trazabilidad unificados; NFR-003 verificación alineada con arquitectura de colas; EC-008 añadido (worker Redis caído); ERR-007 añadido (job a failed_jobs); Glosario extendido con 4 términos nuevos (ingresantes, no_ingresantes, ProcessCsvBatchJob, Redis Queue); A-05 añadido (disponibilidad Redis); enlace corregido al business-context.md en .specify/specs/ |
| 2.6.0 | 2026-06-25 | Equipo V2 | Enmienda para incorporar campos DB, CSV y la estructura de reporte Excel final con Listas y Área. |
| 2.7.0 | 2026-06-25 | Equipo V2 (Auditoría SDD-Enterprise) | Auditoría de cumplimiento: fórmula de similitud formalizada en AC-009 (Levenshtein × 0.6 + Dice bigramas × 0.4); EC-007 y ERR-003 unificados a estado `paused` (CQ-003); NFR-006 corregido de `pausado` a `paused`. |

---

## External References

> Fuentes externas consultadas durante la elaboración de esta especificación.
> Ver `source-verification.instructions.md` para el flujo DETECT→FETCH→IMPLEMENT→CITE.

| Source | Access Date | Relevant Section | Notes |
|--------|:-----------:|-----------------|-------|
| Papalini, E. (2026). *Non-Deterministic Spec-Driven Development — Enterprise Edition*. Independently published. | 2026-06-24 | Cap. 2 (Four Phases / Four Gates), Cap. 11-12 (Enterprise SDD Pipeline), App. C Template 2 (spec.md) | Framework de referencia para la estructura del presente spec |
| Constitución del Proyecto Vonex v2.3.0 ([constitution.md](../../memory/constitution.md)) | 2026-06-25 | Art. 2-7 | Fuente de verdad para estándares de calidad, jerarquía de estados y límites del proyecto |
