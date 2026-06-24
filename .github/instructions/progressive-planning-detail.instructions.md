---
applyTo: ".specify/**"
description: Detailed sketch fields, refinement depth, and ceremony-level behavior for progressive planning
---

# Progressive Planning Detail

See [progressive-planning.instructions.md](progressive-planning.instructions.md) for the core contract.

## Sketch Fields

Each phase sketch should capture:
- goal
- key dependencies
- risk assessment
- rough acceptance-criteria count
- scope boundaries

Do not include detailed task decomposition or full test cases at sketch time.

## Refinement Depth

When a prior phase completes:
1. read the next sketch
2. load current codebase state, reports, and learnings
3. refine the sketch into full US, AC, TC, and task decomposition
4. let the operator approve, reorder, add, drop, or revise the next phase

## Ceremony-Level Behavior

- level 2: optional
- level 3: recommended
- level 4: recommended with architecture review
- level 5: mandatory for multi-phase work

## Iterative Re-Sketch

If refinement invalidates the original sketch, mark what changed, write a short replacement sketch for the affected scope, and continue from the updated baseline.
