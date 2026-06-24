---
applyTo: ".specify/**"
description: Adaptive ceremony levels that control agent depth based on feature complexity
---

## Ceremony Levels

Read `.specify/specs/<feature>/.feature-meta.json` before producing output and use `ceremonyLevel` to set workflow depth.

| Level | Use When | Core Behavior |
|-------|----------|---------------|
| **ultra-light** | bug fix, typo, config change | abbreviated artifacts and relaxed gate depth |
| **standard** | typical feature | full pipeline and normal gates |
| **full** | architecture, security, or cross-team change | full pipeline plus stricter review and clarification |

## Core Rules

- Agents and scripts must read `ceremonyLevel` before deciding depth.
- Ultra-light may abbreviate the workflow but does not skip correctness.
- Full ceremony requires stricter review, clarification, and low-confidence cleanup.

See [ceremony-level-checklists.instructions.md](ceremony-level-checklists.instructions.md) for per-level artifact expectations, gate behavior, and context-budget guidance.

## Ceremony-Gated Features

Some SDD capabilities are **off by default** and activated only at the `full` ceremony level:

| Feature | Level required | Where documented |
|---------|---------------|-----------------|
| Per-task verification checkpoint (Wave 27 §26 #7) | `full` | `software-engineer.agent.md` § Per-Task Verification Checkpoint |

> **Rationale:** Proportional ceremony (§15) keeps overhead low for the majority of work while allowing full discipline for high-risk delivery without changing the underlying mechanics.
