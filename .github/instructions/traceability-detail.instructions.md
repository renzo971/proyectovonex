---
applyTo: ".specify/**"
description: Full traceability format table, chain diagram, regex patterns, and confidence calibration guidance
---

# Traceability Detail

See [traceability.instructions.md](traceability.instructions.md) for the core contract.

## Format Table

| ID Type | Format | Example | Used In |
|---------|--------|---------|---------|
| User Story | `US-XXX` | `US-001` | `spec.md` |
| Acceptance Criterion | `AC-XXX` | `AC-001` | `spec.md` |
| Non-Functional Requirement | `NFR-XXX` | `NFR-001` | `spec.md` |
| Edge Case | `EC-XXX` | `EC-001` | `spec.md`, `clarifications.md` |
| Clarification Question | `CQ-XXX` | `CQ-001` | `clarifications.md` |
| Test Case | `TC-XXX` | `TC-001` | `test-cases.md` |
| Task | `TXXX` | `T001` | `tasks.md` |

## Traceability Chain

```text
US-XXX -> AC-XXX -> TC-XXX -> test file
US-XXX -> TXXX -> source file
US-XXX -> NFR-XXX / EC-XXX / design section
```

## Gate Patterns

- User stories: `/^#{2,4}\s+US-\d{3}/`
- Acceptance criteria: `/AC-\d{3}/`
- NFRs: `/NFR-\d{3}/`
- Test cases: `/^#{3,4}\s+TC-\d{3}/`
- Tasks: `/T\d{3}/`
- Clarifications: `/CQ-\d{3}/`

## Confidence Calibration

Use `High` for direct evidence, `Medium` for supported inference, and `Low` for assumptions that still need human review.
