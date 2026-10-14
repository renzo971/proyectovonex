# Ship Checklist: Motor de Cruce Automático de Ingresantes UNMSM (Feature 001 — Full Review)

**Feature ID:** 001-motor-cruce-ingresantes
**Review Date:** 2026-07-08
**Reviewer:** Review Agent (Phase 5 — Quality Assurance)
**Branch:** feat-implementacion-proyecto
**Release Version:** v3.1.0 (feature-complete review)
**Complejidad:** High (5 user stories, 4 fases, ~40 archivos de producción + frontend React + BD dual) → dos pasadas ordenadas (Pass 1 gate → Pass 2).

> **Nota de método:** Cada hallazgo de este review fue verificado leyendo el código fuente
> real (`routes/api.php`, `CruceIngresantesController.php`, `RealizarCruceExactoAction.php`,
> `CalcularSimilitudesCabosAction.php`, `tests/`), NO solo los artefactos SDD. Confianza: **HIGH**.

---

## 0. Contexto — Estado previo

El `analysis-report.md` **Run 9 (2026-07-07)** dictó **FAIL** con 2 defectos CRÍTICOS (C-01
data corruption, C-02 auth ausente) + 4 warnings (W-01…W-06). Después de ese análisis se
mergearon commits de fix (`T024`, `T026`, `T030`). Este review re-verifica el estado REAL
del código para determinar qué se cerró y qué sigue abierto.

### Delta vs Run 9 (verificado en código)

| Gap (Run 9) | Tarea | Estado en código HOY | Evidencia |
|---|---|---|---|
| C-01 / DA-G3 — `marcar_no_ingresado` no se leía (corrupción `alumno_id=0`) | T026 | ✅ **RESUELTO** | `CruceIngresantesController.php:212` lee `marcar_no_ingresado`; valida `alumno_id` solo si no es no-ingresado; pasa `null` correcto |
| W-01 / DA-G1 — `pendientes()` excluía filas y ordenaba mal | T024 | ✅ **RESUELTO** | `CruceIngresantesController.php:294-307` sin exclusión por umbral; orden `candidatos_count DESC, max_similitud DESC, apellido...` |
| Export crash con listas grandes de IDs | T030 | ✅ **RESUELTO** | `pendientes()` batch-load con `buildPgArrayLiteral`; export usa eager `loadAcademiaDataFor` |
| C-02 / DA-G5 — auth ausente en `/api/cruce/*` | CQ-004 | ❌ **ABIERTO — CRÍTICO** | `routes/api.php:12-22` — cero middleware en 7 rutas de cruce |
| W-04 / DA-G6 — anti-patterns de test en código de producción | T029 | ❌ **ABIERTO** | `CalcularSimilitudesCabosAction.php:186`; `RealizarCruceExactoAction.php:31-38` |
| W-05 — rutas de utilidad no registradas | T028 | ❌ **ABIERTO** | `routes/api.php` no registra `health`/`academiaAlumnos`/`limpiar`/`reprocesar` (los métodos existen) |

---

## 1. Pass 1 — Spec Compliance

> **Gate rule:** Si ALGÚN AC falla, se detiene y no se ejecuta Pass 2.

### 1.1 Verificación de Acceptance Criteria (AC ↔ Código)

| AC | Requisito | Pass/Fail | Evidencia |
|----|-----------|-----------|-----------|
| AC-001 | Split por fecha + dedup + skip fechas procesadas | ✅ PASS | `ProcesarCargaCsvAction` + constraint UNIQUE `lotes_cruce.fecha_examen` (INV-03) |
| AC-001a | Validación de 12 columnas exactas | ✅ PASS | `ProcesarCargaCsvActionTest` (fixtures `missing-columns.csv`, `wrong-columns.csv`) |
| AC-001c | Rechazo >20MB con HTTP 413 | ✅ PASS | `CruceIngresantesController.php:32-37` |
| AC-001d | Job falla → `error`, sin duplicados | ⚠️ PARCIAL | Estado `error` cubierto; test de no-duplicación depende del anti-pattern DA-G6 |
| AC-002 | Normalización (MAYÚS + tildes + Ñ→N) | ✅ PASS | `NormalizarTextoActionTest` (107 líneas) |
| AC-003 | Split apellidos compuestos (DE LA CRUZ) | ✅ PASS | `NormalizarTextoAction` — prefijos DE LA/DEL/DE LOS/SAN |
| AC-004 | Filtro post-normalización → dual table | ✅ PASS | INV-05; `ProcesarCargaCsvAction` normaliza antes de filtrar |
| AC-005 | Valida conexión academia antes de query | ✅ PASS | `ConexionAcademiaTest` |
| AC-006 | Filtro estados `IN (0,2,3,9,13,14)` + estado_aula + ciclo | ✅ PASS | `RealizarCruceExactoAction.php:21` `ESTADOS_ACTIVOS` |
| AC-007 | Jerarquía de estados INV-06 + recency (T038) | ✅ PASS | `ResolverEstadoHierarchy` + `ResolverEstadoHierarchyTest` (242 líneas) |
| AC-008 | Match exacto 2 apellidos + 1 nombre → `confirmado_automatico` | ✅ PASS | `RealizarCruceExactoAction`; INV-01 forzado en `Ingresante::saving()` |
| AC-009 | Fuzzy ≥70% + top 5; pendientes no-exclusionario | ⚠️ **CONDICIONAL** | Lógica correcta PERO umbral real (70%) NO es el testeado (55% — DA-G6) |
| AC-010 | Sin candidatos → opción "No Ingresado", igual aparece en pendientes | ✅ PASS | `pendientes()` incluye filas sin candidatos, ordenadas al final |
| AC-011 | UI React fila + selector candidatos ordenados | ✅ PASS | `resources/js/components/UnmatchedRow.jsx` |
| AC-012 | Confirmar match → `confirmado_manual` | ✅ PASS | `GuardarCruceConfirmadoActionTest` (413 líneas) |
| AC-013 | "No Ingresado" → estado `no_ingresado`, `alumno_id=NULL` | ✅ PASS | `confirmar()` + T026 fix verificado |
| AC-004b | `alumno_id` inexistente → HTTP 404 | ✅ PASS | `GuardarCruceConfirmadoAction` retorna `http_status` |
| AC-014 | Export CSV `;` + BOM UTF-8, 24 columnas | ✅ PASS | `exportar()` + `ExportarExcelCruceActionTest` (16 tests) |
| AC-015 | Export incluye `confirmado_automatico` + `confirmado_manual` | ⚠️ **COVERAGE GAP** | Comportamiento correcto en código, sin TC dedicado (W-06 Run 9) |
| ~~AC-016~~ | (removido por PO — sin Hoja 2 / gráficos) | N/A | Confirmado removido v3.1.0 |

### 1.2 NFR

| NFR | Requisito | Estado | Evidencia |
|-----|-----------|--------|-----------|
| NFR-001 | Lote ~27k filas ≤ 50s | ✅ PASS | `CsvProcessingPerformanceTest` (T021) |
| NFR-002 | `/candidatos` p95 < 300ms | ✅ PASS | `FuzzyMatchPerformanceTest` (T021) |
| NFR-004 | Credenciales solo en `.env` | ✅ PASS | `DB_ACADEMIA_*` env vars; sin hardcode (INV-08) |
| NFR-005 | Trazabilidad de totales del lote | ✅ PASS | `lotes_cruce` con totales de auditoría |
| NFR-006 | Procesamiento async Redis + failed_jobs | ✅ PASS | `ProcessCsvBatchJob` + `QUEUE_CONNECTION=redis` |

### 1.3 Boundary / Security-critical AC

| AC/Concern | Estado | Evidencia |
|---|---|---|
| **Seguridad de endpoints (plan.md §4.1/§5.2)** | ❌ **FAIL** | `routes/api.php` — CERO auth en todas las rutas `/api/cruce/*` |

### 1.4 Test Coverage

- Suite completa: **81/81 passing**, 296 assertions (`php vendor/bin/pest --no-coverage`, 2.8s)
- `tests/Feature/` **SÍ contiene tests reales** (`CruceIngresantesPendientesTest`,
  `CruceIngresantesExportarTest`) — la observación de Run 9 (solo ExampleTest) está superada.
- ⚠️ **El verde de la suite NO prueba el comportamiento de producción del fuzzy match**:
  los tests corren con umbral **55%** (`runningUnitTests() ? 55 : 70`), no con el **70%** real.

---

## Pass 1 — VEREDICTO: ❌ FAIL

**Razón del gate:** Existe un fallo de cumplimiento de nivel arquitectura/seguridad
(ausencia total de autenticación en endpoints que exponen PII y permiten acciones
destructivas — contradice plan.md §4.1/§5.2). Adicionalmente, AC-009 no puede certificarse
como cumplido porque los tests validan un umbral distinto (55%) al de producción (70%).

> Por la regla de gate del agente Review, con un fallo de este nivel **NO se procede a Pass 2
> (Code Quality) como certificación de ship**. Aun así, documento abajo los hallazgos de
> calidad ya detectados durante la verificación de código, por transparencia y para acelerar
> la remediación — pero NO constituyen aprobación.

---

## 2. Hallazgos de Code Quality (informativos — no certificación)

### 2.1 CRÍTICO — Seguridad (C-02 / DA-G5 / CQ-004)

**Severidad:** Critical · **Confianza:** HIGH · **Bloquea ship**

`routes/api.php` registra las 7 rutas `/api/cruce/*` **sin ningún middleware de auth**.
Solo `/user` (no usado por el feature) tiene `auth:sanctum`.

Riesgo concreto:
- `POST /cruce/upload` — cualquiera puede inyectar lotes.
- `GET /cruce/lotes/{id}/pendientes` y `/candidatos` — **exponen PII** (nombres, apellidos, DNI, código de postulante) sin autenticación.
- `GET /cruce/lotes/{id}/exportar` — descarga masiva de PII sin auth.
- Los métodos `limpiar()` (`TRUNCATE` de toda la data de cruce, línea 419) y `reprocesar()` existen; si sus rutas se registran (T028) sin auth, quedan expuestos también.

**Decisión requerida:** CQ-004 está **OPEN**. Es una decisión humana (PO + Security Owner).
No debe implementarse ni ignorarse por defecto. Opciones (plan.md DA-G5):
- **A (recomendada):** `auth:sanctum` + gates por rol en el grupo de rutas `cruce`.
- **B:** Aceptar el riesgo formalmente, documentado, acotado en tiempo, con controles compensatorios y firma.

### 2.2 ALTO — Anti-patterns de test en código de producción (W-04 / DA-G6 / T029)

**Severidad:** High · **Confianza:** HIGH · **Bloquea aprobación de calidad**

Dos violaciones de `anti-patterns.instructions.md` (Rule 3 / integridad de test) — código de
producción que se comporta distinto bajo test:

1. `CalcularSimilitudesCabosAction.php:186`
   ```php
   $threshold = app()->runningUnitTests() ? 55.0 : 70.0;
   ```
   El umbral canónico es 70% (context-bridge INV, AC-009). Bajar a 55% en test hace que la
   suite valide un comportamiento que **nunca ocurre en producción**. Los tests fuzzy verdes
   no garantizan el corte real.

2. `RealizarCruceExactoAction.php:31-38`
   ```php
   if (app()->runningUnitTests()) {
       $trace = debug_backtrace(...);
       foreach ($trace as $step) {
           if (str_contains($step['function'], 'tc004_handles_database_connection_failure')) { ... }
       }
   }
   ```
   El código de producción **sniffea el nombre del método de test** para simular un fallo de
   conexión. Es lógica que solo existe para engañar a un test específico.

**Fix (T029):** inyectar el umbral por constructor/config; simular el fallo de conexión con
una conexión fake ligada al test (no con `debug_backtrace`).

### 2.3 BAJO — Rutas de utilidad no registradas (W-05 / T028)

Los métodos `health`, `academiaAlumnos`, `limpiar`, `reprocesar` están implementados en el
controller pero sus rutas no están en `routes/api.php` → código muerto/inalcanzable. Trivial
(1h). **Precaución:** al registrarlos, `limpiar`/`reprocesar` DEBEN ir detrás de auth (bloqueado por CQ-004).

### 2.4 BAJO — Ruta `confirmar` duplicada (S-01 Run 9)

`routes/api.php:19-20` registra `POST /cruce/ingresantes/{id}/confirmar` y
`POST /cruce/{id}/confirmar`, ambas a `confirmar()`. Limpiar o documentar la intención.

### 2.5 Aspectos positivos verificados

- `declare(strict_types=1)` presente en todos los archivos de producción revisados.
- Sanitización anti-inyección de fórmulas CSV en `exportar()` (líneas 399-405) — buena práctica de seguridad.
- INV-01 forzado en `Ingresante::saving()` (auto-confirmación bloqueada salvo flag interno).
- Eager loading correcto en `pendientes()` — sin N+1 sobre academia.
- Manejo defensivo del export: `loadAcademiaDataFor` eager ANTES del stream para evitar body corrupto tras headers 200.

---

## 3. Coverage / Documentación

- [x] `test-cases.md` sincronizado con la suite (81 tests).
- [ ] AC-015 sin TC dedicado (coverage gap heredado, W-06).
- [x] OpenAPI documenta 11 paths; **advertencia:** documenta auth Cookie/Bearer que el código NO aplica (divergencia contract↔código, ligada a CQ-004).

---

## 4. Ship Decision

**VEREDICTO: ❌ DO NOT SHIP (CHANGES REQUIRED)**

**Racional:** El motor de cruce es funcionalmente sólido y la mayoría de ACs/NFRs se cumplen
(dual-table, eager fuzzy, recency INV-06, export CSV 24 cols, performance dentro de SLA). Sin
embargo hay **un bloqueante de seguridad crítico** (auth totalmente ausente en endpoints con
PII y acciones destructivas, CQ-004 sin resolver) y **anti-patterns de test que invalidan la
confianza en el verde de la suite** para el path fuzzy. Ninguno es aceptable para producción.

### Condiciones de salida (orden sugerido)

1. **[HUMANO — bloqueante] Resolver CQ-004.** PO/Security Owner decide A (implementar auth) o B (aceptar riesgo formal firmado). Ver §2.1.
2. **[P0] Implementar la decisión de CQ-004.** Si Opción A: `auth:sanctum` + gates de rol en el grupo `cruce`, con `limpiar`/`reprocesar` restringidas a admin.
3. **[P1 — T029] Eliminar los dos anti-patterns de test** (§2.2) y re-verificar que la suite pasa con el umbral real de 70%.
4. **[P3 — T028] Registrar las rutas de utilidad** (detrás de auth) y limpiar la ruta `confirmar` duplicada.
5. Añadir TC dedicado para AC-015.
6. Re-ejecutar este review tras (1)-(3).

---

## 5. Reviewer Focus (atención humana crítica)

| # | Ubicación | Hallazgo | Confianza | Acción |
|---|-----------|----------|-----------|--------|
| 1 | `routes/api.php:12-22` | Auth ausente en todos los endpoints de cruce (PII + destructivos) | HIGH | **Decisión CQ-004 — PO/Security** |
| 2 | `CalcularSimilitudesCabosAction.php:186` | Umbral 55% en test vs 70% prod — el verde no valida producción | HIGH | Fix T029 |
| 3 | `RealizarCruceExactoAction.php:31-38` | `debug_backtrace` sniff del nombre del test en código de prod | HIGH | Fix T029 |
| 4 | `routes/api.php` | 4 métodos de utilidad sin ruta; `limpiar` = TRUNCATE total | MEDIUM | T028 (con auth) |
| 5 | `openapi.yaml` | Documenta auth que el código no aplica | MEDIUM | Sincronizar tras CQ-004 |

---

## 6. Sign-off

- [ ] Todos los issues críticos resueltos: ❌ (C-02/CQ-004 abierto)
- [ ] Anti-patterns de test eliminados: ❌ (DA-G6/T029 abierto)
- [ ] Cobertura aceptable: ⚠️ (81/81 verde, pero AC-009 no valida umbral real; AC-015 sin TC)
- [ ] Security review: ❌ **No apto** — ver §2.1

**Review Status:** CHANGES REQUIRED — no archivar ni mergear a producción hasta resolver CQ-004 y T029.

**Reviewer:** Review Agent (Phase 5)
**Date:** 2026-07-08
