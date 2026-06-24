# SDD Evolution Module — Copilot Context

This project has the **sdd-evolution** module installed. It provides a meta-evolution
workflow for Enterprise SDD — tracking public AI agent frameworks, analysing them,
and proposing improvements.

## Key Concepts

- **`_evolution/` directory** — Contains analysis files, comparison documents, WHATSNEW.md, and EVOLUTION.md. This is where all evolution artifacts live.
- **Framework analysis** — Each tracked public framework has a `*-ANALYSIS.md` file following an 11-section template.
- **Feature harvest** — New features from public frameworks are proposed in `EVOLUTION.md` after evaluation against SDD philosophy constraints.
- **Design boundaries** — 9 inviolable constraints govern what can and cannot be adopted. See `sdd-philosophy.instructions.md`.

## Module Agents

| Agent | When to Invoke |
|-------|---------------|
| `@framework-analyst` | Analysing a new or updated framework |
| `@framework-comparator` | Comparing multiple frameworks |
| `@framework-updater` | Refreshing tracked repos |
| `@sdd-evolver` | Proposing SDD improvements from framework analyses |
| `@evolution-planner` | Creating implementation plans from proposals |
| `@module-designer` | Designing new SDD modules |
| `@extension-designer` | Designing new SDD extensions |
| `@agent-builder` | Creating new `.agent.md` files or improving existing agents |
| `@instruction-builder` | Creating shared `.instructions.md` files with `applyTo` patterns |
| `@guidance-builder` | Creating `.guidance.md` documents with pros/cons/examples |
| `@prompt-builder` | Creating `.prompt.md` templates composing agent chains |
| `@workflow-builder` | Creating `.yml` GitHub Actions workflows |

## Important Files

- `instructions/sdd-philosophy.instructions.md` — Design constraints (read before proposing changes)
- `instructions/framework-repos.instructions.md` — Tracked repo map
- `templates/` — Structural skeletons for analyses, comparisons, and evolution sections
