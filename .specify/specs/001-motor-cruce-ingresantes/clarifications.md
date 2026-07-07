# Clarifications Log: Motor de Cruce Automático de Ingresantes UNMSM

**Feature ID:** 001-motor-cruce-ingresantes
**Sessions:** 2
**Status:** In Progress — 1 pregunta abierta (CQ-004)

---

## Summary

**Total Questions:** 4
**Resolved:** 3
**Pending:** 1 (CQ-004)

**Key Decisions:**
1. El filtro por OBSERVACION (`ALCANZO VACANTE`) se aplica siempre sobre el texto normalizado, enrutando a `ingresantes` o `no_ingresantes` (dual table).
2. De-duplicación automática de filas idénticas dentro del mismo CSV de origen para asegurar la calidad de la data analítica.
3. Ante fallo de conexión a `academia` durante el cruce, el lote se marca `paused` (recuperable); ante fallo catastrófico del job, se marca `error` (requiere intervención manual).

---

## Session 3: 2026-07-07 (Post-Implementation Gap Remediation)

**Participants:** Architect Agent, Reconciliation Agent
**Duration:** N/A (asynchronous audit)

### Questions Raised

#### CQ-004: Autenticación ausente en todos los endpoints `/api/cruce/*`

**Category:** Security / Architecture
**Route To:** PO + Security Owner
**Status:** OPEN — pendiente de decisión humana

**Question:**
El código auditado (`routes/api.php`) registra todos los endpoints `cruce` (`upload`, `lotes`, `status`, `pendientes`, `candidatos`, `confirmar` ×2, `exportar`, y los de utilidad `health`/`academia/alumnos`/`limpiar`/`reprocesar`) **sin ningún middleware de autenticación o autorización**, contradiciendo plan.md §4.1 ("Auth Required: Yes") y §5.1/§5.2 (Sanctum + matriz de roles admin/admisiones/marketing). Estos endpoints exponen y mutan PII (nombres, código de postulante, referencias a alumno) y permiten acciones destructivas (`limpiar` trunca toda la data de cruce; `reprocesar` re-ejecuta jobs).

¿Se debe implementar auth (`auth:sanctum` + roles admin/admisiones/marketing) en todos los endpoints `/api/cruce/*` ahora, diferirlo a un sprint posterior, o aceptar formalmente el riesgo por [razón a documentar por el PO/Security Owner]?

**Options Considered (plan.md DA-G5):**
1. **Opción A (recomendada):** Aplicar `auth:sanctum` + autorización por rol/ability al grupo de rutas `cruce` según la matriz de §5.2 (escritura: admin/admisiones; exportación: +marketing; destructivas `limpiar`/`reprocesar`: solo admin). Requiere que el SPA se autentique (Sanctum cookie/token).
2. **Opción B:** Aceptar el riesgo formalmente con una razón documentada, acotada en el tiempo, y controles compensatorios (ej. restricción a nivel de red), firmado por el PO/Security Owner.

**Decision:** **Sin resolver.** Requiere sign-off humano explícito antes de cerrarse en cualquier dirección — no se diseña ni se implementa una solución de auth sin esa decisión (Architect "Ask First" boundary).

**Decided By:** — (pendiente)
**Date:** — (pendiente)

---

## Session 2: 2026-06-25

**Participants:** Samuel Cisneros (PO), Renzo Santos (Tech Lead), Antigravity (Clarification Agent)
**Duration:** 10 min

### Questions Addressed

#### CQ-003: Estado del lote ante fallo de conexión a `academia` vs fallo catastrófico del job

**Category:** Business Logic / Error Handling
**Route To:** Tech Lead
**Status:** Resolved

**Question:**
Tres artefactos describían comportamientos distintos para el fallo durante el cruce:
- `EC-007` decía "pausar el lote".
- `ERR-003` decía "marcar lote como `error`".
- `TC-019` decía "error o pausado".

¿Cuál es el comportamiento canónico para cada tipo de fallo?

**Options Considered:**
1. **Opción A (Diferenciación semántica):** `paused` para fallos recuperables (conexión a `academia` caída); `error` para fallos catastróficos del job (excepción inesperada no capturada). El BatchStatus enum ya soporta ambos.
2. **Opción B (Estado único):** Todo fallo resulta en `error`, dejando la semántica de recuperabilidad al log.

**Decision:**
Se elige la **Opción A (Diferenciación semántica)**.

**Rationale:**
La distinción operativa es crítica: `paused` le indica al administrador que puede reintentar sin riesgo de duplicar datos; `error` le indica que requiere diagnóstico. Sin esta distinción, el operador no sabe si volver a encolar el job es seguro.

**Impact on Artifacts:**
- [x] spec.md: EC-007 → estado `paused` (conexión caída, recuperable); ERR-003 → estado `paused` (idem); ERR-007 → estado `error` (job catastrófico, requiere diagnóstico).
- [x] test-cases.md: TC-019 → verificar específicamente estado `paused`; TC-027 → verificar específicamente estado `error`.
- [x] plan.md §8.1: Alinear tabla de Error Categories con esta distinción.

**Decided By:** Renzo Santos, Tech Lead
**Date:** 2026-06-25

---

## Session 1: 2026-06-24

**Participants:** Samuel Cisneros (PO), Equipo V2, Antigravity (Clarification Agent)
**Duration:** 15 min

### Questions Addressed

#### CQ-001: Filtro de OBSERVACION: Normalizado vs Crudo

**Category:** Business Logic
**Route To:** PO
**Status:** Resolved

**Question:**
¿El filtro por `ALCANZO VACANTE` se debe aplicar sobre el valor normalizado (mayúsculas, sin tildes) o sobre el valor crudo original del CSV?

**Context:**
> El filtro de OBSERVACION (AC-004) se aplica después de la normalización del campo, no sobre el valor crudo. (NC-1)

**Options Considered:**
1. **Opción A (Filtrar sobre normalizado):** Robusto contra variaciones de tildes o mayúsculas/minúsculas en el CSV oficial.
2. **Opción B (Filtrar sobre crudo):** Más simple pero propenso a omitir registros si el formato del CSV varía ligeramente.

**Decision:**
El filtro se aplica **siempre sobre el valor normalizado**.

**Rationale:**
Evita errores de filtrado debido a inconsistencias de formato en la base de datos de origen de la UNMSM. Los registros que no cumplen el filtro se enrutan de forma dual a la tabla `no_ingresantes` para no perder trazabilidad.

**Impact on Artifacts:**
- [x] spec.md: US-001, AC-004 y Notas Técnicas.

**Decided By:** Samuel Cisneros, PO
**Date:** 2026-06-24

---

#### CQ-002: Manejo de Registros Duplicados en el CSV

**Category:** Business Logic
**Route To:** PO
**Status:** Resolved

**Question:**
Si el archivo CSV contiene registros idénticos duplicados (mismo postulante con la misma fecha de examen y misma observación), ¿el sistema debe de-duplicar e importar un solo registro en el lote, o debe importar todos manteniendo la duplicidad tal como viene en el CSV original?

**Context:**
> Dado un archivo CSV con múltiples fechas de examen, cuando se sube al sistema, entonces se divide en lotes independientes... y se ignoran silenciosamente las fechas que ya fueron procesadas previamente... (AC-001)

**Options Considered:**
1. **Opción A (De-duplicación automática):** El sistema detecta registros idénticos en el mismo CSV y solo importa uno de ellos para evitar duplicidad de registros en la base de datos analítica.
2. **Opción B (Preservar duplicidad):** El sistema importa cada fila tal cual viene en el archivo para mantener correspondencia exacta 1:1 con el documento oficial, dejando la resolución de anomalías para auditorías externas.

**Decision:**
Se elige la **Opción A (De-duplicación automática)**.

**Rationale:**
Evita la polución de datos duplicados en las tablas analíticas y asegura que las métricas y los conteos finales del lote representen personas únicas.

**Impact on Artifacts:**
- [x] spec.md: US-001, AC-001 y Notas Técnicas.

**Decided By:** Samuel Cisneros, PO
**Date:** 2026-06-24

---

## Pending Questions

These questions require further investigation or stakeholder input:

- **CQ-004** (Session 3, 2026-07-07): Auth ausente en todos los endpoints `/api/cruce/*` — requiere sign-off explícito del PO/Security Owner (implementar / diferir / aceptar riesgo formalmente). Ver plan.md DA-G5.

---

## Deferred Questions

No hay preguntas diferidas en esta sesión.

---

## Amendments to Specification

| Date | Artifact | Section | Change | CQ Reference |
|------|----------|---------|--------|--------------|
| 2026-06-24 | spec.md | US-001 | Modificación de AC-004 para reflejar la persistencia dual post-normalización. | CQ-001 |
| 2026-06-24 | spec.md | US-001 | Modificación de AC-001 para especificar la de-duplicación automática de filas idénticas en el lote. | CQ-002 |
| 2026-06-25 | spec.md | EC-007 | Estado del lote ante fallo de conexión a `academia` unificado a `paused`. | CQ-003 |
| 2026-06-25 | spec.md | ERR-003 | Estado del lote ante fallo catastrófico del job unificado a `error`. | CQ-003 |
| 2026-06-25 | test-cases.md | TC-019 | Verificación de estado `paused` específicamente (no ambiguo). | CQ-003 |
| 2026-06-25 | test-cases.md | TC-027 | Verificación de estado `error` específicamente. | CQ-003 |

---

## Sign-off

- [x] Product Owner: Samuel Cisneros - Business decisions validated
- [x] Dev Lead: Renzo Santos - Technical feasibility confirmed
- [x] QA Lead: Diego Castillo y Yerson - Technical feasibility confirmed
- [x] FA: Diego Castillo y Yerson - Requirements complete

**Clarification Phase Status:** Gate 1 Complete — 3 preguntas resueltas (2026-06-25). **Nota (2026-07-07):** CQ-004 fue añadida durante el pase de remediación de brechas post-implementación (Session 3); no reabre Gate 1, pero bloquea el cierre formal del gap de seguridad DA-G5 hasta que se resuelva.

