# traceability-audit

Purpose: detect requirement-to-task/test drift before Gate 3.

## Steps

1. Verify US coverage in plan.md.
2. Verify task references (Txx -> US/AC links).
3. Verify test references (TC-xx -> US/AC links).
4. Run `sdd report <feature-id>`.

## Output Contract

- US coverage percentage
- Task-to-requirement traceability matrix
- Test-to-requirement traceability matrix
- Gap report listing uncovered requirements
