---
name: sdd-implement
namespace: true
keyword-tags: [tdd, red-green-refactor, hotspot, hexagonal, commit, git, micro-task, verification]
description: Phase 4 (Implement) namespace meta-skill — TDD, hotspot review, commit hygiene.
---

# sdd-implement (namespace meta-skill)

Purpose: lightweight router for Phase 4 implementation work.

## When to Use

- Picking up a task from `tasks.md` and you need a methodology refresher.
- Reviewing a diff before pushing.
- The user mentions TDD, refactoring, or commit discipline.

## Routed Sub-Skills

| Trigger keywords | Sub-skill | Purpose |
|------------------|-----------|---------|
| `auto-implement`, `incremental`, `gate-safe` | `sdd-auto-implement` | Incremental implementation with gate-safe stop points |
| `hotspot`, `risk`, `churn`, `complexity` | `hotspot-review` | Composite-risk classification of the diff |
| `tdd`, `red-green`, `red green refactor`, `failing test` | (uses `tdd-enforce` instruction) | TDD enforcement is in `tdd-enforce.instructions.md` |
| `commit`, `git`, `rebase`, `squash` | (uses `git-commit-discipline` PLAYBOOK section) | Commit hygiene per PLAYBOOK § Commit Discipline |
| `hexagonal`, `port`, `adapter` | (uses architect plan + plan template) | Implement per the plan's hexagonal boundary |

## Invocation Guidance

1. Default to `sdd-auto-implement` for normal task execution.
2. Load `hotspot-review` when reviewing a diff > 200 LoC or touching a known hotspot.
3. Tdd enforcement is mandatory and lives in the `tdd-enforce` instruction — do not duplicate.

## Boundary

- Never skip gates by claiming a sub-skill grants autonomy — autonomy is governed by `autonomy-policy`.
- Never reformat existing code beyond the task scope (anti-pattern Rule 6: orphan-cleanup precision).
