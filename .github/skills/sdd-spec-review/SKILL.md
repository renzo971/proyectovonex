# sdd-spec-review

Purpose: verify that a pull request or code diff fully satisfies the feature's specification,
acceptance criteria, and test-case coverage before the review agent issues final approval.

## Execution Plan

1. Locate the feature spec directory: `.specify/specs/<feature-id>/`.
2. Load the specification baseline:
   - `spec.md` — all User Stories (US-NNN) and their Acceptance Criteria (AC-NNN)
   - `test-cases.md` — all TCs prefixed `TC-NNN`
   - `plan.md` — architecture contracts (API shapes, component boundaries)
3. Obtain the change surface from one of:
   - The inline diff passed to this skill, OR
   - `git diff main...HEAD` if invoked from the CLI (`sdd skill run sdd-spec-review <feature-id>`)
4. For each AC, assess:
   - Is there at least one code change that directly implements it?
   - Is there at least one TC mapped to it?
   - Is that TC present in the test suite (file + test name)?
5. For each TC:
   - Verify it is runnable (not only a TODO stub unless explicitly flagged `[stub]`).
   - Map it back to one or more ACs.
6. Check API/contract compliance:
   - Diff must not introduce breaking changes to interfaces defined in `plan.md`.
7. Compile a coverage matrix and verdict.

## Output Contract

- **Coverage Matrix** — table of AC ↔ TC ↔ Code; columns: `AC`, `TC`, `Code File`, `Status`
- **Uncovered ACs** — list of ACs with no code change and/or no TC
- **Stub-Only TCs** — list of TCs that exist only as stubs
- **Contract Violations** — any API/interface deviations from `plan.md`
- **Verdict** — `PASS` | `PASS WITH WARNINGS` | `FAIL`
- **Recommended Action** — one sentence on what to do next
