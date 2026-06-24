---
description: Implement a feature from existing specification artifacts
mode: agent
---

**Implement the feature** defined in the specification artifacts.

## Wave 23 §23.B.2 — Constitution Re-Injection (mandatory)

> **Before any other step**, the implementing agent must re-read the project
> constitution. The constitution loaded in Phase 0 has likely drifted out of
> context by the time implementation begins; re-injecting it at write time
> closes the governance gap surfaced by Spec Kit v0.8.6.

Open and read in full: `@file:.specify/memory/constitution.md`

Surface the 7 articles as a checklist in your first response, then verify that
each artifact you are about to write honours each article. Ask before guessing
when an article is silent.

## Steps

1. Read the spec artifacts to understand feature requirements:
   - `spec.md` — user stories and acceptance criteria
   - `plan.md` — architecture and design decisions
   - `data-model.md` — domain model
   - `test-cases.md` — test strategy
   - `tasks.md` — task breakdown

2. Follow TDD:
   - Invoke `@test-engineer` to write failing tests first (Red phase)
   - Invoke `@software-engineer` to implement code that passes tests (Green phase)

3. Verify traceability:
   - Every test references TC-XXX, US-XXX, AC-XXX
   - Every source file references TXXX
   - Code comments include traceability markers

4. Run `@review` when implementation is complete.
