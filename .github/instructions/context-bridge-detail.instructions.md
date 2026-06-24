---
applyTo: ".specify/**,.github/agents/**"
description: "Companion detail for context-bridge — fix_attempt_count field schema, lifecycle, and escalation thresholds"
---

## Fix Attempt Tracking — `fix_attempt_count` (Detail)

### Field Definition

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `fix_attempt_count` | integer | 0 | Number of consecutive fix attempts for the current task without test improvement |

### Lifecycle

- **Increment:** Each time the implementer modifies files for the same task without new
  tests passing or existing failures resolving, `fix_attempt_count` increments by 1.
- **Reset:** When the test suite shows measurable improvement (a new test passes, or a
  previously failing test now passes), `fix_attempt_count` resets to 0.
- **Persist:** The count is stored in `context-bridge.md` metadata so it survives across
  conversation sessions.

### Example in context-bridge.md

```yaml
current_task: T004
fix_attempt_count: 2
last_test_improvement: "2026-05-12T10:30:00Z"
files_modified_this_attempt:
  - src/modules/order/order.service.ts
  - src/modules/order/order.repository.ts
```

### Escalation Thresholds

| Threshold | Action |
|-----------|--------|
| `fix_attempt_count ≥ 3` | Auto-trigger escalation protocol (Wave 18) with loop-pattern summary — files modified, tests failing, attempts made |
| `fix_attempt_count ≥ 5` | Recommend task redesign — "Task may need architectural decomposition — approach is not converging" |
