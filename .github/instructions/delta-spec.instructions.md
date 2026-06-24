---
applyTo: ".specify/specs/**/*delta*,.specify/templates/delta*"
description: "Use when: creating delta specifications, deciding between delta vs full spec, evaluating architect-phase skip criteria, reviewing delta spec completeness"
---

## Delta Specifications

### When to Use Delta vs. Full Spec

| Scenario | Use |
|----------|-----|
| New capability, new domain entities | Full spec |
| Modify/rename existing component (≤ 3 files) | Delta spec |
| Remove existing component | Delta spec (requires justification) |
| Add new endpoint to existing API | Delta spec if ≤ 3 files impacted |
| Cross-cutting change (> 3 files) | Full spec |

### Change Type Semantics

| Type | `before` required | `justification` required |
|------|:-:|:-:|
| ADDED | No | No |
| MODIFIED | Yes | No |
| REMOVED | No | Yes |
| RENAMED | Yes | No |

### Architect-Phase Skip Criteria

A delta spec may skip Phase 2 (Architecture) when **all** conditions are met:

1. Change type is **MODIFIED** or **RENAMED**
2. Impact scope ≤ **3 files**
3. No new domain entities introduced
4. No cross-boundary changes (all modifications within one component)

When skipping, proceed directly from Gate 1 to Phase 3 (Test Design) or
Phase 4 (Implementation) depending on complexity.

### Gate Validation

- **Gate 1:** validates delta template completeness — all required fields filled
  based on `change_type` (e.g., MODIFIED requires `before` field)
- **Gate 2:** verifies impact assessment covers all affected components
  (skipped if architect-phase skip is active)
