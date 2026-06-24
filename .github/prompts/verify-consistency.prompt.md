---
description: Run consistency analysis to verify traceability across all artifacts
mode: agent
---

**Run consistency analysis** across all specification artifacts.

Invoke `@analysis` to verify:

- Every US-XXX in spec.md has a corresponding design section in plan.md
- Every AC-XXX has at least one TC-XXX in test-cases.md
- Every TC-XXX has a corresponding test file in tests/
- Every TXXX in tasks.md has a corresponding source file in src/
- No orphaned items (tests without requirements, code without tasks)
- No contradictions between artifacts

The analysis agent will produce one of three verdicts:
- **PASS** — all cross-references valid
- **PASS WITH WARNINGS** — minor issues, non-blocking
- **FAIL** — critical traceability gaps found
