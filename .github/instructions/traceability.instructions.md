---
applyTo: ".specify/**"
description: Canonical traceability ID formats used across all SDD artifacts
---

## Traceability ID Standards

Use these canonical IDs:

- `US-XXX` for user stories
- `AC-XXX` for acceptance criteria
- `NFR-XXX` for non-functional requirements
- `EC-XXX` for edge cases
- `CQ-XXX` for clarification questions
- `TC-XXX` for test cases
- `TXXX` for tasks

## Core Rules

- Every AC links to a parent US.
- Every TC references at least one AC.
- Every Task references at least one US.
- Code comments include traceability IDs when they carry task-specific intent.
- IDs are unique within a feature and deleted IDs are never reused.

See [traceability-detail.instructions.md](traceability-detail.instructions.md) for the full format table, chain diagram, regex patterns, and confidence-calibration guidance.

