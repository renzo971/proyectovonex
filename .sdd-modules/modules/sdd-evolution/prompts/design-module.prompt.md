---
name: 'design-module'
description: 'Interactively design and scaffold a new SDD module'
argument-hint: 'Module name (e.g., cost-optimizer, security-scanner)'
agent: 'module-designer'
---

# Design SDD Module

## Goal

Design and scaffold a new SDD module following the module system conventions.

## Context

### Module name

```text
$ARGUMENTS
```

## Process

1. **Gather requirements** — Ask about purpose, target phase, components needed, dependencies.
2. **Design structure** — Plan module.json, agents, instructions, prompts, templates, scaffolds.
3. **Present for approval** — Show the design to the user before scaffolding.
4. **Scaffold** — Generate all files in `.sdd-modules/modules/{name}/`.
5. **Validate** — Verify module.json completeness and cross-references.

## Output

A complete module scaffold in `.sdd-modules/modules/{name}/` with all files listed in `module.json`.
