# SDD Evolution Module

> Framework self-improvement system — analyse external frameworks, harvest features, and plan Enterprise SDD improvements.

## Overview

The **sdd-evolution** module provides a complete meta-evolution workflow for Enterprise SDD. It enables teams to systematically track public AI agent frameworks, analyse their features, compare approaches, harvest improvements, and convert proposals into actionable implementation plans — all while respecting SDD's philosophy and design boundaries.

## Installation

```bash
sdd module install sdd-evolution
```

This creates the `_evolution/` directory for analysis files, comparisons, and evolution documents.

## Components

### Agents (12)

| Agent | Purpose | Model Tier |
|-------|---------|------------|
| `framework-analyst` | Analyse a single framework → produce ANALYSIS.md | deep |
| `framework-comparator` | Compare multiple frameworks → produce COMPARISON.md | deep |
| `framework-updater` | Pull latest repos, detect changes, update WHATSNEW.md | standard |
| `sdd-evolver` | Harvest features → propose improvements in EVOLUTION.md | deep |
| `evolution-planner` | Convert proposals → actionable implementation plans | standard |
| `module-designer` | Interactive design & scaffolding of new SDD modules | standard |
| `extension-designer` | Interactive design & scaffolding of new SDD extensions | standard |
| `agent-builder` | Create new `.agent.md` files or improve existing agents | standard |
| `instruction-builder` | Create shared `.instructions.md` files with `applyTo` patterns | standard |
| `guidance-builder` | Create `.guidance.md` documents with pros/cons/examples | standard |
| `prompt-builder` | Create `.prompt.md` templates composing agent chains | light |
| `workflow-builder` | Create `.yml` GitHub Actions workflows | light |

### Instructions (2)

| Instruction | Scope |
|-------------|-------|
| `sdd-philosophy` | Inviolable constraints, design boundaries, evaluation criteria |
| `framework-repos` | Canonical map of 9 tracked public framework repositories |

### Prompts (5)

| Prompt | Agent | Description |
|--------|-------|-------------|
| `analyse-framework` | framework-analyst | Analyse a framework directory |
| `compare-frameworks` | framework-comparator | Compare multiple ANALYSIS.md files |
| `evolve-sdd` | sdd-evolver | Harvest features and propose improvements |
| `design-module` | module-designer | Design and scaffold a new module |
| `design-extension` | extension-designer | Design and scaffold a new extension |

### Templates (3)

| Template | Purpose |
|----------|---------|
| `analysis-template.md` | 11-section structural skeleton for framework analyses |
| `comparison-template.md` | 5-section structural skeleton for framework comparisons |
| `evolution-section-template.md` | Format template for EVOLUTION.md harvest sections |

### Scaffolds (2)

| Scaffold | Contents |
|----------|----------|
| `module-scaffold/` | `module.json.template`, `agent.agent.md.template`, `README.md.template` |
| `extension-scaffold/` | `extension.json.template`, `README.md.template` |

## Typical Workflow

```
1. Update repos        →  @framework-updater pulls latest, updates WHATSNEW.md
2. Analyse frameworks  →  @framework-analyst produces *-ANALYSIS.md per framework
3. Compare frameworks  →  @framework-comparator produces COMPARISON.md
4. Harvest features    →  @sdd-evolver proposes improvements in EVOLUTION.md
5. Plan implementation →  @evolution-planner creates phased task plan in _plan/
6. Design new modules  →  @module-designer scaffolds new SDD modules
```

## File Structure

```
.sdd-modules/modules/sdd-evolution/
├── module.json
├── README.md
├── copilot-instructions-supplement.md
├── setup-module.sh
├── agents/
│   ├── framework-analyst.agent.md
│   ├── framework-comparator.agent.md
│   ├── framework-updater.agent.md
│   ├── sdd-evolver.agent.md
│   ├── evolution-planner.agent.md
│   ├── module-designer.agent.md
│   ├── extension-designer.agent.md
│   ├── agent-builder.agent.md
│   ├── instruction-builder.agent.md
│   ├── guidance-builder.agent.md
│   ├── prompt-builder.agent.md
│   └── workflow-builder.agent.md
├── instructions/
│   ├── sdd-philosophy.instructions.md
│   └── framework-repos.instructions.md
├── prompts/
│   ├── analyse-framework.prompt.md
│   ├── compare-frameworks.prompt.md
│   ├── evolve-sdd.prompt.md
│   ├── design-module.prompt.md
│   └── design-extension.prompt.md
├── templates/
│   ├── analysis-template.md
│   ├── comparison-template.md
│   └── evolution-section-template.md
└── scaffolds/
    ├── module-scaffold/
    │   ├── module.json.template
    │   ├── agent.agent.md.template
    │   └── README.md.template
    └── extension-scaffold/
        ├── extension.json.template
        └── README.md.template
```

## Output Directory

When installed, this module creates `_evolution/` at the project root:

```
_evolution/
├── EVOLUTION.md              ← Feature harvest document
├── WHATSNEW.md               ← Per-framework changelog
├── *-ANALYSIS.md             ← Individual framework analyses
└── *-COMPARISON*.md          ← Cross-framework comparisons
```

## Removal

```bash
sdd module remove sdd-evolution
```

> **Note:** Removal does not delete the `_evolution/` directory or its contents. Those files are project artifacts, not module files.

## Requirements

- Enterprise SDD v4.3 or later
- Module system enabled (`.sdd-modules/` directory present)
