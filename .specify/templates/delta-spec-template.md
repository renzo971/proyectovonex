# Delta Specification: [CHANGE_TITLE]

**Feature ID:** [NNN]-[feature-slug]
**Created:** [DATE]
**Author:** [NAME]
**Status:** Proposed | Approved | Implemented | Archived

---

## Change Summary

| Field | Value |
|-------|-------|
| **Change Type** | ADDED / MODIFIED / REMOVED / RENAMED |
| **Target** | [component / file / API endpoint affected] |

---

## Before State

> Required for MODIFIED and RENAMED change types. Describe the current state.

[Describe the current behavior, interface, or structure being changed]

## After State

> Describe the desired end state after this change is applied.

[Describe the new behavior, interface, or structure]

---

## Impact Assessment

> List all downstream components, APIs, tests, and documentation affected by this change.

| Affected Component | Impact Type | Details |
|--------------------|-------------|---------|
| [component] | [breaking / non-breaking / cosmetic] | [description] |

**Total files impacted:** [N]

---

## Justification

> Required for REMOVED change types. Explain why this removal is necessary.

[Rationale for the change — business driver, technical debt, security fix, etc.]

---

## Acceptance Criteria

| AC ID | Criterion | Verification Method |
|-------|-----------|---------------------|
| DAC-001 | [criterion] | [manual / automated test / review] |
| DAC-002 | [criterion] | [manual / automated test / review] |

---

## Architect Phase Skip Assessment

> Delta specs may skip the architect phase when ALL of these conditions are met:
> - Change type is MODIFIED or RENAMED
> - Impact scope ≤ 3 files
> - No new domain entities introduced
> - No cross-boundary changes
>
> If conditions are met, proceed directly to implementation after Gate 1 approval.

**Skip architect phase:** Yes / No
**Justification:** [explain why skip is or is not appropriate]

---

## Traceability

| Relation | Reference |
|----------|-----------|
| Parent Spec | [NNN]-[original-feature-slug] (if applicable) |
| Related ACs | [AC-NNN, AC-NNN] |
| Related Tasks | [T-NNN] |
