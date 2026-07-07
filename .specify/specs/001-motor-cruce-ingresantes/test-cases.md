# Casos de Prueba: Motor de Cruce Automático de Ingresantes UNMSM

**ID de Feature:** 001-motor-cruce-ingresantes
**Creado:** 2026-06-24
**Autor:** Diego Castillo
**Estado:** Aprobado

> Glosario de siglas:
> - **US:** Historia de Usuario
> - **AC:** Criterio de Aceptación
> - **NFR:** Requisito No Funcional
> - **EC:** Caso de Borde (Edge Case)
> - **ERR:** Escenario de Error
> - **E2E:** Prueba de extremo a extremo
> - **BD:** Base de Datos

---

## 1. Estrategia de Pruebas

### 1.1 Alcance de Pruebas

| Tipo de prueba | Alcance | Objetivo de cobertura |
|---------------|---------|----------------------|
| Pruebas de Unidad | `NormalizarTextoAction`, `ProcesarCargaCsvAction`, `RealizarCruceExactoAction`, `CalcularSimilitudesCabosAction`, `GuardarCruceConfirmadoAction`, `ExportarExcelCruceAction` | 100% en lógica de negocio (Art. III §3.2 Constitution) |
| Pruebas de Integración | endpoints de API, BD `academia` y `lotes_cruce`, cola Redis | Flujos clave de carga, cruce, confirmación y exportación |
| Pruebas E2E | Archivo CSV completo → reporte CSV consolidado, interfaz de validación asistida | Flujo feliz + casos de error críticos |
| Pruebas de Rendimiento | Procesamiento asíncrono de CSV y respuesta de endpoints de candidatos | Validación de NFR-001 y NFR-002 |
| Pruebas de Contrato | contrato API REST del backend | Endpoints expuestos por el plan |

### 1.2 Entorno de Pruebas

| Entorno | Propósito | Datos |
|---------|----------|------|
| Local | Desarrollo y pruebas unitarias | Fixtures y factories |
| CI | Validación continua | Bases de datos temporales, Redis mock o real |
| Staging | Pruebas de integración | Datos anónimos representativos |

### 1.3 Estrategia de Datos de Prueba

- **Fixtures:** `tests/fixtures/` o `.specify/specs/001-motor-cruce-ingresantes/test-data/`
- **Factories:** `tests/factories/` para `Ingresante`, `LoteCruce`, `Alumno`
- **Mocks:** En pruebas unitarias se simula la conexión y las respuestas de la base `academia` para aislar la lógica de cruce. En pruebas de integración se simula o se controla el worker Redis para validar el comportamiento de la cola sin depender de un worker en producción.

### 1.4 Estado de Implementación de Pruebas (auditoría 2026-07-07)

> Este documento especifica casos de prueba; no todos tienen un archivo PHPUnit/Pest implementado. Confirmado por lectura directa de `tests/`:

| Categoría | Archivos reales encontrados | Estado |
|---|---|---|
| Unidad (`tests/Unit/Actions/`) | `NormalizarTextoActionTest.php`, `ProcesarCargaCsvActionTest.php`, `RealizarCruceExactoActionTest.php`, `CalcularSimilitudesCabosActionTest.php`, `GuardarCruceConfirmadoActionTest.php`, `ExportarExcelCruceActionTest.php`, `ConexionAcademiaTest.php`, `InvariantsTest.php` | Implementadas (T019) |
| Rendimiento (`tests/Performance/`) | `CsvProcessingPerformanceTest.php`, `FuzzyMatchPerformanceTest.php` | Implementadas (T021) |
| Contrato (`tests/Contract/`) | `OpenApiContractTest.php`, `AsyncApiContractTest.php` | Implementadas (no mapeadas a un task ID específico) |
| **Integración / Feature (`tests/Feature/`)** | Solo `ExampleTest.php` (default de Laravel) | **Genuinamente faltante — T020 no iniciado.** Ninguno de los TC de tipo "Integración" listados en este documento (TC-001, TC-004, TC-005, TC-009, TC-010, TC-015, TC-023, TC-025–TC-033, TC-047–TC-051, etc.) tiene un test automatizado real hoy. No se fabrican archivos de test aquí — se documenta el gap honestamente. Ver tasks.md T020. |

---

## 2. Casos de Prueba

### 2.1 Historia de Usuario: US-001 - Carga, Normalización y Filtrado de CSV

#### TC-001: Importar CSV con múltiples fechas de examen y duplicados en el mismo lote

| Atributo | Valor |
|----------|-------|
| **Tipo** | Integración |
| **Prioridad** | P1 (Crítico) |
| **Automatizado** | Sí |
| **Trazas a** | US-001, AC-001, plan.md: ProcesarCargaCsvAction / LoteCruce |

**Precondiciones:**
- Registro previo en `lotes_cruce` para la fecha `2026-05-10`.
- CSV con dos fechas de examen: `2026-05-10` y `2026-05-17`, incluyendo filas duplicadas idénticas.

**Pasos de Prueba:**
| Paso | Acción | Resultado Esperado |
|------|--------|-------------------|
| 1 | Subir el CSV vía `POST /api/cruce/upload` | Respuesta 202 con `lote_id` y estado `processing` |
| 2 | Esperar a que el `ProcessCsvBatchJob` complete | El lote nuevo se crea solo para `2026-05-17` y la fecha `2026-05-10` es ignorada |
| 3 | Consultar `lotes_cruce` y logs de lote | Se registran totales de filas procesadas y duplicados eliminados |

**Datos de Prueba:**
```json
{
  "input": {
    "csv": "CODIGO,APELLIDOS,NOMBRES,EAP,PUNTAJE,MERITO,OBSERVACION,TIPO,MODALIDAD,UNIVERSIDAD,PERIODO,FECHA\n001,LOPEZ GARCIA,JUAN,MEDICINA HUMANA,15.500,10,ALCANZO VACANTE,ORDINARIO,GENERAL,UNMSM,2026-I,2026-05-10\n001,LOPEZ GARCIA,JUAN,MEDICINA HUMANA,15.500,10,ALCANZO VACANTE,ORDINARIO,GENERAL,UNMSM,2026-I,2026-05-10\n002,PEREZ LOPEZ,MARIA,DERECHO,14.200,25,ALCANZO VACANTE,ORDINARIO,GENERAL,UNMSM,2026-I,2026-05-17"
  },
  "expected": {
    "lote_fecha": "2026-05-17",
    "ignored_fechas": ["2026-05-10"],
    "duplicates_removed": 1
  }
}
```

**Limpieza:**
- Borrar registros creados en `lotes_cruce` y tablas asociadas.

---

#### TC-002: Normalización de acentos y Ñ en la lógica del backend

| Atributo | Valor |
|----------|-------|
| **Tipo** | Unidad |
| **Prioridad** | P1 |
| **Automatizado** | Sí |
| **Trazas a** | US-001, AC-002, plan.md: NormalizarTextoAction |

**Dado:** Un texto con caracteres especiales: `Ñ`, `Á`, `É`, `Í`, `Ó`, `Ú`, `DE LA CRUZ`.
**Cuando:** Se ejecuta `NormalizarTextoAction`.
**Entonces:** El resultado es `N`, `A`, `E`, `I`, `O`, `U` y texto en MAYÚSCULAS.

**Datos de Prueba:**
- Entrada: `"María Ñañez de la Cruz"`
- Esperado: `"MARIA NANEZ DE LA CRUZ"`

---

#### TC-003: Separación de apellido paterno, materno y nombres con apellidos compuestos

| Atributo | Valor |
|----------|-------|
| **Tipo** | Unidad |
| **Prioridad** | P1 |
| **Automatizado** | Sí |
| **Trazas a** | US-001, AC-003, plan.md: NormalizarTextoAction |

**Dado:** Nombre normalizado `"DE LA CRUZ GARCIA JUAN CARLOS"`.
**Cuando:** Se procesa la cadena en la acción de parsing.
**Entonces:** Se separan correctamente:
- apellido paterno: `DE LA CRUZ`
- apellido materno: `GARCIA`
- nombres: `JUAN CARLOS`

---

#### TC-004: Filtrar `OBSERVACION` y enrutar a `ingresantes` / `no_ingresantes`

| Atributo | Valor |
|----------|-------|
| **Tipo** | Integración |
| **Prioridad** | P1 |
| **Automatizado** | Sí |
| **Trazas a** | US-001, AC-004, plan.md: ProcesarCargaCsvAction |

**Dado:** CSV con dos filas, una con `ALCANZO VACANTE` y otra con `NO ALCANZO VACANTE`.
**Cuando:** El job de importación procesa el lote.
**Entonces:** La fila con `ALCANZO VACANTE` queda en `ingresantes`; la otra en `no_ingresantes`; ambos registros comparten el mismo `lote_cruce_id` y se registran totales separados.

**Datos de Prueba:**
- Entrada: `OBSERVACION=ALCANZO VACANTE`, `OBSERVACION=NO ALCANZO VACANTE`
- Esperado: 1 registro en cada tabla, mismo lote.

---

### 2.2 Historia de Usuario: US-002 - Consulta Directa a Base de Datos Academia

#### TC-005: Validar conexión y extracción de estados desde `academia`

| Atributo | Valor |
|----------|-------|
| **Tipo** | Integración |
| **Prioridad** | P1 |
| **Automatizado** | Sí |
| **Trazas a** | US-002, AC-005, AC-006, AC-007, plan.md: MatchEngine |

**Dado:** La conexión a la BD `academia` está configurada.
**Cuando:** `RealizarCruceExactoAction` inicia el proceso.
**Entonces:** Se valida la conexión antes de consultar; si la conexión es exitosa, se obtienen solo alumnos con `estado IN (0, 2, 3, 9, 13, 14)` (RETIRADO, MATRICULADO, PAGADO, SUSPENDIDO, STAND BY, FINALIZADO — ampliado 2026-07-07, decisión PO, tasks.md T039, para incluir RETIRADO; ANULADO(11)/TRASLADADO(12) permanecen excluidos), `estado_aula = 1`, sin filtro por ciclo ni exclusión de `matricularegular_id`, y se resuelve el estado de mayor prioridad según la jerarquía numérica.

**Datos de Prueba (schema real — 3 tablas):**

```sql
-- Insertar en personas (PK: dni)
INSERT INTO personas (dni, nombres, apellido_paterno, apellido_materno) 
VALUES ('12345678', 'JUAN', 'LOPEZ', 'GARCIA');

-- Insertar en alumnos (PK: codigo, FK: persona_dni)
INSERT INTO alumnos (codigo, persona_dni) 
VALUES ('ALU001', '12345678');

-- Insertar en alumno_matricula con estado 14 (FINALIZADO) — no requiere ciclo ni aula
INSERT INTO alumno_matricula (id, alumno_codigo, estado, estado_aula, fecha)
VALUES (100, 'ALU001', 14, 1, NOW());
```

- Entrada: alumno con `alumno_matricula.estado = 14` (FINALIZADO).
- Esperado: `getActiveAlumnos()` devuelve 1 resultado con `estado = 14`.

---

#### TC-047: Consultar estado del lote vía API

| Atributo | Valor |
|----------|-------|
| **Tipo** | Integración |
| **Prioridad** | P1 |
| **Automatizado** | Sí |
| **Trazas a** | plan.md: `/api/cruce/lotes/{lote_id}/status`, NFR-005 |

**Dado:** Un lote en proceso o completado.
**Cuando:** Se llama `GET /api/cruce/lotes/{lote_id}/status`.
**Entonces:** La respuesta contiene el `lote_id`, estado actual, totales de registros, totales de ingresantes, no_ingresantes, match exacto, pendientes, no_ingresados y timestamps de inicio/fin.

---

#### TC-048: Consultar ingresantes pendientes vía API

| Atributo | Valor |
|----------|-------|
| **Tipo** | Integración |
| **Prioridad** | P1 |
| **Automatizado** | Sí / Planificado (ver §1.4 — T020 no implementado) |
| **Trazas a** | plan.md: `/api/cruce/lotes/{lote_id}/pendientes`, US-004 AC-011, plan.md DA-G1, tasks.md T024 |

**Dado:** Un lote con ingresantes en estado `pendiente`.
**Cuando:** Se llama `GET /api/cruce/lotes/{lote_id}/pendientes`.
**Entonces:** La respuesta devuelve una lista paginada de **todos** los ingresantes `pendiente` del lote (ninguno excluido por no tener candidatos o por no alcanzar el 80%), con sus datos CSV normalizados y un total de páginas disponible.
**Y:** El orden de la lista es exactamente `candidatos_count DESC, max_similitud DESC, apellido_paterno ASC, apellido_materno ASC` — los ingresantes con más candidatos y mayor similitud aparecen primero.

**[Corregido 2026-07-07 — DA-G1]:** Esta TC describía el comportamiento deseado, pero el código desplegado (`whereHas('candidatos', >= 80)`) **excluye** filas en vez de ordenarlas al final, y ordena primero por `max_similitud DESC` (no `candidatos_count DESC`). Esta TC hoy **falla** contra el código real; queda como especificación del comportamiento correcto hasta que T024 se implemente. Ver TC-059 para el caso específico de cero candidatos.

---

#### TC-059: Ingresante sin candidatos aparece en pendientes, ordenado al final

| Atributo | Valor |
|----------|-------|
| **Tipo** | Integración |
| **Prioridad** | P1 |
| **Automatizado** | Planificado (bloqueado por T024 y T020) |
| **Trazas a** | plan.md DA-G1 (AC-G1.1–AC-G1.5), tasks.md T024 |

**Dado:** Un lote con dos ingresantes `pendiente`: uno con 3 candidatos persistidos y otro sin ningún candidato (similitud máxima < 70% frente a toda la academia).
**Cuando:** Se llama `GET /api/cruce/lotes/{lote_id}/pendientes`.
**Entonces:** Ambos ingresantes aparecen en la respuesta (ninguno es excluido); el que tiene 0 candidatos aparece **después** del que tiene 3, con `candidatos: []` y `max_similitud: 0`; y `meta.total` cuenta ambos registros.

**Nota:** Este caso es actualmente imposible de pasar contra el código desplegado, porque `whereHas('candidatos', >= 80)` excluye por completo al ingresante sin candidatos del result set. Ver tasks.md T024.

---

#### TC-049: GET /api/cruce/lotes — List all batches

| Atributo | Valor |
|----------|-------|
| **Tipo** | Integración |
| **Prioridad** | P1 (High) |
| **Automatizado** | Sí |
| **Trazas a** | US-001, US-004, NFR-005, openapi.yaml `/cruce/lotes` GET, plan.md §4.1 |

**Dado** que existen lotes procesados en el sistema
**Y** el usuario está autenticado
**Cuando** realiza GET /api/cruce/lotes
**Entonces** el response HTTP es 200
**Y** el body es un array paginado de objetos LoteCruce
**Y** cada objeto contiene: lote_id, estado (enum: processing|completed|paused|error), fecha_examen, total_rows, rows_procesadas, created_at
**Y** el schema cumple con openapi.yaml LoteCruce

**Caso negativo:**
**Dado** que el usuario NO está autenticado
**Cuando** realiza GET /api/cruce/lotes
**Entonces** el response HTTP es 401

---

### TC-050: CruceBatchProcessedEvent dispatched on batch success

**ID:** TC-050
**US:** US-001
**AC:** (AsyncAPI contract)
**Trazas a:** asyncapi.yaml CruceBatchProcessedEvent, tasks.md T007
**Priority:** High

**Dado** que un lote CSV fue procesado exitosamente
**Y** todos los registros fueron clasificados (ingresantes o no_ingresantes)
**Cuando** el job ProcessCsvBatchJob finaliza sin errores
**Entonces** se dispatcha el evento CruceBatchProcessedEvent
**Y** el payload contiene: lote_id, total_registros, total_ingresantes, total_no_ingresantes
**Y** verificable via Event::fake() en tests de integración

---

### TC-051: CruceBatchFailedEvent dispatched on batch failure

**ID:** TC-051
**US:** US-001
**AC:** (AsyncAPI contract)
**Trazas a:** asyncapi.yaml CruceBatchFailedEvent, tasks.md T007
**Priority:** High

**Dado** que un lote CSV está en procesamiento
**Y** ocurre un error irrecuperable durante el job
**Cuando** el job ProcessCsvBatchJob falla definitivamente
**Entonces** se dispatcha el evento CruceBatchFailedEvent
**Y** el payload contiene: lote_id y detalles del error
**Y** verificable via Event::fake() en tests de integración

---

### 2.3 Historia de Usuario: US-003 - Motor de Coincidencia en Dos Fases

#### TC-006: Cruce exacto automático con 2 apellidos y 1 nombre

| Atributo | Valor |
|----------|-------|
| **Tipo** | Integración |
| **Prioridad** | P1 |
| **Automatizado** | Sí |
| **Trazas a** | US-003, AC-008, plan.md: RealizarCruceExactoAction |

**Dado:** Un ingresante normalizado con apellidos y nombre que existen en `academia`.
**Cuando:** Se ejecuta `RealizarCruceExactoAction::executeBatch()`.
**Entonces:** El sistema busca match por nombre compuesto (`findMatchByName`). Si encuentra coincidencia de 2 apellidos + al menos 1 nombre, asigna `alumno_id`, estado `confirmado_automatico` y datos enriquecidos.

**Datos de Prueba:**
- Ingresante: `APELLIDO_PATERNO=PEREZ`, `APELLIDO_MATERNO=LOPEZ`, `NOMBRES=JUAN`
- Academia: persona con `apellido_paterno=PEREZ`, `apellido_materno=LOPEZ`, `nombres=JUAN`
- Esperado: match por nombre, estado `confirmado_automatico`

---

#### TC-007: Cálculo de similitud difusa y top 5 candidatos ordenados

| Atributo | Valor |
|----------|-------|
| **Tipo** | Unidad / Integración |
| **Prioridad** | P1 |
| **Automatizado** | Sí |
| **Trazas a** | US-003, AC-009, plan.md: CalcularSimilitudesCabosAction |

**Dado:** Un ingresante sin match exacto y una lista de candidatos en `academia`.
**Cuando:** Se calcula similitud usando el Dice coefficient sobre bigramas de caracteres y Levenshtein (fórmula: `similitud = Levenshtein × 0.6 + Dice_bigramas × 0.4`).
**Entonces:** Genera hasta 5 candidatos ordenados de mayor a menor probabilidad de match.

**Datos de Prueba:**
- Entrada: `NOMBRE=JHON`, `APELLIDO_PATERNO=RAMOS`, `APELLIDO_MATERNO=LOPEZ` (ingresante) vs `JOHN RAMOS LOPEZ` (academia)
- Esperado: similitud >= 85% con la fórmula Dice bigramas; lista ordenada por puntaje, máximo 5 candidatos.

---

#### TC-008: Ningún candidato supera el umbral de similitud y se expone opción "No Ingresado"

| Atributo | Valor |
|----------|-------|
| **Tipo** | Integración |
| **Prioridad** | P1 |
| **Automatizado** | Sí |
| **Trazas a** | US-003, AC-010, plan.md: CalcularSimilitudesCabosAction |

**Dado:** Un ingresante con similitud máxima < 70% frente a alumnos de academia.
**Cuando:** Se calcula la lista de candidatos.
**Entonces:** La lista está vacía y el sistema marca al ingresante como `pendiente` con opción de `no_ingresado` en la interfaz.


---

#### TC-056: Flat array + integer index byName — sin duplicación

| Atributo | Valor |
|----------|-------|
| **Tipo** | Unidad |
| **Prioridad** | P2 |
| **Automatizado** | Sí |
| **Trazas a** | US-003, plan.md: Optimization Strategies |

**Dado:** `getActiveAlumnos()` retorna ~25,000-30,000 registros de academia.
**Cuando:** Se construye el índice `byName`.
**Entonces:** El índice almacena solo enteros (posiciones en `$alumnos[]`), nunca copias de los datos completos. El arreglo `$alumnos` tiene exactamente N elementos y el índice apunta a posiciones dentro de él, sin duplicar los arrays asociativos de cada alumno.

**Verificación:** Comparar `memory_get_usage()` antes y después de construir el índice. No debe existir `byDni` (el CSV no contiene DNI).

---

### 2.4 Historia de Usuario: US-004 - Interfaz de Validación Asistida

#### TC-009: Interfaz pendiente muestra candidato ordenado y confirma match manual

| Atributo | Valor |
|----------|-------|
| **Tipo** | E2E |
| **Prioridad** | P1 |
| **Automatizado** | Sí / Planificado |
| **Trazas a** | US-004, AC-011, AC-012, AC-013, plan.md: UnmatchedRow.jsx, api.js |

**Dado:** Un ingresante en estado `pendiente` y una lista de candidatos con porcentajes.
**Cuando:** El administrador selecciona un candidato y presiona "Confirmar Match".
**Entonces:** Se llama a `POST /api/cruce/ingresantes/{id}/confirmar`, el registro pasa a `confirmado_manual`, y la UI muestra éxito.

**Datos de Prueba:**
- Entrada: alumno válido desde `academia`.
- Esperado: estado `confirmado_manual` y datos enriquecidos actualizados.

---

#### TC-010: Marcar como "No Ingresado" cuando no hay candidato válido

| Atributo | Valor |
|----------|-------|
| **Tipo** | E2E |
| **Prioridad** | P2 |
| **Automatizado** | Sí / Planificado |
| **Trazas a** | US-004, AC-013 |

**Dado:** Un ingresante sin candidatos relevantes.
**Cuando:** El administrador selecciona la opción "Sin coincidencias encontradas — Marcar como No Ingresado".
**Entonces:** El estado se actualiza a `no_ingresado` y la UI refleja la confirmación.

**[Corregido 2026-07-07 — DA-G3]:** El código desplegado de `CruceIngresantesController::confirmar` **no** lee `marcar_no_ingresado` del request — valida solo `alumno_id` y siempre invoca `GuardarCruceConfirmadoAction::execute($id, $request->integer('alumno_id'))`. Como `$request->integer('alumno_id')` retorna `0` cuando el campo está ausente, esta acción hoy persiste `estado_match='confirmado_manual', alumno_id=0` (registro corrupto) en vez de `no_ingresado, alumno_id=NULL`. Esta TC **falla contra el código real** hasta que se implemente tasks.md T026. Ver TC-057/TC-058 para casos específicos del contrato corregido.

---

#### TC-057: `marcar_no_ingresado=true` persiste `no_ingresado` con `alumno_id=NULL` (nunca 0)

| Atributo | Valor |
|----------|-------|
| **Tipo** | Integración |
| **Prioridad** | P0 |
| **Automatizado** | Planificado (bloqueado por T026 y T020) |
| **Trazas a** | plan.md DA-G3 (AC-G3.1, AC-G3.2), data-model.md §4/§10, tasks.md T026 |

**Dado:** Un ingresante en estado `pendiente`.
**Cuando:** Se envía `POST /api/cruce/ingresantes/{id}/confirmar` con body `{ "marcar_no_ingresado": true }` (sin `alumno_id`, o con un `alumno_id` presente que debe ser ignorado).
**Entonces:** El ingresante queda con `estado_match='no_ingresado'` y `alumno_id=NULL`; `lotes_cruce.total_pendientes` decrementa en 1 y `total_no_ingresado` incrementa en 1. En ningún caso se persiste `alumno_id=0`.

**Nota:** Contra el código desplegado hoy (2026-07-07), este test **falla** — ver el bug descrito en TC-010 y tasks.md T012/T026.

---

#### TC-058: `marcar_no_ingresado` false/ausente exige `alumno_id` válido existente

| Atributo | Valor |
|----------|-------|
| **Tipo** | Integración |
| **Prioridad** | P1 |
| **Automatizado** | Planificado (bloqueado por T026 y T020) |
| **Trazas a** | plan.md DA-G3 (AC-G3.3, AC-G3.4), ERR-006, tasks.md T026 |

**Dado:** Un ingresante en estado `pendiente`.
**Cuando:** Se envía `POST /api/cruce/ingresantes/{id}/confirmar` con `marcar_no_ingresado` false o ausente y (a) sin `alumno_id`, o (b) con un `alumno_id` que no existe en `academia`.
**Entonces:** El endpoint retorna HTTP 422 (caso a, campo requerido faltante) o HTTP 404 (caso b, ERR-006); el estado del ingresante no cambia; en ningún caso se persiste `estado_match='confirmado_manual'` con `alumno_id` nulo o `0`.

---

#### TC-052: CSV con BOM UTF-8 es procesado correctamente

| Atributo | Valor |
|----------|-------|
| **Tipo** | Integración |
| **Prioridad** | P1 |
| **Automatizado** | Sí |
| **Trazas a** | US-001, AC-001a |

**Dado:** Un archivo CSV con BOM UTF-8 (`\xEF\xBB\xBF`) al inicio (común en exportaciones de Excel).
**Cuando:** Se sube el archivo vía `POST /api/cruce/upload`.
**Entonces:** El sistema detecta y remueve el BOM antes de validar los headers. Los headers se reconocen correctamente y el lote se crea sin errores de "Formato de columnas incorrecto".

**Datos de Prueba:**
- Input: CSV file con `\xEF\xBB\xBF` + `CODIGO,APELLIDOS,...`
- Esperado: HTTP 202 con `lote_id` (no HTTP 400 por headers inválidos).

---

### 2.5 Historia de Usuario: US-005 - Exportación de Reporte Consolidado en CSV

#### TC-011: Generar CSV consolidado con datos crudos y enriquecidos

| Atributo | Valor |
|----------|-------|
| **Tipo** | Integración |
| **Prioridad** | P2 |
| **Automatizado** | Sí |
| **Trazas a** | US-005, AC-014, plan.md: ExportarExcelCruceAction |

**Dado:** Un lote procesado con matches confirmados.
**Cuando:** Se solicita `GET /api/cruce/lotes/{lote_id}/exportar`.
**Entonces:** Se descarga un único archivo CSV (delimitador `;`, BOM UTF-8, `Content-Type: text/csv`) con columnas A–M del CSV original y columnas N+ con Sede, Ciclo, Año académico y Estado — **no** un archivo `.xlsx` ni una "Hoja 1" (no existen múltiples hojas).

---

#### TC-012: ~~Generar Excel con gráficos analíticos en Hoja 2~~ — REMOVIDO

| Atributo | Valor |
|----------|-------|
| **Tipo** | N/A |
| **Prioridad** | N/A |
| **Automatizado** | N/A |
| **Trazas a** | ~~US-005, AC-015~~ AC-016 (removida) |

**[Removido 2026-07-07]:** Este caso de prueba apuntaba a AC-016 (Hoja 2 con gráficos analíticos en un archivo `.xlsx` nativo), que era aspiracional y nunca se implementó — el export real es un stream CSV plano vía `fputcsv`, sin dependencia de PhpSpreadsheet. El PO confirmó que esto es aceptable tal cual (2026-07-07); no se programa como trabajo futuro. Se conserva este ID como registro histórico de trazabilidad, no como un caso de prueba activo.

---

## 3. Pruebas de Casos de Borde

### EC-001: Registro CSV con nombre o apellido vacío

#### TC-013: Continuar procesamiento y registrar error por fila incompleta

| Atributo | Valor |
|----------|-------|
| **Tipo** | Unidad / Integración |
| **Prioridad** | P2 |
| **Automatizado** | Sí |
| **Trazas a** | EC-001 |

**Dado:** Una fila CSV con `NOMBRES` vacío.
**Cuando:** Se procesa el lote.
**Entonces:** Se registra un error en el log del lote con número de fila y el job continúa con las demás filas.

---

### EC-002: CSV sin columnas requeridas

#### TC-014: Rechazar carga con mensaje de columnas faltantes

| Atributo | Valor |
|----------|-------|
| **Tipo** | Integración |
| **Prioridad** | P1 |
| **Automatizado** | Sí |
| **Trazas a** | EC-002, ERR-001 |

**Dado:** Un CSV faltando `NOMBRES`, `OBSERVACION` o `FECHA`.
**Cuando:** Se intenta subir el archivo.
**Entonces:** La carga se rechaza con HTTP 422 y mensaje que indica las columnas faltantes.

---

### EC-003: Motor difuso sin candidatos superiores al umbral

#### TC-015: Mostrar opción "No Ingresado" sin bloquear el flujo

| Atributo | Valor |
|----------|-------|
| **Tipo** | Integración |
| **Prioridad** | P2 |
| **Automatizado** | Sí |
| **Trazas a** | EC-003 |

**Dado:** Un ingresante cuya similitud máxima es < 70%.
**Cuando:** Se genera la lista de candidatos.
**Entonces:** La lista está vacía y la opción `no_ingresado` es accesible en la interfaz.


---

### EC-004: Fecha de examen ya procesada

#### TC-016: Ignorar registros de fecha ya existente y registrar el salto

| Atributo | Valor |
|----------|-------|
| **Tipo** | Integración |
| **Prioridad** | P1 |
| **Automatizado** | Sí |
| **Trazas a** | EC-004 |

**Dado:** CSV con fecha `2026-05-10` ya procesada en `lotes_cruce`.
**Cuando:** Se vuelve a subir el CSV.
**Entonces:** Los registros de esa fecha se ignoran silenciosamente y el log del lote registra la fecha omitida.

---

### EC-005: Más de 5 candidatos históricos con igualdad de similitud

#### TC-017: Limitar candidatos a 5 y desempatar por apellido paterno

| Atributo | Valor |
|----------|-------|
| **Tipo** | Unidad |
| **Prioridad** | P2 |
| **Automatizado** | Sí |
| **Trazas a** | EC-005 |

**Dado:** Más de 5 alumnos con similitud igual.
**Cuando:** Se ordenan candidatos.
**Entonces:** Se muestran solo los 5 primeros y los empates se desempatan por apellido paterno alfabético.

---

### EC-006: CSV con codificación no UTF-8/ISO-8859-1

#### TC-018: Detectar codificación inválida y rechazar con error descriptivo

| Atributo | Valor |
|----------|-------|
| **Tipo** | Integración |
| **Prioridad** | P1 |
| **Automatizado** | Sí |
| **Trazas a** | EC-006, ERR-002 |

**Dado:** CSV codificado en UTF-16.
**Cuando:** Se sube el archivo.
**Entonces:** La carga es rechazada con mensaje de codificación y no se insertan registros.

---

### EC-007: Timeout o error de conexión durante el cruce

#### TC-019: Pausar lote y dejar registros `pendiente` cuando la DB academia falla

| Atributo | Valor |
|----------|-------|
| **Tipo** | Integración |
| **Prioridad** | P1 |
| **Automatizado** | Sí |
| **Trazas a** | EC-007 |

**Dado:** Conexión a `academia` falla durante el proceso.
**Cuando:** `RealizarCruceExactoAction` se ejecuta.
**Entonces:** El lote se marca `paused` (fallo recuperable, ver CQ-003); los registros ya procesados conservan su estado; los no procesados quedan en `pendiente` para reintento. El sistema NO marca `error` ante fallo de conexión recuperable.

---

### EC-008: Worker Redis caído durante el procesamiento

#### TC-020: Garantizar job en `failed_jobs` y mantener lote consistente

| Atributo | Valor |
|----------|-------|
| **Tipo** | Integración |
| **Prioridad** | P1 |
| **Automatizado** | Sí |
| **Trazas a** | EC-008, NFR-006 |

**Dado:** Worker Redis reiniciado durante un job activo.
**Cuando:** El job falla.
**Entonces:** El job debe aparecer en `failed_jobs`; el lote permanece en estado `processing` sin registros duplicados ni perdidos.

---

### EC-009: CSV exportado desde Excel con BOM UTF-8

#### TC-053: BOM al inicio del archivo no impide el reconocimiento de headers

| Atributo | Valor |
|----------|-------|
| **Tipo** | Integración |
| **Prioridad** | P1 |
| **Automatizado** | Sí |
| **Trazas a** | EC-009, US-001 AC-001a |

**Dado:** Un archivo CSV exportado desde Excel que incluye BOM UTF-8 (`\xEF\xBB\xBF`) antes del header `CODIGO`.
**Cuando:** Se sube el archivo vía `POST /api/cruce/upload`.
**Entonces:** El BOM se remueve automáticamente, los headers se reconocen como `CODIGO, APELLIDOS, NOMBRES...` y el lote se crea exitosamente. Sin el stripping del BOM, el primer header se leería como `\xEF\xBB\xBFCODIGO` y la validación fallaría.

---

## 4. Escenarios de Error

### ERR-001: CSV con formato de columnas incorrecto

#### TC-021: Rechazar carga cuando columnas requeridas tienen nombres incorrectos

| Atributo | Valor |
|----------|-------|
| **Tipo** | Integración |
| **Prioridad** | P1 |
| **Automatizado** | Sí |
| **Trazas a** | ERR-001, US-001 AC-001a |

**Dado:** Un CSV que contiene 12 columnas pero con nombres incorrectos (ej: `APELLIDO` en lugar de `APELLIDOS`, `NOMBRE` en lugar de `NOMBRES`, `FECHA_EXAMEN` en lugar de `FECHA`).
**Cuando:** Se hace `POST /api/cruce/upload`.
**Entonces:** HTTP 422, mensaje de error que lista las columnas con nombres incorrectos o faltantes y no se crea ningún registro en BD.

> **Diferencia con TC-014:** TC-014 cubre columnas AUSENTES; TC-021 cubre columnas PRESENTES pero con nombres incorrectos. Ambos casos están definidos en AC-001a.

---

### ERR-002: Codificación de archivo no soportada

#### TC-022: Rechazar archivo con codificación inválida antes de procesar

| Atributo | Valor |
|----------|-------|
| **Tipo** | Integración |
| **Prioridad** | P1 |
| **Automatizado** | Sí |
| **Trazas a** | ERR-002 |

**Dado:** CSV con codificación UTF-16.
**Cuando:** Se sube el archivo.
**Entonces:** HTTP 422 con mensaje de codificación no soportada.

---

### ERR-003: Fallo de conexión a BD `academia`

#### TC-023: Abortar el cruce con mensaje y registrar el fallo

| Atributo | Valor |
|----------|-------|
| **Tipo** | Integración |
| **Prioridad** | P1 |
| **Automatizado** | Sí |
| **Trazas a** | ERR-003 |

**Dado:** Conexión a `academia` no disponible.
**Cuando:** Se ejecuta el proceso de cruce.
**Entonces:** La operación falla limpiamente con mensaje de usuario y el lote queda en estado `paused` (fallo recuperable, ver CQ-003).

---

### ERR-004: CSV vacío tras filtro de OBSERVACION

#### TC-024: Rechazar carga cuando no hay registros `ALCANZO VACANTE`

| Atributo | Valor |
|----------|-------|
| **Tipo** | Integración |
| **Prioridad** | P1 |
| **Automatizado** | Sí |
| **Trazas a** | ERR-004 |

**Dado:** CSV donde ninguna fila tiene `OBSERVACION=ALCANZO VACANTE`.
**Cuando:** Se sube el archivo.
**Entonces:** HTTP 422 y mensaje que indica que el CSV no contiene registros válidos.

---

### ERR-005: Archivo mayor a 20 MB

#### TC-025: Rechazar carga de archivo demasiado grande

| Atributo | Valor |
|----------|-------|
| **Tipo** | Integración |
| **Prioridad** | P1 |
| **Automatizado** | Sí |
| **Trazas a** | ERR-005 |

**Dado:** Un archivo CSV de 21 MB.
**Cuando:** Se intenta subir.
**Entonces:** HTTP 413 y mensaje de límite de tamaño.

---

### ERR-006: Confirmación con `alumno_id` inválido

#### TC-026: Manejar selección inválida en la interfaz de confirmación

| Atributo | Valor |
|----------|-------|
| **Tipo** | Integración |
| **Prioridad** | P1 |
| **Automatizado** | Sí |
| **Trazas a** | ERR-006 |

**Dado:** La interfaz envía un `alumno_id` inexistente.
**Cuando:** Se hace `POST /api/cruce/ingresantes/{id}/confirmar`.
**Entonces:** HTTP 404 y el estado del ingresante no cambia.

---

### ERR-007: Job falla y mueve a `failed_jobs`

#### TC-027: Capturar job fallido y mantener lote en estado pausado

| Atributo | Valor |
|----------|-------|
| **Tipo** | Integración |
| **Prioridad** | P1 |
| **Automatizado** | Sí |
| **Trazas a** | ERR-007, NFR-006 |

**Dado:** Job `ProcessCsvBatchJob` lanza una excepción inesperada no recuperable.
**Cuando:** El worker de Redis procesa el job.
**Entonces:** El job aparece en `failed_jobs`, el lote se marca específicamente como `error` (fallo catastrófico, ver CQ-003) y no se pierden ni duplican registros ya insertados.

---

## 5. Pruebas No Funcionales

### NFR-001: Rendimiento de carga asíncrona

#### TC-028: Procesar un CSV de ~27,000 filas en menos de 50 segundos

| Atributo | Valor |
|----------|-------|
| **Tipo** | Rendimiento |
| **Prioridad** | P1 |
| **Automatizado** | Sí |
| **Trazas a** | NFR-001, plan.md: Redis Queue |

**Escenario:** Despachar un job con un CSV sintético de 27,000 filas.
**Objetivo:** `lotes_cruce.estado = 'completed'` en < 50 segundos.

---

### NFR-002: Tiempo de respuesta de fuzzy match

#### TC-029: Endpoint de candidatos responde en < 300 ms p95

| Atributo | Valor |
|----------|-------|
| **Tipo** | Rendimiento |
| **Prioridad** | P1 |
| **Automatizado** | Sí |
| **Trazas a** | NFR-002, plan.md: API endpoint de candidatos |

**Escenario:** Consultar `GET /api/cruce/ingresantes/{ingresante_id}/candidatos` con carga representativa.
**Objetivo:** p95 < 300 ms.

---

### NFR-003: Soporte de carga de archivo hasta 20 MB

#### TC-030: Aceptar archivo CSV de 20 MB sin error de memoria

| Atributo | Valor |
|----------|-------|
| **Tipo** | Rendimiento |
| **Prioridad** | P2 |
| **Automatizado** | Sí |
| **Trazas a** | NFR-003 |

**Dado:** Archivo de 20 MB.
**Cuando:** Se sube mediante el endpoint de carga.
**Entonces:** Respuesta HTTP exitosa y job encolado sin error de memoria.

---

### NFR-004: Seguridad de credenciales

#### TC-031: Validar que credenciales de `academia` no están en el repositorio

| Atributo | Valor |
|----------|-------|
| **Tipo** | Seguridad |
| **Prioridad** | P1 |
| **Automatizado** | Sí |
| **Trazas a** | NFR-004 |

**Dado:** Repositorio de código.
**Cuando:** Se ejecuta revisión de secrets.
**Entonces:** No existen credenciales de BD en el repositorio; solo variables de entorno.

---

### NFR-005: Trazabilidad de lotes

#### TC-032: Verificar totales y metadatos de `lotes_cruce`

| Atributo | Valor |
|----------|-------|
| **Tipo** | Integración |
| **Prioridad** | P1 |
| **Automatizado** | Sí |
| **Trazas a** | NFR-005 |

**Dado:** Lote procesado.
**Cuando:** Se consulta `lotes_cruce`.
**Entonces:** Existen fecha de examen, totales de registros, ingresantes, no_ingresantes, match exacto, pendientes, no_ingresados y timestamps de inicio/fin.

---

### NFR-006: Procesamiento asíncrono con Redis

#### TC-033: Ejecutar job en Redis y soportar reinicio sin pérdida de datos

| Atributo | Valor |
|----------|-------|
| **Tipo** | Integración |
| **Prioridad** | P1 |
| **Automatizado** | Sí |
| **Trazas a** | NFR-006, plan.md: Redis Queue |

**Dado:** Worker Redis activo.
**Cuando:** Se encola `ProcessCsvBatchJob` y el worker se reinicia durante el procesamiento.
**Entonces:** El job falla a `failed_jobs`; el lote no pierde registros y puede reintentarse.

---

### 5.2 Pruebas de Lógica de Negocio Adicionales (Campos y Reportes)

#### TC-034: Mapeo de EAP a AREA académica en UNMSM

| Atributo | Valor |
|----------|-------|
| **Tipo** | Unidad |
| **Prioridad** | P1 |
| **Automatizado** | Sí |
| **Trazas a** | US-005, AC-014, plan.md: ExportarExcelCruceAction |

**Dado:** Diferentes carreras profesionales de UNMSM en el CSV (`EAP`).
**Cuando:** Se calcula la columna `AREA` en el reporte.
**Entonces:** El sistema asocia correctamente la carrera a su área académica correspondiente.

**Datos de Prueba:**
- `"MEDICINA HUMANA"` -> `Área A`
- `"CIENCIAS BIOLOGICAS"` -> `Área B`
- `"INGENIERIA DE SOFTWARE"` -> `Área C`
- `"ADMINISTRACION"` -> `Área D`
- `"DERECHO"` -> `Área E`

---

#### TC-035: Validación de la estructura de 24 columnas del reporte final

| Atributo | Valor |
|----------|-------|
| **Tipo** | Integración |
| **Prioridad** | P1 |
| **Automatizado** | Sí |
| **Trazas a** | US-005, AC-014 |

**Dado:** Un lote de cruce finalizado con alumnos coincidentes.
**Cuando:** Se genera y descarga el CSV consolidado.
**Entonces:** El archivo contiene exactamente 24 columnas en el orden A-X especificado en `AC-014` y los campos de la base de datos se corresponden correctamente.

---

#### TC-036: Cálculo de LISTA - 1 (Cachimbos Históricos)

| Atributo | Valor |
|----------|-------|
| **Tipo** | Unidad |
| **Prioridad** | P1 |
| **Automatizado** | Sí |
| **Trazas a** | US-005, AC-014 |

**Dado:** Alumnos matriculados en diferentes ciclos históricos de Vonex.
**Cuando:** Se realiza la exportación del CSV.
**Entonces:** La columna `LISTA - 1` se marca con `1` si el ciclo es igual o posterior a "Verano 2024", y con `0` si es anterior.

**Datos de Prueba:**
- Ciclo "Verano 2024" -> `1`
- Ciclo "Verano 2025" -> `1`
- Ciclo "Anual 2023" -> `0`

---

#### TC-037: Cálculo de LISTA - 2 (Cachimbos Temporada)

| Atributo | Valor |
|----------|-------|
| **Tipo** | Unidad |
| **Prioridad** | P1 |
| **Automatizado** | Sí |
| **Trazas a** | US-005, AC-014 |

**Dado:** Alumnos matriculados en ciclos del verano 2026, octubre 2025 o activos a febrero 2026.
**Cuando:** Se realiza la exportación del CSV.
**Entonces:** La columna `LISTA - 2` se marca con `1` si se cumple la condición de temporada (incluyendo retirados/suspendidos), y con `0` si no.

**Datos de Prueba:**
- Ciclo "VERANO 2026", Estado "RETIRADO" -> `1`
- Ciclo "OCTUBRE 2025", Estado "SUSPENDIDO" -> `1`
- Ciclo "ANUAL 2025", Estado "MATRICULADO" (no activo a feb 2026) -> `0`

---

#### TC-038: Cálculo de LISTA - 3 (Cachimbos Activos a Febrero 2026)

| Atributo | Valor |
|----------|-------|
| **Tipo** | Unidad |
| **Prioridad** | P1 |
| **Automatizado** | Sí |
| **Trazas a** | US-005, AC-014 |

**Dado:** Alumnos matriculados en la academia.
**Cuando:** Se realiza la exportación del CSV.
**Entonces:** La columna `LISTA - 3` se marca con `1` si el alumno es activo (MATRICULADO, PAGADO, FINALIZADO) al 27 de febrero de 2026, y con `0` en cualquier otro caso.

**Datos de Prueba:**
- Ciclo "Verano 2026", Estado "MATRICULADO", fecha de matrícula <= 27/02/2026 -> `1`
- Ciclo "Verano 2026", Estado "RETIRADO", fecha de retiro <= 27/02/2026 -> `0`

---

### 5.4 Pruebas de Invariantes de Negocio

#### TC-039: Solo RealizarCruceExactoAction puede asignar estado `confirmado_automatico` (INV-01)

| Atributo | Valor |
|----------|-------|
| **Tipo** | Unidad |
| **Prioridad** | P1 |
| **Automatizado** | Sí |
| **Trazas a** | INV-01, US-003 AC-008 |

**Dado:** Un ingresante en estado `pendiente`.
**Cuando:** Se intenta actualizar directamente `estado_match` a `confirmado_automatico` desde un path de código distinto a `RealizarCruceExactoAction` (ej. `GuardarCruceConfirmadoAction`, controlador directo o Tinker).
**Entonces:** La operación es rechazada o detectada como violación de invariante. Solo `RealizarCruceExactoAction` puede asignar este estado.

**Enfoque de implementación:** Encapsular la asignación de `confirmado_automatico` en un método privado o protegido dentro de `RealizarCruceExactoAction` y usar un event/observer o policy que valide el origen del cambio.

---

#### TC-040: Tabla `no_ingresantes` es append-only — sin DELETE ni UPDATE (INV-02)

| Atributo | Valor |
|----------|-------|
| **Tipo** | Integración |
| **Prioridad** | P1 |
| **Automatizado** | Sí |
| **Trazas a** | INV-02 |

**Dado:** Registros existentes en la tabla `no_ingresantes`.
**Cuando:** Se intenta ejecutar una operación `DELETE` o `UPDATE` sobre la tabla `no_ingresantes`.
**Entonces:** La operación es rechazada a nivel de BD por el trigger `trg_no_ingresantes_readonly` (INV-02 enforceado a nivel DDL — ver data-model.md §5.1). El modelo Eloquent `NoIngresante` también lo rechaza a nivel de aplicación (`const UPDATED_AT = null`). Ambas capas deben fallar independientemente.

**Datos de prueba:**
- Insertar un registro válido en `no_ingresantes`.
- Intentar `NoIngresante::find($id)->update([...])` → debe lanzar excepción Eloquent.
- Intentar `DB::statement("DELETE FROM no_ingresantes WHERE id = ?", [$id])` → debe lanzar excepción PostgreSQL del trigger (código SQLSTATE P0001).
- Intentar `DB::statement("UPDATE no_ingresantes SET observacion = 'X' WHERE id = ?", [$id])` → idem.

---

#### TC-041: Cero operaciones de escritura sobre la conexión `academia` (INV-07)

| Atributo | Valor |
|----------|-------|
| **Tipo** | Integración |
| **Prioridad** | P1 |
| **Automatizado** | Sí |
| **Trazas a** | INV-07, US-002 |

**Dado:** Un lote de ingresantes procesado y cruzado contra la base de datos `academia`.
**Cuando:** Se ejecuta el pipeline completo (importación + cruce exacto + fuzzy match).
**Entonces:** Se interceptan todas las queries ejecutadas contra la conexión `academia` (usando `DB::connection('academia')->listen()`) y se verifica que NINGUNA sea de tipo `INSERT`, `UPDATE` o `DELETE`. Solo se permiten operaciones `SELECT`.

---

#### TC-042: Constraint UNIQUE en `lotes_cruce.fecha_examen` rechaza INSERT duplicado a nivel de BD (INV-03)

| Atributo | Valor |
|----------|-------|
| **Tipo** | Integración |
| **Prioridad** | P1 |
| **Automatizado** | Sí |
| **Trazas a** | INV-03, data-model.md §5.1 |

**Dado:** Un registro existente en `lotes_cruce` con `fecha_examen = '2026-05-17'`.
**Cuando:** Se intenta ejecutar directamente `INSERT INTO lotes_cruce (fecha_examen, ...) VALUES ('2026-05-17', ...)` a nivel de SQL (simulando bypass de la lógica de aplicación).
**Entonces:** PostgreSQL lanza una excepción de violación de constraint UNIQUE (`duplicate key value violates unique constraint "lotes_cruce_fecha_examen_key"`). La inserción es rechazada sin datos corruptos.

---

#### TC-043: Filas idénticas dentro del mismo CSV solo producen un registro en BD (INV-04)

| Atributo | Valor |
|----------|-------|
| **Tipo** | Unidad |
| **Prioridad** | P1 |
| **Automatizado** | Sí |
| **Trazas a** | INV-04, CQ-002, US-001 AC-001 |

**Dado:** Un CSV con 3 filas completamente idénticas (mismo código, apellidos, nombres, EAP, puntaje, mérito, observación, tipo, modalidad, universidad, período y fecha).
**Cuando:** `ProcesarCargaCsvAction` procesa el lote.
**Entonces:** Solo se persiste 1 registro en la tabla correspondiente (`ingresantes` o `no_ingresantes`); las 2 filas duplicadas son eliminadas antes de cualquier INSERT. El total reportado en `lotes_cruce` refleja 1 registro, no 3.

---

#### TC-044: Valor crudo de OBSERVACION nunca es evaluado en el filtro — solo el normalizado (INV-05)

| Atributo | Valor |
|----------|-------|
| **Tipo** | Unidad |
| **Prioridad** | P1 |
| **Automatizado** | Sí |
| **Trazas a** | INV-05, CQ-001, US-001 AC-004 |

**Dado:** Un CSV con una fila cuyo campo `OBSERVACION` contiene `alcanzó vacante` (minúsculas y con tilde — que post-normalización resulta en `ALCANZO VACANTE`).
**Cuando:** `ProcesarCargaCsvAction` aplica el filtro.
**Entonces:** El registro se enruta a `ingresantes` (el filtro opera sobre el valor normalizado, no el crudo). Verificar en el código que el valor crudo del CSV nunca es comparado directamente con ningún string de filtro.

**Dato adicional de violación:** Si se modifica `ProcesarCargaCsvAction` para comparar el string crudo, este test DEBE fallar. Esto lo convierte en un test de regresión de la invariante.

---

#### TC-045: Jerarquía de estados cubre todas las combinaciones de borde de INV-06

| Atributo | Valor |
|----------|-------|
| **Tipo** | Unidad |
| **Prioridad** | P1 |
| **Automatizado** | Sí |
| **Trazas a** | INV-06, US-002 AC-007 |

**Dado:** Un alumno con múltiples registros históricos en `academia` en diferentes combinaciones de estado.
**Cuando:** Se resuelve el estado mediante la jerarquía de INV-06.
**Entonces:** El estado resuelto es siempre el de mayor prioridad según el orden: `MATRICULADO (2) > PAGADO (3) > FINALIZADO (14) > SUSPENDIDO (9) > RETIRADO (0) > TRASLADADO (12) > STAND BY (13) > ANULADO (11)`.

**Datos de prueba — casos de borde obligatorios (valores numéricos en la DB real):**

| Estados presentes (DB values) | Estado resuelto esperado |
|---|---|
| `ANULADO (11)`, `STAND BY (13)` | `STAND BY` |
| `RETIRADO (0)`, `TRASLADADO (12)`, `ANULADO (11)` | `RETIRADO` |
| `SUSPENDIDO (9)`, `FINALIZADO (14)` | `FINALIZADO` |
| `MATRICULADO (2)`, `ANULADO (11)`, `RETIRADO (0)` | `MATRICULADO` |
| Solo `ANULADO (11)` | `ANULADO` |
| Solo `STAND BY (13)` | `STAND BY` |

---

#### TC-046: Credenciales de `academia` no existen en ningún archivo del repositorio (INV-08)

| Atributo | Valor |
|----------|-------|
| **Tipo** | Seguridad |
| **Prioridad** | P1 |
| **Automatizado** | Sí |
| **Trazas a** | INV-08, NFR-004, TC-031 |

**Dado:** El repositorio de código completo.
**Cuando:** Se ejecuta un scanner de secretos (ej. `git-secrets`, `trufflehog`, o búsqueda por regex de `DB_ACADEMIA_PASSWORD`, `password`, IPs de servidor de producción).
**Entonces:** No se encuentran valores reales de credenciales en ningún archivo rastreado por git. Solo se permiten referencias a variables de entorno (`DB_ACADEMIA_*`). El archivo `.env.example` solo contiene placeholders vacíos o descriptivos (ej. `DB_ACADEMIA_PASSWORD=`).

> **Diferencia con TC-031 (NFR-004):** TC-031 verifica la política general de credenciales; TC-046 verifica específicamente el enforcement del invariante INV-08 para la conexión `academia`. Se complementan.

---

## 6. Suite de Pruebas de Regresión

| ID de Prueba | Descripción | Prioridad | Automatizado |
|-------------|-------------|----------|-------------|
| TC-001 | Importar CSV con múltiples fechas y duplicados | P1 | Sí |
| TC-002 | Normalización de texto con acentos y Ñ | P1 | Sí |
| TC-006 | Cruce exacto automático | P1 | Sí |
| TC-009 | Confirmar match manual desde UI | P1 | Sí / Planificado |
| TC-021 | Rechazar CSV con columnas faltantes | P1 | Sí |
| TC-028 | Procesar CSV de 27,000 filas en < 50 s | P1 | Sí |

---

## 7. Matriz de Cobertura de Pruebas

| Requisito | Unidad | Integración | E2E | Rendimiento |
|-----------|--------|------------|-----|-------------|
| US-001/AC-001 |  | TC-001 |  |  |
| US-001/AC-001a |  | TC-014, TC-021, TC-052, TC-053 |  |  |
| US-001/AC-001b |  | TC-018, TC-022 |  |  |
| US-001/AC-001c |  | TC-025 |  |  |
| US-001/AC-001d |  | TC-027 |  |  |
| US-001/AC-001e |  | TC-033 |  |  |
| US-001/AC-001f |  |  |  | TC-028 |
| US-001/AC-002 | TC-002 |  |  |  |
| US-001/AC-003 | TC-003 |  |  |  |
| US-001/AC-004 |  | TC-004 |  |  |
| US-001/AsyncAPI |  | TC-050, TC-051 |  |  |
| US-002/AC-005 |  | TC-005 |  |  |
| US-002/AC-005a |  | TC-005 |  |  |
| US-002/AC-006 |  | TC-005 |  |  |
| US-002/AC-007 | TC-045 | TC-005 |  |  |
| US-003/AC-003a |  |  |  | TC-028 (cobertura transitiva via AC-001f) |
| US-003/AC-008 |  | TC-006 |  |  |
| US-003/AC-009 | TC-007 |  |  |  |
| US-003/AC-010 |  | TC-008, TC-015 |  |  |
| US-004/AC-011 |  |  | TC-009, TC-048 |  |
| US-004/AC-012 |  |  | TC-009 |  |
| US-004/AC-013 |  |  | TC-010, TC-057 |  |
| US-004/AC-004a |  |  |  | TC-029 |
| US-004/AC-004b |  | TC-026, TC-058 |  |  |
| US-005/AC-014 | TC-034, TC-036, TC-037, TC-038 | TC-011, TC-035 |  |  |
| US-005/AC-015 |  | **GAP — no dedicated TC** (TC-012 previously mismapped here; TC-012 covered AC-016, now removed) |  |  |
| ~~US-005/AC-016~~ | — | — | — | — **[Removed 2026-07-07 — AC-016 removed from spec.md, see TC-012]** |
| DA-G1 (2026-07-07, pendientes ordering) |  | TC-048, TC-059 |  |  |
| DA-G3 (2026-07-07, marcar_no_ingresado) |  | TC-057, TC-058 |  |  |
| EC-001 |  | TC-013 |  |  |
| EC-002 |  | TC-014 |  |  |
| EC-003 |  | TC-015 |  |  |
| EC-004 |  | TC-016 |  |  |
| EC-005 | TC-017 |  |  |  |
| EC-006 |  | TC-018 |  |  |
| EC-007 |  | TC-019 |  |  |
| EC-008 |  | TC-020 |  |  |
| ERR-001 |  | TC-014, TC-021 |  |  |
| ERR-002 |  | TC-022 |  |  |
| ERR-003 |  | TC-023 |  |  |
| ERR-004 |  | TC-024 |  |  |
| ERR-005 |  | TC-025 |  |  |
| ERR-006 |  | TC-026 |  |  |
| ERR-007 |  | TC-027 |  |  |
| NFR-001 |  |  |  | TC-028 |
| NFR-002 |  |  |  | TC-029 |
| NFR-003 |  |  |  | TC-030 |
| NFR-004 |  | TC-031 |  |  |
| NFR-005 |  | TC-032, TC-047 |  |  |
| NFR-006 |  | TC-033 |  |  |
| AD-001 (v2.9.0) | TC-056 | TC-005 |  |  |
| INV-01 | TC-039 |  |  |  |
| INV-02 |  | TC-040 |  |  |
| INV-03 |  | TC-042 |  |  |
| INV-04 | TC-043 |  |  |  |
| INV-05 | TC-044 |  |  |  |
| INV-06 | TC-045 | TC-005 |  |  |
| INV-07 |  | TC-041 |  |  |
| INV-08 |  | TC-046, TC-031 |  |  |

---

## 8. Plan de Ejecución de Pruebas

### 8.1 Pipeline de CI

| Etapa | Pruebas | Desencadenante |
|-------|---------|----------------|
| Pre-commit | Pruebas de Unidad | Gancho local |
| Revisión de PR | Unidad + Integración | Pull request abierto |
| Fusión | Suite completa | Fusión a main |
| Nocturna | E2E + Rendimiento | Programado |

### 8.2 Pruebas Manuales

| Caso | Cuándo | Evaluador |
|------|---------|-----------|
| Exploratoria de carga CSV | Antes de la liberación | QA |
| Validación de UI de cabos sueltos | Antes de la liberación | QA + Dev |

---

## 9. Aprobación

- [x] QA Lead: Diego Castillo y Yerson - Date: 2026-06-25
- [x] Dev Lead: Renzo Santos - Date: 2026-06-25
