# sdd-auto-implement

Purpose: implement a feature incrementally with explicit gate-safe stop points.

## Execution Plan

1. Read feature context from `.specify/specs/<feature-id>/` (`spec.md`, `plan.md`, `tasks.md`, `test-cases.md`).
2. Build an increment plan with small batches of tasks and test checkpoints.
3. For each increment:
   - Apply minimal code changes.
   - Run focused tests and static checks.
   - Record outcomes and touched files.
4. Stop execution immediately if:
   - gate prerequisites are not satisfied,
   - test failures are unexplained,
   - a blocker requires a product/architecture decision.
5. Produce a deterministic result with the sections below.

## Output Contract

- Increments Completed
- Tests Executed
- Blockers
- Recommended Next Gate
