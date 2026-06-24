---
name: sdd-architect
namespace: true
keyword-tags: [api, rest, openapi, messaging, kafka, async-event, architecture-decision, adr, boundary, hexagonal]
description: Phase 3 (Architect) namespace meta-skill — REST, async messaging, ADR, hexagonal.
---

# sdd-architect (namespace meta-skill)

Purpose: lightweight router for Phase 3 architecture work.

## When to Use

- Designing a new feature plan (Phase 3) and you need pattern guidance.
- Reviewing an existing plan before Gate 2.
- The user mentions API surface, messaging, or architectural decisions.

## Routed Sub-Skills

| Trigger keywords | Sub-skill | Purpose |
|------------------|-----------|---------|
| `api`, `rest`, `openapi`, `endpoint`, `versioning` | `api-patterns` | REST API decision framework |
| `kafka`, `event`, `message`, `topic`, `envelope`, `async` | `messaging-patterns` | Async messaging decision framework |
| `adr`, `architecture decision`, `record decision` | (planned `architecture-decision-records`) | ADR authoring (deferred — use plan template's ADR section) |
| `hexagonal`, `port`, `adapter`, `boundary` | (planned `boundary-design`) | Hexagonal boundary design (deferred — see PLAYBOOK § Hexagonal) |

## Invocation Guidance

1. Identify the integration surface (sync HTTP vs async events) and load the matching sub-skill.
2. For mixed-surface plans, load both `api-patterns` and `messaging-patterns`.
3. Defer ADR/boundary sub-skills to PLAYBOOK guidance until the dedicated skills land.

## Boundary

- Never override constitution conventions (path style, tenancy prefix, etc.) — sub-skills must defer to constitution.
- Never produce free-form prose where the plan template expects a structured table.
