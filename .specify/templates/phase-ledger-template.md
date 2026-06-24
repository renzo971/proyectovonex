# Phase Execution Ledger: [FEATURE_NAME]

**Feature ID:** [NNN]-[feature-slug]
**Created:** [DATE]
**Last Updated:** [DATE]
**Ledger Mode:** Manual | Generated via `sdd status --phase-ledger`

> This ledger is a **read-only derivative** of existing `.specify/` gate artifacts. It provides a compact, human-auditable timeline of the feature's execution across all SDD phases. It does not replace the source artifacts — edit `.specify/specs/<feature-id>/` files directly.

---

## Phase Summary

| Phase | Name | Status | Gate | Date |
|-------|------|:------:|:----:|------|
| 0 | Pre-Specification (Brainstorm / Constitution) | ✅ / 🟡 / ⬜ | — | |
| 1 | Specification (US + AC) | ✅ / 🟡 / ⬜ | Gate 1 | |
| 2 | Design (Architecture + Contracts) | ✅ / 🟡 / ⬜ | Gate 2 | |
| 3 | Test Preparation (TC + Tasks) | ✅ / 🟡 / ⬜ | Gate 3 | |
| 4 | Implementation (TDD Red→Green) | ✅ / 🟡 / ⬜ | — | |
| 5 | Review & Ship | ✅ / 🟡 / ⬜ | Gate 4 | |

---

## Phase Details

### Phase 0 — Pre-Specification

**Status:** ✅ Complete / 🟡 In Progress / ⬜ Not Started

**Plan Summary:**
- [ ] Business context established
- [ ] Constitution reviewed for relevant articles
- [ ] Feature scope agreed with stakeholders

**Execution Log:**
> [Key decisions, context notes, or scope changes from this phase]

**Open Items from this phase:**
- [Item 1 — resolved / deferred to Phase N]

---

### Phase 1 — Specification (Gate 1)

**Status:** ✅ Complete / 🟡 In Progress / ⬜ Not Started
**Gate 1 Result:** PASS / FAIL / Not yet run

**Plan Summary:**
- [ ] Spec written (`spec.md`)
- [ ] User Stories: [N] stories
- [ ] Acceptance Criteria: [N] AC items
- [ ] Clarifications resolved: [N/N]

**Execution Log:**
> [Key clarifications, scope changes, stakeholder input from this phase]

**Gate Evidence:**
- `spec.md` — [exists / missing]
- `clarifications.md` — [exists / missing]
- `business-context.md` — [exists / missing]
- External References: [present / absent]

**Open Items from this phase:**
- [Item 1]

---

### Phase 2 — Design (Gate 2)

**Status:** ✅ Complete / 🟡 In Progress / ⬜ Not Started
**Gate 2 Result:** PASS / FAIL / Not yet run

**Plan Summary:**
- [ ] Architecture design completed (`plan.md`)
- [ ] API contracts defined
- [ ] Data model documented
- [ ] ADR written (if applicable)

**Execution Log:**
> [Architecture decisions, trade-offs, constraints encountered]

**Gate Evidence:**
- `plan.md` — [exists / missing]
- `data-model.md` — [exists / missing]
- `aggregate-decision-record.md` (if DDD) — [exists / N/A]

**Open Items from this phase:**
- [Item 1]

---

### Phase 3 — Test Preparation (Gate 3)

**Status:** ✅ Complete / 🟡 In Progress / ⬜ Not Started
**Gate 3 Result:** PASS / FAIL / Not yet run

**Plan Summary:**
- [ ] Test cases written: [N] TC items
- [ ] Implementation tasks defined: [N] tasks
- [ ] TDD stubs created (if TDD mode active)

**Execution Log:**
> [Test design decisions, coverage notes]

**Gate Evidence:**
- `test-cases.md` — [exists / missing]
- `tasks.md` — [exists / missing]

**Open Items from this phase:**
- [Item 1]

---

### Phase 4 — Implementation

**Status:** ✅ Complete / 🟡 In Progress / ⬜ Not Started

**Plan Summary:**
- [ ] TDD Red phase (failing tests written)
- [ ] TDD Green phase (implementation complete)
- [ ] All tasks marked done: [N/N]

**Execution Log:**
> [Implementation notes, blockers encountered, scope changes during build]

**Open Items from this phase:**
- [Item 1]

---

### Phase 5 — Review & Ship (Gate 4)

**Status:** ✅ Complete / 🟡 In Progress / ⬜ Not Started
**Gate 4 Result:** GO / GO with conditions / NO-GO / Not yet run

**Plan Summary:**
- [ ] Code review complete
- [ ] Security review complete
- [ ] Test evidence reviewed
- [ ] Gate 4 release packet produced

**Execution Log:**
> [Review findings summary, blockers resolved]

**Gate Evidence:**
- `review-output.md` — [exists / missing]
- `security-review-output.md` — [exists / missing]
- `test-report.md` — [exists / missing]
- `gate4-release-packet.md` — [exists / missing]

**Open Items from this phase:**
- [Item 1]

---

## Timeline

| Date | Phase | Event | Actor |
|------|-------|-------|-------|
| [DATE] | 0 | Feature created | [Name] |
| [DATE] | 1 | Gate 1 passed | [Agent / Name] |
| [DATE] | 2 | Gate 2 passed | [Agent / Name] |
| [DATE] | 3 | Gate 3 passed | [Agent / Name] |
| [DATE] | 5 | Gate 4 GO verdict | [Agent / Name] |

---

## Retrospective Notes

> Add any lessons learned or process improvements identified during this feature.

- [Note 1]
