---
name: sdd-specify
namespace: true
keyword-tags: [domain, vocabulary, acceptance-criteria, prfaq, requirement-decomposition, ambiguity, hidden-requirement, spec-review]
description: Phase 1 (Specify) namespace meta-skill — routes to the right specification sub-skill.
---

# sdd-specify (namespace meta-skill)

Purpose: lightweight router for Phase 1 specification work. Loaded eagerly at cold-start; routes to one or more sub-skills only when their trigger keywords appear in the active context.

## When to Use

- Starting a new feature spec (Phase 1) and you need decision support.
- Reviewing a draft spec before Gate 1.
- The user mentions ambiguity, missing acceptance criteria, or requirement decomposition.

## Routed Sub-Skills

| Trigger keywords | Sub-skill | Purpose |
|------------------|-----------|---------|
| `brief`, `brain-dump`, `intake`, `kernel`, `distil`, `seed spec` | `intent-kernel` | Distil raw input into a 5-field intent kernel to seed Phase 1 spec (Wave 27 §26 #4) |
| `prfaq`, `working-backwards`, `idea`, `pre-spec` | `prfaq-working-backwards` | Pre-spec PRFAQ + assumption ledger |
| `spec-review`, `acceptance-criteria checklist` | `sdd-spec-review` | Structured spec review |
| `red-team`, `assumption`, `adversarial review` | `red-team-spec` | Adversarial spec review |
| `ambiguity`, `score`, `vague`, `quality gate` | `sdd-ambiguity-score` | Score and surface ambiguity hotspots |
| `pattern`, `recurring`, `cluster` | `pattern-analyze` | Surface recurring patterns across specs |
| `hidden`, `implicit`, `assumed` requirement | `hidden-requirement-scan` | Surface implicit requirements (Wave 23 §C) |

## Invocation Guidance

1. Match the strongest trigger in the active task.
2. Load only one sub-skill per turn unless the user explicitly opts in to chaining.
3. If no trigger matches strongly, defer to the agent's own judgment — do not load any sub-skill.

## Boundary

- Never duplicate sub-skill content here. This file is a router, not a catalog.
- Never bypass Gate 1 by promising what a sub-skill cannot deliver.
