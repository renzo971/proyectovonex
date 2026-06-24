---
description: Convert approved design and tasks into an incremental implementation plan.
mode: agent
---

Invoke `@software-engineer` to create execution increments for the active feature.

## Steps

1. Read `plan.md`, `tasks.md`, and `test-cases.md`.
2. Group tasks into small, testable increments.
3. For each increment, define test commands, rollback condition, and done criteria.
4. Mark gate boundary checkpoints where execution must pause.

Output must include sections: Increment Plan, Test Checkpoints, Gate Boundaries, Rollback Triggers.
