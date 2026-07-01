# Context Bridge: Motor de Cruce Automático de Ingresantes UNMSM

**Feature ID:** 001-motor-cruce-ingresantes
**Updated:** 2026-06-25
**Target Phase:** 2 — Design
**Ceremony Level:** standard

---

## Feature Goal

Automatizar la validación y emparejamiento de identidades de ingresantes UNMSM contra la base de datos de alumnos de la academia Vonex, procesando ~27,000 registros por lote de forma asíncrona (≤ 50 segundos), con resolución manual asistida de casos ambiguos, trazabilidad completa por fecha de examen y exportación de reportes analíticos en Excel.

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
- Toda la lógica de matching (exacto + difuso)
- Generación de reportes Excel

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
alumno_matricula.aula_id → aulas.id
aulas.matricula_id → matriculas.id
matriculas.id → ciclos.matricula_id
```

### Tabla: `personas`

| Campo | Tipo | PK | Notas |
|---|---|---|---|
| `dni` | VARCHAR | PK | DNI del alumno |
| `nombres` | VARCHAR | | Nombres — se normaliza antes de comparar |
| `apellido_paterno` | VARCHAR | | Apellido paterno (separado) |
| `apellido_materno` | VARCHAR | | Apellido materno (separado) |
| `telefono` | VARCHAR | | Celular del alumno |

### Tabla: `alumnos`

| Campo | Tipo | PK/FK | Notas |
|---|---|---|---|
| `codigo` | VARCHAR | PK | Código interno del alumno |
| `persona_dni` | VARCHAR | FK → personas.dni | DNI de la persona |
| `email` | VARCHAR | | Email del alumno |

### Tabla: `alumno_matricula`

| Campo | Tipo | PK/FK | Notas |
|---|---|---|---|
| `id` | BIGINT | PK | ID autoincremental |
| `alumno_codigo` | VARCHAR | FK → alumnos.codigo | Código del alumno |
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
WHERE alumno_matricula.estado IN (2, 3, 9, 13)   -- MATRICULADO, PAGADO, SUSPENDIDO, STAND BY
  AND alumno_matricula.estado_aula = 1            -- aula activa
  AND EXISTS (SELECT 1 FROM ciclos                -- ciclo activo
              WHERE ciclos.matricula_id = matriculas.id
              AND ciclos.fecha_fin >= CURRENT_DATE)
  AND alumno_matricula.id NOT IN (                -- excluir duplicados regulares
      SELECT matricularegular_id FROM alumno_matricula
      WHERE matricularegular_id IS NOT NULL
  )
```

### Jerarquía de estados (INV-06 actualizado)

El campo `alumno_matricula.estado` es numérico. La jerarquía se mapea como:

| Valor | Estado | Prioridad |
|---|---|---|
| 2 | MATRICULADO | 1 (más alto) |
| 3 | PAGADO | 2 |
| 9 | SUSPENDIDO | 3 |
| 13 | STAND BY | 4 (más bajo) |

Los estados FINALIZADO, RETIRADO, TRASLADADO y ANULADO no existen en esta base como estados activos de `alumno_matricula.estado`.

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
| Cabo suelto | Ingresante sin match exacto, con similitud ≥ 30% con al menos un alumno | `ingresantes.estado_match = 'pendiente'` |
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
| INV-06 | La jerarquía de estados de alumno es fija e inmutable. En el schema real de academia los estados son numéricos: 2 (MATRICULADO) > 3 (PAGADO) > 9 (SUSPENDIDO) > 13 (STAND BY). Los estados FINALIZADO, RETIRADO, TRASLADADO y ANULADO no existen como valores activos en `alumno_matricula.estado`. | Todo código que resuelva alumni con múltiples registros debe usar este orden exacto por valor numérico |
| INV-07 | La base `academia` es estrictamente de solo lectura para este sistema | Cero operaciones INSERT, UPDATE o DELETE sobre la conexión `academia` |
| INV-08 | Las credenciales de `academia` nunca se hardcodean | La configuración de conexión se toma exclusivamente de variables de entorno `DB_ACADEMIA_*` |

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
