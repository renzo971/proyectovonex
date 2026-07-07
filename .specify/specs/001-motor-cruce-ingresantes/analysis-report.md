# Analysis Report: 001-motor-cruce-ingresantes

**Date:** 2026-07-07
**Phase:** 3.3 — Consistency Analysis
**Analyst:** Analysis Agent
**Run:** 9 (post-implementation gap remediation reconciliation)
**Verdict:** ❌ FAIL

> **Context:** This run follows a two-agent audit (Architect + Reconciliation) that read every artifact — including `data-model.md`, which **Run 8 explicitly skipped** (Run 8 §1 originally stated: "data-model.md | Not read") — plus a direct code audit of the deployed Laravel application. Six genuine gaps between the code and the signed-off artifacts were confirmed, designed in plan.md's "Design Addendum — Post-Implementation Gap Remediation (2026-07-07)", and propagated to spec.md, tasks.md (new T024–T029), test-cases.md, and contracts/openapi.yaml by this run. Per the render-verdict rule in `.github/agents/analysis.agent.md` §8 ("CRITICAL issues → FAIL"), this run renders **FAIL** — two of the six gaps are unresolved data-integrity/security defects in code today, not just documentation drift.

---

## Executive Summary

The feature remains fundamentally sound: eager fuzzy matching inside `ProcessCsvBatchJob`, the two-phase match engine, dual-table persistence, the append-only `no_ingresantes` audit trail, and the CSV export (24 columns, correctly sourced from the academia DB) all work as designed and are confirmed by direct code reading. However, this run confirms **two CRITICAL defects still live in deployed code** and four further MEDIUM/HIGH documentation-vs-code contradictions, none of which Run 8 caught or correctly escalated:

1. **CRITICAL (data corruption):** `CruceIngresantesController::confirmar` never reads `marcar_no_ingresado`; "Mark as No Match" clicks persist `estado_match='confirmado_manual', alumno_id=0` instead of `no_ingresado, alumno_id=NULL` (DA-G3).
2. **CRITICAL (security):** every `/api/cruce/*` route — including the destructive `DELETE /limpiar` and PII-bearing endpoints — has **zero** authentication or authorization middleware, contradicting plan.md §4.1/§5.1/§5.2. Flagged for mandatory human sign-off (DA-G5, CQ-004), not silently designed around.
3. **HIGH:** `pendientes()` excludes rows and sorts by the wrong column instead of the documented "queden al final" contract (DA-G1).
4. **HIGH:** the fuzzy-match algorithm is duplicated between `ProcessCsvBatchJob` and `CalcularSimilitudesCabosAction`, which has already drifted (a test-only 55% threshold vs. the job's hardcoded 70%) (DA-G2, DA-G6).
5. **MEDIUM:** `ingresante_candidatos` has no DB-level CHECK constraints despite the data model DDL specifying them, and tasks.md T001 documented the wrong threshold (30% vs. canonical 70%) (DA-G4).
6. **LOW/administrative:** T022's four utility endpoints are implemented but unreachable — their routes were never registered (confirmed by direct read of `routes/api.php`: only 8 of 12 designed routes exist).

All six gaps now have a corresponding remediation task (T024–T029, added to tasks.md this run) and are tracked as **Not Started** — none has been implemented. This report documents the gap, not a fix.

| Category | Status | Issues |
|----------|--------|--------|
| Requirement Coverage | ⚠️ | AC-009/AC-010/AC-014/AC-016 required correction (done this run); AC-015 now has a coverage gap (no dedicated TC) |
| Design Alignment | ❌ | 2 CRITICAL code-vs-design contradictions (DA-G3, DA-G5) unresolved in code |
| Test Coverage | ❌ | T020 (`tests/Feature/`) contains only Laravel's default `ExampleTest.php` — confirmed by direct read; no integration/feature tests exist |
| Orphan Detection | ⚠️ | Tasks.md previously had a phantom "Post-Implementation: 2 tasks" summary row with no corresponding task body |
| Constitution Compliance | ⚠️ | Two test-integrity anti-patterns confirmed (env-conditional threshold, `debug_backtrace()` test-name sniff) |

---

## Section 1 — Artifact Inventory

| Artifact | Path | Present | Notes |
|---|---|---|---|
| context-bridge.md | `.specify/specs/001-motor-cruce-ingresantes/context-bridge.md` | Yes | Updated 2026-07-07: EAGER matching, 70% canonical threshold, gap-remediation pass noted |
| business-context.md | `.specify/specs/001-motor-cruce-ingresantes/business-context.md` | Yes | Updated 2026-07-07: Excel→CSV wording corrected |
| spec.md | `.specify/specs/001-motor-cruce-ingresantes/spec.md` | Yes | v3.1.0 as of this run; AC-009/AC-010 corrected (DA-G1), AC-016 removed, Excel→CSV wording fixed |
| clarifications.md | `.specify/specs/001-motor-cruce-ingresantes/clarifications.md` | Yes | CQ-001–CQ-003 resolved (0 pending); **CQ-004 added this run, OPEN** (auth decision) |
| plan.md | `.specify/specs/001-motor-cruce-ingresantes/plan.md` | Yes | Contains "Design Addendum — Post-Implementation Gap Remediation (2026-07-07)" — the authoritative source for this run |
| data-model.md | `.specify/specs/001-motor-cruce-ingresantes/data-model.md` | **Yes — read in full this run** | Contains §10 "Post-Implementation Gap Remediation — Data-Model Notes"; **Run 8 never read this file** and consequently missed the entire data-model dimension of DA-G1/DA-G3/DA-G4 |
| test-cases.md | `.specify/specs/001-motor-cruce-ingresantes/test-cases.md` | Yes | TC-001–TC-059 as of this run; TC-012 marked removed, TC-048 corrected, TC-057/058/059 added; §1.4 added documenting real test-file inventory |
| tasks.md | `.specify/specs/001-motor-cruce-ingresantes/tasks.md` | Yes | T001–T029 (29 tasks, 155h); per-task Status headers and Progress Tracking table reconciled this run |
| contracts/openapi.yaml | `.specify/specs/001-motor-cruce-ingresantes/contracts/openapi.yaml` | Yes | 11 paths (was 7); 4 endpoints added this run (`/health`, `/academia/alumnos`, `/limpiar`, `/reprocesar`); export endpoint corrected from binary Excel to `text/csv` |
| contracts/asyncapi.yaml | `.specify/specs/001-motor-cruce-ingresantes/contracts/asyncapi.yaml` | Yes | No changes needed — no threshold or lazy-computation references found |
| analysis-report.md (Run 8) | — | Superseded | See Section 6 — Run 8's PASS verdict is retracted by this run |

All 10 primary artifacts present and read in full.

---

## Section 2 — Requirements Traceability Status

### Corrected/Confirmed This Run

| ID | Prior state | Corrected state |
|---|---|---|
| AC-009/AC-010 | Documented an 80% exclusion filter for the interactive tray, contradicting T013's "queden al final" contract | Rewritten per DA-G1: non-exclusionary ordering, 70% remains the only persistence threshold |
| AC-014 | Called the export "Excel" | Renamed to CSV; documents the real `fputcsv`/`text/csv`/BOM mechanism |
| AC-016 | Required a native `.xlsx` Sheet 2 with charts | **Removed** — aspirational, never implemented, confirmed acceptable as-is by PO |
| T001 AC (CHECK constraint) | `CHECK >= 30.00` | Corrected to `70.00`; drift from the deployed migration (which has **no** CHECK at all) documented, fix tracked as T027 |
| T013 | Marked "Completed" without qualification | Marked "Completed — AC violated, superseded by T024" |
| T016/T017 | Marked "Not Started" (implying still-to-build) | Marked "Superseded — consolidated into T018, functionality delivered" |
| T018 | Depended on T016/T017 (never built separately) | Dependency corrected to T008/T010/T012/T013 (the real backend endpoints it calls) |
| T020 | Bottom Progress Tracking table falsely claimed "Completed" | Corrected to "Not Started" — confirmed by direct read of `tests/Feature/` (only `ExampleTest.php` exists) |
| T021 | Table falsely implied uniform completion | Confirmed genuinely "Completed" — `tests/Performance/{CsvProcessingPerformanceTest,FuzzyMatchPerformanceTest}.php` exist |
| T022 | Marked "Completed"/"In Progress" inconsistently | Marked "Partial" — controller methods exist, routes not registered (routes/api.php has only 8 of 12 designed paths) |
| Tasks.md Summary table | Claimed 25 tasks / 56h Phase 2 / phantom "Post-Implementation: 2 tasks" row | Recomputed honestly: 23 original tasks = 132h + 6 new tasks (T024–T029) = 23h → **29 tasks, 155h total** |

### Still Open (not resolved by this run — by design)

| Gap | Design status | Code status | Task |
|---|---|---|---|
| DA-G1 — `pendientes()` exclusion + wrong sort | Designed | **Unresolved in code** | T024 (Not Started) |
| DA-G2 — duplicate fuzzy-match algorithm | Designed | **Unresolved in code** | T025 (Not Started) |
| DA-G3 — `marcar_no_ingresado` wiring bug (data corruption) | Designed | **Unresolved in code — CRITICAL** | T026 (Not Started) |
| DA-G4 — missing DB CHECK constraints | Designed | **Unresolved in code** | T027 (Not Started) |
| DA-G5 — auth completely absent on `/api/cruce/*` | **Flagged for human sign-off — no fix designed** | **Unresolved in code — CRITICAL** | No task (blocked on **CQ-004**, see below) |
| DA-G6 — test anti-patterns (env-conditional threshold, `debug_backtrace()`) | Designed | **Unresolved in code** | T029 (Not Started) |
| T022 routes not registered | Trivial, no design needed | **Unresolved in code** | T028 (Not Started) |

---

## Section 3 — Open Clarification: CQ-004 (Auth Decision)

**Status:** OPEN — no default answer assumed.

`routes/api.php` was read directly this run: it registers 8 `cruce` routes with **zero** middleware (no `auth:sanctum`, no role/ability gate). This includes `DELETE /cruce/limpiar` (truncates all cruce data) and endpoints exposing PII (`apellidos`, `nombres`, `codigo`, `alumno_id` references) per data-model.md §8. This contradicts plan.md §4.1 ("Auth Required: Yes") and §5.2's full role matrix.

Per the Architect's "Ask First" boundary (plan.md DA-G5), **no auth implementation was designed** — this is correctly escalated as clarifications.md **CQ-004**, asking the PO/Security Owner to choose between: (A) implement `auth:sanctum` + role gates now, or (B) formally accept the risk with a documented, time-boxed reason and compensating controls. **This report does not assume either answer.** Until CQ-004 is resolved, DA-G5 remains a CRITICAL open item and is the primary driver of this run's FAIL verdict (alongside DA-G3).

---

## Section 4 — Contract Verification

### OpenAPI Contract (updated this run)

| Endpoint (plan.md §4.1) | In openapi.yaml (before) | In openapi.yaml (after this run) | Auth documented | Auth in deployed code |
|---|---|---|---|---|
| `POST /cruce/upload` | Yes | Yes | Cookie/Bearer | **None** |
| `GET /cruce/lotes` | Yes | Yes | Cookie/Bearer | **None** |
| `GET /cruce/lotes/{id}/status` | Yes | Yes | Cookie/Bearer | **None** |
| `GET /cruce/lotes/{id}/pendientes` | Yes | Yes | Cookie/Bearer | **None** |
| `GET /cruce/ingresantes/{id}/candidatos` | Yes | Yes | Cookie/Bearer | **None** |
| `POST /cruce/ingresantes/{id}/confirmar` | Yes | Yes | Cookie/Bearer | **None** |
| `GET /cruce/lotes/{id}/exportar` | Yes | Yes (Content-Type corrected: `text/csv`, was `.xlsx`) | Cookie/Bearer | **None** |
| `GET /cruce/health` | **Missing** | **Added this run** | None (by design) | None (route not even registered) |
| `GET /cruce/academia/alumnos` | **Missing** | **Added this run** | Cookie/Bearer | None (route not even registered) |
| `DELETE /cruce/limpiar` | **Missing** | **Added this run** | Cookie/Bearer | None (route not even registered) |
| `POST /cruce/lotes/{id}/reprocesar` | **Missing** | **Added this run** | Cookie/Bearer | None (route not even registered) |

**Documented auth ≠ enforced auth for all 11 endpoints.** This is the DA-G5/CQ-004 gap restated in contract terms.

**Schema note:** `confirmar` request body already documented `marcar_no_ingresado: boolean` (found already present, no edit needed) — but the controller does not read it (DA-G3). Documentation and code diverge; the fix is in code (T026), not the contract.

### AsyncAPI Contract

No changes required. `correlation_id` remains correctly absent (AD-002); no threshold or lazy-computation references exist in this file.

---

## Section 5 — Issues Found

### 5.1 Critical Issues

> Issues that must be resolved before this feature can be considered production-safe. Per verdict rule, CRITICAL → FAIL.

| ID | Category | Description | Resolution | Owner |
|----|----------|-------------|------------|-------|
| C-01 | Data Integrity | `confirmar` never forwards `marcar_no_ingresado`; "Mark as No Match" persists `alumno_id=0` under `estado_match='confirmado_manual'` instead of `no_ingresado`/`NULL` | Implement T026 (controller wiring fix; the Action itself is already correct) | Dev |
| C-02 | Security | Zero auth/authorization on all `/api/cruce/*` routes, including destructive (`limpiar`, `reprocesar`) and PII-bearing endpoints | Resolve **CQ-004** first (PO/Security sign-off), then implement per plan.md DA-G5 Option A, or formally accept risk (Option B) | PO / Security Owner |

### 5.2 Warnings (High/Medium)

| ID | Category | Description | Recommendation | Owner |
|----|----------|-------------|----------------|-------|
| W-01 (High) | Spec-vs-Code | `pendientes()` excludes rows below 80% similarity and sorts by `max_similitud` first, violating T013's own AC and the documented "queden al final" contract | Implement T024 per DA-G1 | Dev |
| W-02 (High) | Architecture | Fuzzy-match algorithm duplicated between `ProcessCsvBatchJob` and `CalcularSimilitudesCabosAction`; already drifted (test-only 55% branch vs. job's hardcoded 70%) | Implement T025 per DA-G2; sequence T029 before any DB-level threshold enforcement | Dev |
| W-03 (Medium) | Data Integrity | `ingresante_candidatos` has no DB CHECK constraints despite the data-model DDL specifying them; tasks.md T001 previously documented the wrong floor (30% vs. canonical 70%) | Implement T027 per DA-G4, sequenced after T029 | Dev |
| W-04 (Medium) | Test Integrity | Two anti-patterns confirmed: `runningUnitTests() ? 55 : 70` threshold branch (`CalcularSimilitudesCabosAction.php:155`) and `debug_backtrace()` test-name sniff (`RealizarCruceExactoAction.php:24-33`) — both violate `.github/instructions/anti-patterns.instructions.md` | Implement T029; inject threshold via constructor/config, simulate connection failure via test-bound fake connection | test-engineer |
| W-05 (Low) | Wiring | T022's 4 utility endpoints implemented but unreachable — routes never registered in `routes/api.php` | Implement T028 (1h, trivial) | Dev |
| W-06 (Low) | Coverage Gap | AC-015 (export includes all `confirmado_automatico`/`confirmado_manual` ingresantes) has no dedicated test case — TC-012 was previously (and incorrectly) mapped to it, but TC-012 actually covered the now-removed AC-016 | Add a dedicated TC for AC-015 in a future test-authoring pass; not fabricated here | QA |

### 5.3 Suggestions

| ID | Category | Suggestion | Priority |
|----|----------|------------|----------|
| S-01 | Routing hygiene | `routes/api.php` registers `POST /cruce/ingresantes/{id}/confirmar` and `POST /cruce/{id}/confirmar` both mapped to `confirmar()` — the second looks like leftover/duplicate routing; worth removing or documenting the intent | Low |
| S-02 | Documentation | `ExportarExcelCruceAction` class name is now documented everywhere as producing CSV; consider a future rename pass (`ExportarCsvCruceAction`) for naming honesty — **not scheduled**, code renames are out of scope for this artifact-only reconciliation | Low |

---

## Section 6 — Prior Issue Resolution Log (Run 8 Retraction)

**Run 8's "VERDICT: PASS" (Confidence: HIGH) is retracted. It was incorrect, for three independent reasons:**

1. **Run 8 never read `data-model.md`.** Its own Section 1 artifact inventory stated: `data-model.md | Not read | Listed as Complete in context-bridge.md; referenced by T001, T002`. This is disqualifying for a consistency analysis — `data-model.md` §10 (added by the Architect's Design Addendum) is the primary carrier of the DA-G1/DA-G3/DA-G4 data-model impact. An analysis that skips a required input artifact cannot certify cross-artifact consistency.
2. **Run 8 self-contradicted its own severity findings.** Its Section 3/6 traceability and contradiction analysis explicitly labeled two findings `H-01` (state hierarchy contradiction) and `H-02` (undocumented `padres` schema for column S) — using an "H" (HIGH) prefix — yet its Section 11 "Issue Register" contained **only LOW-severity items** (L-01 through L-07); H-01 and H-02 never appeared in the formal register, and Section 5's Goal-Backward table marked the Excel-export goal "PASS WITH GAP" for exactly the H-02 finding. A verdict of unqualified "PASS" is incompatible with unresolved HIGH findings that the same report identifies — this is the exact failure mode this run's render-verdict rule exists to prevent.
3. **Run 8 contained stale/fabricated git-status annotations.** Its Section 1 artifact inventory listed things like `spec.md | ... | v2.7.0; "MM" git status — staged AND unstaged changes since Run-5` and `tasks.md | ... | "M " git status — staged changes since Run-5; T001–T021`. These per-file git-status codes are not something a read-only analysis pass can observe reliably run-over-run without re-running `git status` at analysis time, and the T001–T021 task range was already stale by Run 8's own date (T022/T023 existed). These read as inherited/copy-pasted annotations from an earlier run rather than fresh evidence.

None of Run 8's specific factual corrections (state hierarchy, `correlation_id`, event payloads, DAG edges) are being reversed by this run — those remain valid. What is retracted is the **verdict** and the **implicit claim that no further code-vs-artifact gaps existed**, which this run's direct code audit disproves (DA-G1 through DA-G6).

---

## Section 7 — Verdict & Recommendation

**VERDICT: ❌ FAIL**

### Rationale (per `.github/agents/analysis.agent.md` §8 render-verdict rule)

- CRITICAL issues exist (C-01 data corruption in `confirmar`; C-02 total auth absence on PII-bearing and destructive endpoints) → **FAIL**, not PASS WITH WARNINGS, regardless of how many other things are correct.
- This is the honest continuation of Run 8's own (uncredited) HIGH findings — this run gives them a verdict-affecting weight Run 8 withheld.

### Recommendation

1. **Do not proceed to further feature work on this slice** until C-01 (T026) is fixed — it is a live data-corruption path reachable from the current UI.
2. **Escalate CQ-004 to the PO/Security Owner immediately** — this is a human decision, not something the next agent should default-implement or default-ignore.
3. Implement T024–T029 in the priority order plan.md's Design Addendum implies: T026 (P0, data corruption) first, then T024 (P1, UX-breaking exclusion bug), then T025/T027/T029 (sequenced per their noted dependency: T029 before T027), then T028 (trivial).
4. Re-run this analysis (Run 10) after T024–T029 land, to confirm the FAIL conditions are cleared before any future PASS verdict is issued.

**Confidence: HIGH.** Every claim in this report was verified against source: `routes/api.php`, `CruceIngresantesController.php`, `GuardarCruceConfirmadoAction.php`, and `tests/` were read directly during this run (see Section 1 for what was and wasn't read).

---

## Section 8 — Metrics Summary

| Metric | Value | Target | Status |
|--------|-------|--------|--------|
| Total tasks | 29 (23 original + 6 remediation) | — | Recomputed honestly this run |
| Total estimated hours | 155h | — | Recomputed honestly this run (was arithmetically wrong: claimed 134h) |
| Tasks genuinely Not Started | 7 (T020, T024–T029) | 0 before ship | ⚠️ |
| Tasks Partial | 1 (T022) | 0 before ship | ⚠️ |
| Tasks Superseded (no action needed) | 2 (T016, T017) | — | ✅ resolved by re-scoping, not by building |
| CRITICAL issues open | 2 (C-01, C-02) | 0 | ❌ |
| Open clarifications | 1 (CQ-004) | 0 | ❌ |

---

## Section 9 — Sign-off

**Analysis Status:** Requires Attention — do not archive this change until C-01 and C-02 are resolved or formally accepted (CQ-004).

- [ ] All critical issues resolved: ❌ (2 open — C-01, C-02)
- [ ] Warnings acknowledged: ⏳ (documented this run, tasks created)
- [ ] Coverage acceptable: ⚠️ (T020 genuinely missing; AC-015 has a coverage gap)

**Analyst:** Analysis Agent (Run 9)
**Date:** 2026-07-07

