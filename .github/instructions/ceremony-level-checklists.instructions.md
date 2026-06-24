---
applyTo: ".specify/**"
description: Per-level artifact expectations, gate depth, and context-budget guidance for ceremony levels
---

## Ceremony Level Checklists

See [ceremony-levels.instructions.md](ceremony-levels.instructions.md) for the level-selection contract.

## How to Read the Level

Scripts and agents should read `.specify/specs/<feature>/.feature-meta.json` and default to `standard` if `ceremonyLevel` is missing.

## Agent Behavior

- **ultra-light:** skip business-context and clarifications, allow a brief spec, allow flat tasks, shorten review, and keep ship checks focused on correctness.
- **standard:** run the full documented pipeline with normal templates and gates.
- **full:** require clarification, architecture review before Gate 2, stricter ship checks, extended review focus, and resolution of low-confidence findings before shipping.

## Gate Behavior

- **ultra-light:** Gate 4 uses relaxed artifact checks.
- **standard:** all gates run with normal behavior.
- **full:** all gates run strictly and tolerate no unresolved warnings.

## Context Budget

- **ultra-light:** load only the minimum artifacts needed for the current task.
- **standard:** prefer the compiled context cache first.
- **full:** load the full artifact set; if trimmed, prioritize context bridge, spec, plan, tests, then tasks.

Use `sdd context compile --feature <id>` to build the cached feature context file when repeated sessions need a thinner starting point.
