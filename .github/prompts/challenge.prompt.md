---
description: Challenge assumptions in the current design before implementation.
mode: agent
---

Invoke `@analysis` in challenge mode on the active feature.

## Steps

1. Read `spec.md`, `plan.md`, and `tasks.md` for the selected feature.
2. Identify explicit and implicit assumptions.
3. Falsify assumptions with edge cases and counterexamples.
4. Score confidence (1-5) and classify risk (`low|medium|high|critical`).
5. Propose safer alternatives for `high` and `critical` items.

Output must include sections: Assumptions, Counter-Evidence, Confidence Scores, Risk Levels, Safer Alternatives.
