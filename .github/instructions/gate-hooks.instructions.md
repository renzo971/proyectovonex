---
applyTo: ".specify/**,.github/agents/**"
description: Post-gate automation hooks — declarative actions triggered after gate passage
---

## Gate Hooks

Hooks automate post-gate actions after validation passes or fails without weakening gate integrity.

## Hook Types

`notify`, `auto-commit`, `trigger-next`, `export-report`, `skill-eval-verify`, and `post-merge-verify` are configured under `.feature-meta.json -> gateHooks` per gate.

## Core Rules

- Hooks run only after gate validation.
- Failed hooks are warnings, not gate reversals.
- Hooks execute in declared order.
- Hooks never bypass gates or mutate primary artifacts.

## Mode Behavior

- `standard`: operator opts in with `sdd gate <id> <N> --hooks`
- `autonomous-guided` and `autonomous-governed`: hooks auto-execute per configuration

See [gate-hooks-detail.instructions.md](gate-hooks-detail.instructions.md) for config schema, auto-commit format, trigger-next mapping, CLI examples, and the `skill-eval-verify` / `post-merge-verify` hook contracts.
