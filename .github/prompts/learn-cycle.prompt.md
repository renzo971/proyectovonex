---
description: Run a structured memory learn cycle for a feature
mode: agent
---

Run a **memory learn cycle** for feature `<feature-id>` and produce actionable updates.

Workflow:

1. Execute `sdd memory status <feature-id>` and summarize freshness/conflict indicators.
2. Execute `sdd memory doctor <feature-id>` and classify issues by severity.
3. If no blocking issues: execute `sdd memory sync <feature-id>`.
4. Update `analysis-report.md` with a short "Memory Lifecycle Status" summary.
5. Propose the next 3 actions to improve memory quality for the feature.

Output format:

- Current status (freshness score, stale files, unresolved conflicts)
- Doctor findings (if any)
- Sync outcome
- Recommended actions (3 items)

If doctor finds blocking contradictions, stop before sync and provide a remediation plan.
