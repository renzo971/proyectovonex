---
name: 'design-extension'
description: 'Interactively design and scaffold a new SDD extension'
argument-hint: 'Extension name (e.g., cost-tracker, pr-reviewer)'
agent: 'extension-designer'
---

# Design SDD Extension

## Goal

Design and scaffold a new SDD extension — a lightweight single-purpose addition to Enterprise SDD.

## Context

### Extension name

```text
$ARGUMENTS
```

## Process

1. **Gather requirements** — Ask about purpose, target phase, and which optional files are needed.
2. **Design structure** — Plan extension.json, agent, and support files.
3. **Present for approval** — Show the design before scaffolding.
4. **Scaffold** — Generate all files in `.sdd-modules/extensions/{name}/`.
5. **Validate** — Verify extension.json completeness.

## Output

A complete extension scaffold in `.sdd-modules/extensions/{name}/`.
