# Context Bridge: Motor de Cruce Automático de Ingresantes UNMSM

**Feature ID:** 001-motor-cruce-ingresantes
**Updated:** 2026-06-25
**Target Phase:** 2 — Design
**Ceremony Level:** standard

---

## Feature Goal

Automatizar la validación y emparejamiento de identidades de ingresantes UNMSM contra la base de datos de alumnos de la academia Vonex, procesando ~27,000 registros por lote de forma asíncrona (≤ 50 segundos), con resolución manual asistida de casos ambiguos, trazabilidad completa por fecha de examen y exportación de reportes CSV enriquecidos (compatibles con Excel).

---

## Post-Implementation Gap Remediation Pass (2026-07-07)

Tras la marca `Implemented`, una auditoría de dos agentes (Architect + Reconciliation) confirmó 6 brechas genuinas entre el código real y los artefactos, ahora resueltas a nivel de diseño en plan.md "Design Addendum" y propagadas a spec.md, tasks.md (T024–T029), test-cases.md y contracts/openapi.yaml. Invariantes clave reafirmados por esta auditoría:

- **Fuzzy match es EAGER**, no lazy: se computa dentro de `ProcessCsvBatchJob` inmediatamente después del match exacto, para todos los `pendiente` del lote. `GET /candidatos` es un SELECT puro. Cualquier referencia restante a cómputo "on-demand"/"primera vez que se abre la UI" es obsoleta (ver data-model.md §7.2, no corregida en este pase por estar fuera del alcance explícito de artefactos a actualizar).
- **Umbral de similitud canónico: 70.00%** — único valor de aceptación para persistir un candidato en `ingresante_candidatos`. El 80% es (o era) un filtro de *display* en la bandeja interactiva, ahora rediseñado como no-exclusionario (DA-G1); el 30% que aparecía en tasks.md T001 era un error, corregido a 70.00.
- **Conteo de tareas:** 23 tareas originales (T001–T023, excluyendo IDs no usados) + 6 tareas de remediación nuevas (T024–T029) = **29 tareas**, 155h estimadas totales. El resumen previo de tasks.md tenía una fila fantasma "Post-Implementation: 2 tasks" sin tareas reales asociadas y subestimaba la Fase 2 en 8h; ambos errores fueron corregidos.
- Dos brechas quedan **sin resolver en código** (solo diseñadas): DA-G3 (bug de corrupción de datos en "Mark as No Match") y DA-G5 (auth completamente ausente, flagged para sign-off humano vía CQ-004). Ver analysis-report.md Run 9.

---

## Completed Phases Summary

| Phase | Artifact | Status |
|---|---|---|
| Business Context | business-context.md | Complete |
| Clarifications | clarifications.md | 3 preguntas resueltas — Gate 1: Complete (2026-06-25) |
| Specification | spec.md v2.5.0 | Complete |
| Data Model | data-model.md | Complete |
| Solution Design | plan.md | Complete |
| API Contracts | openapi.yaml, asyncapi.yaml | Complete |
| Test Cases | test-cases.md | Draft complete |

---

## Bounded Contexts

### Context 1: CruceIngresantes (este sistema — owner)

**Responsabilidad:** Ingerir, normalizar, cruzar y persistir registros de postulantes UNMSM contra la base de matrículas de la academia, exponiendo una interfaz de resolución manual para casos ambiguos.

**Owns:**

- Tabla `lotes_cruce` — metadatos del lote y totales de auditoría
- Tabla `ingresantes` — postulantes que pasaron el filtro `ALCANZO VACANTE`
- Tabla `no_ingresantes` — postulantes que NO pasaron el filtro (solo auditoría)
- Toda la lógica de matching (exacto + difuso, computado EAGER dentro de `ProcessCsvBatchJob`)
- Generación de reportes CSV enriquecidos (compatibles con Excel; sin gráficos ni segunda hoja)

**No owns ni modifica:**

- Ninguna tabla de la base `academia`
- Registros de matrícula de alumnos
- Gestión de autenticación/sesión (delegada a la app Laravel principal)

---

### Context 2: Academia (externo — solo lectura)

**Responsabilidad:** Fuente de verdad de los registros de matrícula de alumnos. CruceIngresantes la consulta pero nunca escribe sobre ella.

**Método de integración:** Conexión secundaria PostgreSQL vía config de Laravel (`DB_ACADEMIA_*` env vars).

**Contrato mínimo esperado del schema de academia:**

El schema real de la base `academia` usa claves primarias varchar y nombres de tablas en plural. Las relaciones entre tablas son:

```
alumno_matricula.alumno_codigo → alumnos.codigo
alumnos.persona_dni → personas.dni
alumno_matricula.padre_id → padres.id
padres.persona_dni → personas.dni
alumno_matricula.aula_id → aulas.id
aulas.matricula_id → matriculas.id
matriculas.id → ciclos.matricula_id
```

### Tabla: `personas`

| Campo | Tipo | PK | Notas |
|---|---|---|---|
| `dni` | VARCHAR | PK | DNI de la persona |
| `nombres` | VARCHAR | | Nombres — se normaliza antes de comparar |
| `apellido_paterno` | VARCHAR | | Apellido paterno (separado) |
| `apellido_materno` | VARCHAR | | Apellido materno (separado) |
| `telefono` | VARCHAR | | Celular o teléfono de contacto |

### Tabla: `alumnos`

| Campo | Tipo | PK/FK | Notas |
|---|---|---|---|
| `codigo` | VARCHAR | PK | Código interno del alumno |
| `persona_dni` | VARCHAR | FK → personas.dni | DNI de la persona |
| `email` | VARCHAR | | Email del alumno |

### Tabla: `padres`

| Campo | Tipo | PK/FK | Notas |
|---|---|---|---|
| `id` | BIGINT | PK | ID autoincremental del padre/apoderado |
| `persona_dni` | VARCHAR | FK → personas.dni | DNI del padre en la tabla personas |

### Tabla: `alumno_matricula`

| Campo | Tipo | PK/FK | Notas |
|---|---|---|---|
| `id` | BIGINT | PK | ID autoincremental |
| `alumno_codigo` | VARCHAR | FK → alumnos.codigo | Código del alumno |
| `padre_id` | BIGINT | FK → padres.id (NULLABLE) | ID del padre/apoderado relacionado |
| `aula_id` | BIGINT | FK → aulas.id | Aula asignada |
| `estado` | SMALLINT | | 2=MATRICULADO, 3=PAGADO, 9=SUSPENDIDO, 13=STAND BY |
| `estado_aula` | SMALLINT | | 1 = aula activa |
| `fecha` | TIMESTAMP | | Fecha de matrícula |
| `matricularegular_id` | BIGINT | NULLABLE | Si tiene valor, es un duplicado regular |

### Tablas auxiliares

| Tabla | Campos clave |
|---|---|
| `aulas` | `id`, `matricula_id`, `hora_inicio`, `codigo_aula` |
| `matriculas` | `id` |
| `ciclos` | `id`, `matricula_id`, `fecha_inicio`, `fecha_fin` |


### Filtros para alumnos activos (usados en el matching)

```sql
WHERE alumno_matricula.estado IN (0, 2, 3, 9, 13, 14)   -- RETIRADO, MATRICULADO, PAGADO, SUSPENDIDO, STAND BY, FINALIZADO
  AND alumno_matricula.estado_aula = 1            -- aula activa
  AND EXISTS (SELECT 1 FROM ciclos                -- ciclo activo
              WHERE ciclos.matricula_id = matriculas.id
              AND ciclos.fecha_fin >= CURRENT_DATE)
  AND alumno_matricula.id NOT IN (                -- excluir duplicados regulares
      SELECT matricularegular_id FROM alumno_matricula
      WHERE matricularegular_id IS NOT NULL
  )
```

> **Corrección (2026-07-07, decisión PO — tasks.md T039):** el filtro se amplió para incluir RETIRADO (0) como candidato válido de cruce, resolviendo el límite de alcance detectado en T038 (un registro RETIRADO nunca entraba al pool antes de que la deduplicación por recencia pudiera actuar sobre él). ANULADO (11) y TRASLADADO (12) permanecen excluidos — decisión deliberada y acotada del PO.

### Jerarquía de estados (INV-06 actualizado)

El campo `alumno_matricula.estado` es numérico. En la base de datos real de `academia` existen los siguientes valores numéricos:

| Valor | Estado | Prioridad en Jerarquía |
|---|---|---|
| 2 | MATRICULADO | 1 (más alto) |
| 3 | PAGADO | 2 |
| 14 | FINALIZADO | 3 |
| 9 | SUSPENDIDO | 4 |
| 0 | RETIRADO | 5 |
| 12 | TRASLADADO | 6 |
| 13 | STAND BY | 7 |
| 11 | ANULADO | 8 (más bajo) |

*Nota:* Los valores `1` (PENDIENTE) y `4` (PRE-INSCRITO) también existen en la base de datos, pero no participan en esta jerarquía de resolución de estados para el cruce.

Para la extracción inicial de la base de datos de Academia, el motor aplica un filtro de estados activos: `estado IN (0, 2, 3, 9, 13, 14)` (RETIRADO, MATRICULADO, PAGADO, SUSPENDIDO, STAND BY, FINALIZADO — ampliado 2026-07-07 por decisión PO, tasks.md T039, para incluir RETIRADO; ANULADO(11)/TRASLADADO(12) permanecen excluidos), según se detalla en el filtro de la query. Sin embargo, al resolver alumnos con múltiples registros históricos en la base de datos, se debe utilizar la jerarquía completa descrita arriba.

**Anti-Corruption Layer:** La normalización (`NormalizarTextoAction`) se aplica a los datos de Academia antes de cualquier comparación. El dominio nunca almacena strings crudos de Academia — solo formas normalizadas.

**Riesgo de integración:** Si el schema de Academia cambia (renombran columnas, agregan restricciones), este sistema falla en silencio durante el cruce. Mitigación: validar la conexión y ejecutar una query de smoke test al inicio de cada job (AC-005).

---

## Ubiquitous Language Map

Tabla autoritativa de traducción entre lenguaje de negocio (reuniones, requisitos, user stories) y conceptos técnicos (código, base de datos, API).

| Término de Negocio | Concepto Técnico | Ubicación |
|---|---|---|
| Ingresante | Postulante cuya `OBSERVACION` normalizada es exactamente `ALCANZO VACANTE` | Tabla `ingresantes`, model `Ingresante` |
| No ingresante | Postulante que NO cumplió el filtro de OBSERVACION | Tabla `no_ingresantes` |
| Lote | Conjunto de registros del CSV agrupados por una misma `FECHA_EXAMEN` | Tabla `lotes_cruce`, model `LoteCruce` |
| Fecha de examen | Fecha que identifica y agrupa un lote | `lotes_cruce.fecha_examen` (DATE, UNIQUE) |
| Cabo suelto | Ingresante sin match exacto, con similitud ≥ 70% con al menos un alumno | `ingresantes.estado_match = 'pendiente'` |
| Match exacto | Coincidencia de 2 apellidos + 1 nombre post-normalización contra un alumno de academia | `estado_match = 'confirmado_automatico'` |
| Validación asistida | Resolución manual del administrador desde la UI React | `estado_match = 'confirmado_manual'` |
| No ingresado | Postulante descartado explícitamente por el administrador (sin alumno asociado) | `estado_match = 'no_ingresado'` |
| Normalización | Conversión a MAYÚSCULAS + eliminación de tildes + Ñ→N | `NormalizarTextoAction` |
| OBSERVACION | Columna del CSV usada para filtrar ingresantes vs no-ingresantes | `ingresantes.observacion` (almacenado normalizado) |
| Jerarquía de estados | Orden de prioridad inmutable para resolver un alumno con múltiples registros históricos | Array de prioridad en la lógica de resolución (ver INV-06) |

---

## Business Invariants

Reglas que el diseño técnico DEBE preservar. Cualquier implementación que las viole es un defecto, no un trade-off.

| ID | Invariante | Expresión técnica |
|---|---|---|
| INV-01 | Un ingresante nunca se auto-confirma sin match exacto de 2 apellidos + 1 nombre (post-normalización) | El estado `confirmado_automatico` solo puede ser escrito por `RealizarCruceExactoAction`; ningún otro path de código puede asignarlo |
| INV-02 | `no_ingresantes` es append-only y nunca se elimina | No existen operaciones DELETE ni UPDATE sobre esa tabla |
| INV-03 | Una `fecha_examen` se procesa exactamente una vez — re-subir el mismo CSV es idempotente | Forzado por constraint UNIQUE en `lotes_cruce.fecha_examen` |
| INV-04 | Las filas idénticas dentro del mismo CSV se de-duplican antes de persistir | La de-duplicación ocurre en `ProcesarCargaCsvAction` ANTES de cualquier INSERT |
| INV-05 | El filtro de OBSERVACION se aplica SOLO sobre el valor normalizado, nunca sobre el string crudo del CSV | La normalización precede al filtrado en el pipeline del job |
| INV-06 | La jerarquía de estados de alumno es fija e inmutable. El orden de prioridad es: MATRICULADO (2) > PAGADO (3) > FINALIZADO (14) > SUSPENDIDO (9) > RETIRADO (0) > TRASLADADO (12) > STAND BY (13) > ANULADO (11). | Todo código que resuelva alumni con múltiples registros debe usar este orden exacto |
> **Corrección (2026-07-07, verificación PO con datos de producción real):** la jerarquía anterior es INCOMPLETA como única regla de resolución para registros duplicados de un mismo alumno. Un caso real de producción mostró un alumno actualmente RETIRADO (0) resuelto/exportado como PAGADO (3), porque un registro `alumno_matricula` antiguo (2022) con estado PAGADO ganaba por jerarquía sobre el registro real y vigente (RETIRADO), sin considerar cuál es más reciente. **Nueva regla (supersede la lectura solo-jerarquía implementada en T036):** cuando una persona tiene más de un registro `alumno_matricula`, primero se debe identificar el registro MÁS RECIENTE (por `alumno_matricula.fecha`); la jerarquía INV-06 de arriba se usa ÚNICAMENTE como desempate cuando dos o más registros comparten la misma fecha más reciente (o cuando ninguno tiene fecha utilizable). Ver `ResolverEstadoHierarchy` (app/Actions/Cruce/ResolverEstadoHierarchy.php) y tasks.md T038.
| INV-07 | La base `academia` es estrictamente de solo lectura para este sistema | Cero operaciones INSERT, UPDATE o DELETE sobre la conexión `academia` |
| INV-08 | Las credenciales de `academia` nunca se hardcodean | La configuración de conexión se toma exclusivamente de variables de entorno `DB_ACADEMIA_*` |

> **Invariante añadida (2026-07-07, DA-G3):** `ingresantes.alumno_id` debe ser `NULL` cuando `estado_match ∈ {pendiente, no_ingresado}` y `NOT NULL` (referencia válida) cuando `estado_match ∈ {confirmado_automatico, confirmado_manual}`. El valor `0` nunca es válido. Ver data-model.md §4, §10 y plan.md DA-G3 — esta invariante está **diseñada pero aún no forzada en código**: `CruceIngresantesController::confirmar` no reenvía `marcar_no_ingresado`, por lo que hoy puede persistirse `alumno_id = 0` (bug de corrupción de datos, fix en tasks.md T026).

---

## Key Constraints

| Constraint | Fuente | Impacto en diseño |
|---|---|---|
| SLA de procesamiento: ≤ 50s para ~27,000 filas | NFR-001 | El job usa bulk inserts y evita N+1 queries durante la normalización |
| Respuesta de candidatos: ≤ 300ms p95 | NFR-002 | El endpoint `/candidatos` resuelve contra resultados pre-computados o indexados; no hace full-table scan en tiempo real |
| Tamaño de archivo: hasta 20 MB | NFR-003 | El layer HTTP solo recibe el archivo; todo el procesamiento ocurre en el worker de cola |
| Procesamiento asíncrono vía Redis | NFR-006 | `QUEUE_CONNECTION=redis` es requerido; el procesamiento síncrono HTTP del CSV está prohibido |
| PHP strict types (8.4+) | constitution.md Art. II | Todos los archivos PHP declaran `strict_types=1` |
| Sin SQL directo en controladores | constitution.md Art. VII §7.3 | Todas las queries van por Eloquent o DB query builder |
| Credenciales solo en `.env` | constitution.md Art. VII §7.3 | Aplica tanto a la BD Vonex como a la BD Academia |
| **Contrato API autoritativo** | contracts/openapi.yaml | Todo path de endpoint definido en `openapi.yaml` es la fuente de verdad; referencias de paths en `spec.md` y `plan.md` son informativas y deben mantenerse en sincronía con el YAML. |

---

## Phase Transition Notes

**De Fase 1 (Business + Clarifications) → Fase 2 (Design):**

Tres decisiones de clarificación (ver `clarifications.md`) impactan materialmente el data model y la pipeline:

1. **CQ-001 — Filtro sobre valor normalizado:** El filtro `ALCANZO VACANTE` corre después de la normalización. Las columnas `observacion` en `ingresantes` y `no_ingresantes` almacenan el valor NORMALIZADO, no el original del CSV.

2. **CQ-002 — De-duplicación automática:** Las filas idénticas dentro del mismo CSV se eliminan antes de persistir. La clave de de-duplicación es el contenido completo de la fila (todos los campos), no solo el código del postulante.

3. **CQ-003 — Semántica de estado de lote ante fallos:** Fallo de conexión a `academia` → `paused` (recuperable, reintentable sin riesgo de duplicados). Fallo catastrófico del job → `error` (requiere diagnóstico). Esta distinción impacta `ProcessCsvBatchJob`, `plan.md §8.1` y los test cases TC-019 y TC-027.
