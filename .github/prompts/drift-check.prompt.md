---
description: Check for drift between code, specs, and constitution
mode: agent
---

**Check for drift** between the codebase and specification artifacts.

Invoke `@tech-context-maintainer` to run a drift analysis:

- Code vs spec.md — are all user stories implemented?
- Code vs plan.md — does architecture match the design?
- Code vs openapi.yaml — do endpoints match the contract?
- Code vs asyncapi.yaml — do events match the schema?
- Code vs constitution — are architecture principles followed?

The agent will produce a `drift-report.md` with:
- Categorized findings (undocumented feature, stale spec, constitution violation, etc.)
- Severity classification (CRITICAL / HIGH / MEDIUM / LOW)
- Recommended actions for each finding

> **Modes:** Use "full drift analysis" for comprehensive check,
> "check recent changes" for incremental, or "check API drift" for targeted.
