---
applyTo: ".github/agents/**"
description: Lint checklist referenced by sdd-agent-lint skill — defines structural quality rules for agents and instructions
---

# Agent & Instruction Lint Checks

## Agent Structural Requirements

### Frontmatter (Required)
- `name`: Human-readable name
- `description`: One-paragraph purpose
- `tools`: List of allowed tools
- `phase`: SDD phase (e.g., "1", "3.2/4B", "5")

### Recommended
- `recommended-tier`: `light`, `standard`, or `extended`
- `model-tier`: `light`, `standard`, or `extended`
- `instructions`: Explicitly referenced instruction files

### Handoff Rules
- Every handoff MUST have `send: false`
- Reference target agents by filename stem

### Boundary Sections (Required)
Every agent MUST define: **Always Do** (≥2 items), **Ask First** (≥1), **Never Do** (≥2). Concrete and auditable.

**Size Budget Tiers:** compact ≤200 lines, standard ≤400, extended ≤600.

## Instruction Structural Requirements

### Frontmatter (Required)
- `applyTo`: Glob pattern defining activation scope

### Content Rules
- Actionable rules, not just descriptions
- ≥100 characters of content (not a stub)
- Imperative language: "Do X", "Never Y", "Always Z"
- File: `{lowercase-kebab-case}.instructions.md`
