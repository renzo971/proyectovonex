---
name: 'evolve-sdd'
description: 'Harvest features from public frameworks and propose improvements for Enterprise SDD'
agent: 'sdd-evolver'
---

# Evolve Enterprise SDD

## Goal

Analyse the latest state of tracked public AI agent frameworks and propose improvements for Enterprise SDD by appending a new harvest section to `_evolution/EVOLUTION.md`.

## Process

1. Read current SDD capabilities (PLAYBOOK.md, REQUIREMENTS.md).
2. Read `_evolution/WHATSNEW.md` for recent framework changes.
3. Read relevant `_evolution/*-ANALYSIS.md` files for frameworks that changed.
4. Apply feature evaluation criteria from `sdd-philosophy.instructions.md`.
5. Draft proposals for accepted features and document rejected features.
6. Append new harvest section to `_evolution/EVOLUTION.md`.

## Output

Updated `_evolution/EVOLUTION.md` with a new numbered harvest section containing:
- Summary table of proposed features
- Detailed feature descriptions with priority, effort, and implementation approach
- "What NOT to Adopt" table with rejection rationale
