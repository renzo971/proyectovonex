# memory-loop

Purpose: keep structured memory healthy before gate execution.

## Steps

1. Run `sdd memory status <feature-id>`.
2. Run `sdd memory doctor <feature-id>`.
3. If doctor passes, run `sdd memory sync <feature-id>`.
4. Re-run `sdd memory status <feature-id>` and confirm freshness >= 80.

## Output Contract

- Memory status report showing freshness score
- Doctor diagnostic result (PASS/FAIL)
- Sync completion confirmation with drift/conflict summary
