---
description: Lazy phase-prompt loader — given an SDD phase number, loads only the prompts needed for that phase.
mode: agent
---

# sdd-phase-loader

Wave 23 §23.A.27 — reduce cold-start prompt cost by loading **only** the
prompts relevant to the current SDD phase.

## Inputs

- `<phase>` — one of `0`, `1`, `2`, `2.1`, `3`, `3.1`, `4`, `5`.
- (Optional) `<feature-id>` — if present, infer the phase from
  `.specify/specs/<feature-id>/state.json` (key `phase`).

## Phase → Prompt Routing

| Phase | Load these prompts |
|------:|--------------------|
| 0 | `new-project.prompt.md` |
| 1 | `new-project.prompt.md`, `challenge-me.prompt.md` |
| 2 | `clarify.prompt.md`, `verify-consistency.prompt.md` |
| 2.1 | `clarify.prompt.md` |
| 3 | `plan-implementation.prompt.md`, `convergence-review.prompt.md` |
| 3.1 | `plan-implementation.prompt.md` |
| 4 | `implement-feature.prompt.md`, `autonomous-implement.prompt.md`, `quick-fix.prompt.md` |
| 5 | `review-code.prompt.md`, `review-functional.prompt.md`, `assert-quality.prompt.md`, `ship-review.prompt.md`, `release-triad-synthesis.prompt.md` |

Cross-phase utilities (`debug-5-whys`, `reproduce-bug`, `retrospective`,
`spike`, `convergence-review`) are **not** auto-loaded — invoke them
explicitly when needed.

## Behaviour

1. Resolve the phase: from the explicit argument, else from `state.json`.
2. Reference each routed prompt with `@.github/prompts/<name>.prompt.md`
   (do not inline-quote — keep the cold-start surface minimal).
3. Surface a one-line confirmation: "Loaded N phase-`<phase>` prompts (skipped M)".
4. If the phase is unknown, emit a WARN and load `new-project.prompt.md` as a safe default.

## Boundary

- Never load prompts outside the table above without explicit user opt-in.
- Never replace the routed prompts' content here — this file is a router.
- Falls back gracefully when `state.json` is absent (assumes the agent will be told the phase).
