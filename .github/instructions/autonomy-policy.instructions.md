---
applyTo: ".specify/**,.github/agents/**,.github/prompts/**"
description: Autonomy policy — runtime contract for bounded autonomous execution cycles
---

## Autonomy Policy

All autonomous-guided and autonomous-governed execution MUST stay inside policy, budget, provenance, and gate constraints. Standard mode is unaffected.

## Modes

| Mode | Contract |
|------|----------|
| `standard` | Human-driven flow; no autonomous execution. |
| `autonomous-guided` | One bounded item per cycle with explicit operator approval between cycles. |
| `autonomous-governed` | One bounded item per cycle inside policy and evidence rules. |

## Core Cycle Rules

- Read persisted state from files only.
- Select exactly one eligible item.
- Record intent before changing code.
- Execute and verify that one item only.
- Persist evidence, result, and next action.
- Stop the cycle and resume only from a fresh process.

## Hard Boundaries

- Never bypass gates, modify the constitution, rewrite history, or change more than one item per cycle.
- Never carry session context between autonomous cycles.
- Stop and escalate on blockers, contradictions, low confidence, exhausted budget, or failing tests without a bounded repair path.

See [autonomy-evidence.instructions.md](autonomy-evidence.instructions.md) for evidence blocks, stop conditions, rollback behavior, and required operator diagnostics.
