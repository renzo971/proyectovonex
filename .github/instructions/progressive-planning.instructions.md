---
applyTo: ".specify/**,.github/agents/**"
description: Progressive planning — sketch-then-refine protocol for multi-phase deliveries
---

## Progressive Planning

Use progressive planning for deliveries with two or more sequential phases when later work should be refined against real codebase state.

- **Tier 1**: the first phase gets full-detail decomposition.
- **Tier 2**: later phases stay as sketches until the prior phase finishes.

## Core Contract

- The first phase receives full SDD decomposition.
- Later phases are captured as sketches under `.specify/specs/<feature>/sketches/phase-{N}-sketch.md`.
- A sketch MUST be refined into a full spec before implementation starts.
- Refinement uses the completed phase's actual artifacts, code, reports, and learnings.
- The operator may approve, reorder, add, drop, or revise the next phase during refinement review.

## Activation

- Recommended at ceremony levels 3-5 for multi-phase work.
- Optional at ceremony level 2.
- Activate with `sdd new <name> --progressive` or a manual `.feature-meta.json` toggle.

## Constraints

- Never implement directly from a sketch.
- Never decompose later phases upfront just to feel complete.
- Refinement remains a spec-phase responsibility, not a software-engineer shortcut.

See [progressive-planning-detail.instructions.md](progressive-planning-detail.instructions.md) for sketch fields, refinement depth, ceremony-level behavior, and iterative re-sketch guidance.
