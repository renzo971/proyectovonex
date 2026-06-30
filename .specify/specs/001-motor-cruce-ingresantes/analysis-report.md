# Analysis Report — 001-motor-cruce-ingresantes
**Date:** 2026-06-30
**Run:** 5 (definitive)
**Verdict:** PASS

---

## 1. Artifact Inventory

| Artifact | Path | Status | Version / Notes |
|---|---|---|---|
| context-bridge.md | `.specify/specs/001-motor-cruce-ingresantes/context-bridge.md` | Present | Updated 2026-06-25; 8 business invariants, bounded contexts, ubiquitous language map |
| spec.md | `.specify/specs/001-motor-cruce-ingresantes/spec.md` | Present | v2.7.0 — US-001–US-005, AC-001–AC-015, NFR-001–NFR-006, EC-001–EC-008, ERR-001–ERR-007 |
| plan.md | `.specify/specs/001-motor-cruce-ingresantes/plan.md` | Present | Architecture, 7 endpoints in §4.1, §12 Issue #1 resolved |
| test-cases.md | `.specify/specs/001-motor-cruce-ingresantes/test-cases.md` | Present | TC-001–TC-051 (non-contiguous numbering); coverage matrix complete |
| tasks.md | `.specify/specs/001-motor-cruce-ingresantes/tasks.md` | Present | T001–T021 incl. T019/T020/T021 [T] test tasks; Mermaid DAG present |
| data-model.md | `.specify/specs/001-motor-cruce-ingresantes/data-model.md` | Present | 4 entities, enumerations, full DDL migration plan |
| clarifications.md | `.specify/specs/001-motor-cruce-ingresantes/clarifications.md` | Present | CQ-001–CQ-003 all resolved; 0 pending |
| contracts/asyncapi.yaml | `.specify/specs/001-motor-cruce-ingresantes/contracts/asyncapi.yaml` | Present | 3 messages; `correlation_id` absent from all payloads |
| contracts/openapi.yaml | `.specify/specs/001-motor-cruce-ingresantes/contracts/openapi.yaml` | Present | 7 paths; `CandidatoMatch` schema includes `estado_academia` |

All 9 artifacts are present and readable.

---

## 2. Requirements Extraction

### Functional Requirements

| ID | Source | Description | Status |
|---|---|---|---|
| US-001 | spec.md | CSV upload, normalization, filtering, async processing | Covered |
| US-002 | spec.md | Direct read-only query to academia DB | Covered |
| US-003 | spec.md | Two-phase match engine (exact + fuzzy) | Covered |
| US-004 | spec.md | React-based assisted validation UI | Covered |
| US-005 | spec.md | Excel report export (24 columns + charts) | Covered |
| AC-001 | spec.md | Multi-date batch split + deduplication + idempotency | TC-001 |
| AC-001a–AC-001f | spec.md | CSV validation, encoding, 20 MB limit, job failure tolerance, Redis resilience, 50s SLA | All covered |
| AC-002 | spec.md | UPPERCASE + diacritics removal + Ñ→N | TC-002 |
| AC-003 | spec.md | Compound surname parsing | TC-003 |
| AC-004 | spec.md | Post-normalization OBSERVACION filter; dual-table routing | TC-004 |
| AC-005/5a/6/7 | spec.md | Academia DB connection + field extraction + state hierarchy | TC-005, TC-045 |
| AC-008–AC-010 | spec.md | Exact match, fuzzy top-5, empty-list fallback | TC-006–TC-008 |
| AC-011–AC-013 | spec.md | React UI pendiente list, manual confirm, no_ingresado | TC-009, TC-010, TC-048 |
| AC-014–AC-015 | spec.md | Excel 24-column structure, Sheet 2 analytics | TC-011, TC-012, TC-034–TC-038 |
| AC-004a–AC-004b | spec.md | p95 < 300ms on candidatos; 404 on invalid alumno_id | TC-029, TC-026 |

### Non-Functional Requirements

| ID | Requirement | Verification |
|---|---|---|
| NFR-001 | ≤ 50s for ~27k rows (async, Redis) | TC-028 |
| NFR-002 | p95 < 300ms on `GET /api/cruce/ingresantes/{id}/candidatos` | TC-029 |
| NFR-003 | Up to 20 MB CSV upload without memory error | TC-030 |
| NFR-004 | No credentials in repo | TC-031, TC-046 |
| NFR-005 | Full batch traceability in `lotes_cruce` | TC-032, TC-047 |
| NFR-006 | Redis queue; tolerate worker restart; failed jobs in `failed_jobs` | TC-033, TC-020 |

### Business Invariants

| ID | Invariant | Test |
|---|---|---|
| INV-01 | Only `RealizarCruceExactoAction` assigns `confirmado_automatico` | TC-039 |
| INV-02 | `no_ingresantes` is append-only | TC-040 |
| INV-03 | `fecha_examen` is processed exactly once (UNIQUE) | TC-042 |
| INV-04 | Identical CSV rows deduplicated before persist | TC-043 |
| INV-05 | OBSERVACION filter uses normalized value only | TC-044 |
| INV-06 | State hierarchy is immutable | TC-005, TC-045 |
| INV-07 | Zero writes to academia connection | TC-041 |
| INV-08 | Credentials never hardcoded | TC-031, TC-046 |

---

## 3. Traceability Matrix

| Requirement | Test Cases | Task(s) | Gap? |
|---|---|---|---|
| US-001/AC-001 | TC-001 | T005, T007 | None |
| US-001/AC-001a | TC-014, TC-021 | T005, T008 | None |
| US-001/AC-001b | TC-018, TC-022 | T005 | None |
| US-001/AC-001c | TC-025 | T008 | None |
| US-001/AC-001d | TC-027 | T007 | None |
| US-001/AC-001e | TC-033 | T007 | None |
| US-001/AC-001f | TC-028 | T007 | None |
| US-001/AC-002 | TC-002 | T004 | None |
| US-001/AC-003 | TC-003 | T004 | None |
| US-001/AC-004 | TC-004 | T005 | None |
| US-001/AsyncAPI events | TC-050, TC-051 | T007 | None |
| US-002/AC-005, 5a, 6, 7 | TC-005, TC-045 | T006 | None |
| US-003/AC-008 | TC-006 | T006 | None |
| US-003/AC-009 | TC-007 | T009 | None |
| US-003/AC-010 | TC-008, TC-015 | T009 | None |
| US-004/AC-011 | TC-009, TC-048 | T010, T017 | None |
| US-004/AC-012 | TC-009 | T011, T012 | None |
| US-004/AC-013 | TC-010 | T011, T012 | None |
| US-004/AC-004a | TC-029 | T010 | None |
| US-004/AC-004b | TC-026 | T011 | None |
| US-005/AC-014 | TC-011, TC-034–TC-038 | T014 | None |
| US-005/AC-015 | TC-012 | T014 | None |
| NFR-001 | TC-028 | T007 | None |
| NFR-002 | TC-029 | T010 | None |
| NFR-003 | TC-030 | T008 | None |
| NFR-004 | TC-031 | T003 | None |
| NFR-005 | TC-032, TC-047 | T013 | None |
| NFR-006 | TC-033 | T007 | None |
| EC-001 | TC-013 | T005 | None |
| EC-002 | TC-014 | T005, T008 | None |
| EC-003 | TC-015 | T009 | None |
| EC-004 | TC-016 | T005 | None |
| EC-005 | TC-017 | T009 | None |
| EC-006 | TC-018 | T005 | None |
| EC-007 | TC-019 | T007 | None |
| EC-008 | TC-020 | T007 | None |
| ERR-001–ERR-007 | TC-021–TC-027 | T005, T006, T007, T008, T011 | None |
| INV-01–INV-08 | TC-039–TC-046 | T004, T005, T006, T001, T003 | None |

Traceability is complete. No requirement lacks a test case or an implementation task.

---

## 4. Orphan Analysis

### Orphan Test Cases (no requirement)
None. Every TC in the coverage matrix maps to at least one US/AC/NFR/EC/ERR/INV.

- TC-047 → NFR-005 (`/lotes/{lote_id}/status`)
- TC-048 → US-004/AC-011
- TC-049 → US-001, US-004, NFR-005, openapi.yaml `/cruce/lotes` GET, plan.md §4.1
- TC-050 → US-001/AsyncAPI (`CruceBatchProcessedEvent`)
- TC-051 → US-001/AsyncAPI (`CruceBatchFailedEvent`)

### Orphan Tasks (no requirement)
None. All 21 tasks trace to spec artifacts.

### Minor Coverage Gap (LOW)
TC-049 has no explicit row in the §7 coverage matrix. Traceability exists in T020's Coverage list and TC-049's own `Trazas a` header. Risk: zero.

---

## 5. Goal-Backward Verification

**Feature Goal:** Automate identity matching of UNMSM applicants against the Vonex academy database, processing ~27,000 records per batch asynchronously (≤ 50 seconds), with assisted manual resolution of ambiguous cases, full traceability by exam date, and Excel report export.

| Goal Component | Coverage |
|---|---|
| Async processing ≤ 50s for ~27k rows | NFR-001 → T007 → TC-028 ✓ |
| Normalize + filter against academia DB | US-001/AC-004, US-002/AC-005 → T004, T006 ✓ |
| Two-phase matching (exact + fuzzy) | US-003 → T006, T009 → TC-006, TC-007 ✓ |
| Manual resolution of ambiguous cases (React) | US-004 → T010, T011, T017 → TC-009, TC-010 ✓ |
| Full traceability by exam date | NFR-005, INV-03 → T001, T013 → TC-032, TC-047 ✓ |
| Excel report export | US-005/AC-014–AC-015 → T014, T015 → TC-011, TC-012 ✓ |

Goal fully covered. No stranded goal elements.

---

## 6. Gap-Closure Analysis

All gaps identified in runs 1–4 have been remediated. Residual items are LOW severity only (see §11). AD-001 (fuzzy match lazy-on-demand) and AD-002 (`correlation_id` removed) are documented in plan.md and applied in asyncapi.yaml and tasks.md. clarifications.md: 0 pending questions.

---

## 7. Contract Verification

### asyncapi.yaml

| Message | `correlation_id` present? | Required fields | Result |
|---|---|---|---|
| ProcessCsvBatchJob | NO | `lote_id`, `file_path` | PASS |
| CruceBatchProcessedEvent | NO | `lote_id`, `total_registros`, `total_ingresantes`, `total_no_ingresantes` | PASS |
| CruceBatchFailedEvent | NO | `lote_id`, `error_message` | PASS |

`correlation_id` is absent from all three messages and their `required` arrays. AD-002 correctly applied.

### openapi.yaml

| Check | Result |
|---|---|
| `GET /cruce/ingresantes/{id}/candidatos` exists | PASS |
| `CandidatoMatch` schema has `estado_academia` (required) | PASS |
| `CandidatoMatch` schema does NOT have `ranking` | PASS |
| `LoteCruce.estado` enum is `[processing, completed, paused, error]` | PASS — all English |
| All 7 endpoints in plan.md §4.1 present | PASS |
| Auth schemes defined (CookieAuth + BearerAuth) | PASS |

T010 response format `{ alumno_id, nombre_completo, porcentaje_similitud, estado_academia }` matches `CandidatoMatch` schema exactly. `ranking` absent from both. PASS.

T007 `CruceBatchProcessedEvent` payload `{ lote_id, total_registros, total_ingresantes, total_no_ingresantes }` matches asyncapi.yaml required fields exactly. PASS.

spec.md NFR-002 path `/api/cruce/ingresantes/{id}/candidatos` is consistent with openapi.yaml base URL `/api` + path `/cruce/ingresantes/{id}/candidatos`. PASS.

---

## 8. Task Dependency Graph

### Critical Check Results

| Check | Expected | Found | Result |
|---|---|---|---|
| T001→T003 edge absent | Absent | Absent | PASS |
| T002→T004 edge absent | Absent | Absent | PASS |
| T002→T009 present | Present | `T002 --> T009` | PASS |
| T004→T009 present | Present | `T004 --> T009` | PASS |
| T002→T005 present | Present | `T002 --> T005` | PASS |
| T002→T011 present | Present | `T002 --> T011` | PASS |
| T018 `_Depends_` excludes T015 | Excluded | `_Depends: T016, T017_` | PASS |

### DAG Soundness
No cycles. Starting nodes (no incoming edges): T001, T003, T004. All phase transitions respected. Test tasks T019–T021 form a sequential chain independent of feature tasks. T021→T020→T008/T011/T013 dependency chain is correct.

---

## 9. Contradiction Detection

| Scenario | Finding |
|---|---|
| EC-007 vs ERR-003 vs TC-019 (connection failure state) | RESOLVED — CQ-003: connection failure → `paused`; all three artifacts aligned |
| EC-008 state on worker restart | CONSISTENT — lote stays `processing` (job pending retry); TC-020 confirms |
| ERR-007 state on catastrophic job failure | CONSISTENT — lote → `error`; TC-027 confirms |
| T007 AC "or" clause | LOW — "lote stays in `processing` or moves to `error`" reflects two distinct failure modes already documented in EC-008/ERR-007; not a contradiction, just underspecified text |
| NFR-002 endpoint path | CONSISTENT — `/api/cruce/ingresantes/{id}/candidatos` across spec.md, openapi.yaml, plan.md |
| BatchStatus enum values | FULLY CONSISTENT — `processing`, `completed`, `paused`, `error` in all artifacts; zero Spanish variants |

No critical or high-severity contradictions found.

---

## 10. Completeness Assessment

| Area | Status | Notes |
|---|---|---|
| Business invariants covered by tests | Complete | INV-01–INV-08 all have dedicated TCs (TC-039–TC-046) |
| AsyncAPI events covered | Complete | TC-050 (processed), TC-051 (failed) |
| All 7 endpoints have tasks and tests | Complete | T008, T010, T012, T013, T015 + respective TCs |
| Performance test coverage | Complete | TC-028 (NFR-001), TC-029 (NFR-002), TC-030 (NFR-003) |
| Security test coverage | Complete | TC-031, TC-046 (credentials); TC-041 (read-only academia) |
| Error scenarios ERR-001–ERR-007 | Complete | TC-021–TC-027 |
| Edge cases EC-001–EC-008 | Complete | TC-013–TC-020 |
| Excel calculations (AREA, L1, L2, L3) | Complete | TC-034–TC-038 |
| Clarifications | Complete | 0 pending questions |
| Spec alignment with CQ-003 | Complete | spec.md v2.7.0, plan.md §8.1, asyncapi.yaml AD-002 all aligned |

---

## 11. Issues Found

### CRITICAL — None

### HIGH — None

### MEDIUM — None

### LOW (zero implementation risk)

| ID | Artifact | Finding | Risk |
|---|---|---|---|
| L-01 | tasks.md T007 | AC text "lote stays in `processing` or moves to `error`" — the `or` is ambiguous between EC-008 (worker restart → `processing`) and ERR-007 (catastrophic failure → `error`). Distinction is correctly documented in spec.md and individual TCs. | Zero |
| L-02 | test-cases.md TC-007 | "Esperado: similitud >= 85% con la fórmula Dice bigramas" — should read "con la fórmula compuesta (Levenshtein × 0.6 + Dice bigramas × 0.4)". Formula is correct in the Given section. | Zero |
| L-03 | test-cases.md §7 | TC-049 has no dedicated row in the §7 coverage matrix. Traceability exists in T020 Coverage list and TC-049's own header. | Zero |
| L-04 | contracts/openapi.yaml | `CandidatoMatch.description` says "computed Levenshtein similarity metric" — actual formula also uses Dice bigramas. Schema fields are correct. | Zero |
| L-05 | tasks.md DAG | T009 reaches T003 (DB Config) only transitively via T006→T009. A direct T003→T009 edge would be more explicit but is architecturally sound as-is. | Zero |

---

## 12. Verdict & Recommendation

**VERDICT: PASS**

All 15 critical checks pass. The 11-step analysis found zero CRITICAL, zero HIGH, and zero MEDIUM issues. Five LOW issues identified — all are documentation clarity items with zero implementation risk.

**Implementation may proceed.** Recommended parallel start: T001 (Migrations), T003 (Academia DB Config), T004 (NormalizarTextoAction). T019 [T] unit tests can begin in parallel once T004 is ready.

**Confidence level: HIGH.** Run 5 is the definitive post-remediation pass. All structural, semantic, and contract issues from prior runs have been resolved. The artifact set is internally consistent and complete.

---

## 13. Prior Issue Resolution Log

| Issue | Run Identified | Artifact(s) Affected | Status | Evidence |
|---|---|---|---|---|
| Spanish enum `pausado` in NFR-006 | Run 1 | spec.md | FIXED | spec.md NFR-006 uses `paused`; v2.7.0 revision note: "NFR-006 corregido de `pausado` a `paused`" |
| Spanish enum `procesando` in EC-008 | Run 1 | spec.md | FIXED | spec.md EC-008: "el lote permanece en estado `processing`" |
| `correlation_id` in asyncapi.yaml all 3 messages | Runs 1–2 | contracts/asyncapi.yaml | FIXED | All 3 messages: no `correlation_id` in properties or required; plan.md AD-002 documents removal (2026-06-30) |
| TC-023 asserting `error` for connection failure | Run 2 | test-cases.md | FIXED | TC-023: "el lote queda en estado `paused` (fallo recuperable, ver CQ-003)" |
| T010 response missing `estado_academia` | Run 2 | tasks.md | FIXED | T010 AC: "array of `{ alumno_id, nombre_completo, porcentaje_similitud, estado_academia }`" |
| T010 response including `ranking` | Run 2 | tasks.md | FIXED | `ranking` absent from T010 response format and from `CandidatoMatch` schema |
| T007 `CruceBatchProcessedEvent` payload missing `total_no_ingresantes` | Run 2 | tasks.md | FIXED | T007 AC payload matches asyncapi.yaml exactly |
| T018 `_Depends_` incorrectly included T015 | Run 3 | tasks.md | FIXED | T018: `_Depends: T016, T017_` only; explicit note documents T015 removal |
| EC-007 / ERR-003 using `error` for recoverable connection failure | Run 1 | spec.md, clarifications.md | FIXED | CQ-003 resolved; EC-007 → `paused`; ERR-003 → `paused`; ERR-007 → `error` |
| data-model.md ERD NoIngresante had `updated_at` | Run 3 | data-model.md | FIXED | ERD NoIngresante terminates at `timestamp created_at`; §2.3 entity table has no `updated_at` row |
| Missing T019, T020, T021 [T] test tasks | Run 3 | tasks.md | FIXED | All three tasks present with full detail and Mermaid DAG nodes |
| Missing TC-049, TC-050, TC-051 | Run 3 | test-cases.md | FIXED | All three test cases present with Given/When/Then |
| plan.md §4.1 missing `GET /api/cruce/ingresantes/{id}/candidatos` | Run 2 | plan.md | FIXED | §4.1 Endpoints Summary row present |
| plan.md §12 Issue #1 open (Levenshtein threshold undecided) | Run 2 | plan.md | FIXED | §12 Issue #1 struck through; RESOLVED status; threshold confirmed at 30% |
| Coverage matrix missing rows for AC-001b through AC-001f | Run 3 | test-cases.md | FIXED | §7 matrix rows present for AC-001b, AC-001c, AC-001d, AC-001e, AC-001f |
| DAG contained invalid edges T001→T003 and T002→T004 | Run 3 | tasks.md | FIXED | Neither edge present; T003 and T004 are independent starting nodes |
| DAG missing required edges (T002→T009, T004→T009, T002→T005, T002→T011) | Runs 3–4 | tasks.md | FIXED | All four edges present in Mermaid DAG |
