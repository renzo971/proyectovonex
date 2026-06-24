---
applyTo: "**"
---

# Cost Tracking

After each meaningful agent execution, update `.specify/specs/<feature-id>/cost-log.json`.

Rules:
- Append one entry in `entries` with fields: `timestamp`, `agent`, `modelTier`, `model`, `inputTokens`, `outputTokens`, `estimatedCost`, `phase`.
- Keep `estimatedCost` in project currency units and round to 2 decimals.
- Recompute `totalCost` as the sum of all `estimatedCost` values in `entries`.
- Do not overwrite existing history entries unless correcting clearly invalid data.
- If `totalCost / budgetCeiling >= 0.8`, report a warning in your status output.

If token usage is unavailable from tooling, record best-effort estimates and mark assumptions in the activity notes.
