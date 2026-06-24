# Enterprise SDD — Global Copilot Instructions

> These instructions are automatically loaded into every Copilot Chat session.
> They provide the baseline context that all SDD agents, prompts, and skills rely on.

## Framework Identity

You are operating inside an **Enterprise SDD** (Spec-Driven Development) project.
All work follows a constitution-first, gate-driven, agent-based workflow.

## Agent Folder

All 15 core development agents live in `.github/agents/`. Invoke them via `@agent-name`.
Core lifecycle agents: `@constitution`, `@requirement-analyst`, `@clarification`,
`@architect`, `@api-champion`, `@messaging-champion`, `@test-explorer`,
`@gherkin-analyst`, `@test-engineer`, `@software-engineer`, `@review`, `@analysis`.
Specialized: `@brainstorming`, `@refactoring`, `@tech-context-maintainer`.
Meta-builder agents (`@agent-builder`, `@instruction-builder`, `@prompt-builder`,
`@guidance-builder`, `@workflow-builder`) are provided by the **sdd-evolution** module.

## Constitution-First Protocol

1. **Before any implementation**, read the project constitution at `.specify/memory/constitution.md`.
2. The constitution defines non-negotiable principles (Articles I–VI). Never violate them.
3. When in doubt, cite the relevant Article to justify a decision.

## Session Startup Checklist

At the start of every session:
1. Check active feature context: `.specify/memory/active-context.json`
2. Read the constitution if not already in context
3. Load the relevant feature spec from `.specify/specs/{feature-id}/`
4. Check session state: `.specify/memory/session-state.md`

## Quality Gates

Four mandatory gates enforce phase boundaries:
- **Gate 1** — Spec completeness (US, AC, business context filled)
- **Gate 2** — Design completeness (architecture, API contracts, test cases)
- **Gate 3** — Implementation readiness (tasks, code, unit tests)
- **Gate 4** — Ship readiness (review, integration tests, checklist)

Never skip a gate. Use `sdd gate check <gate> -f <feature-id>` to validate.

## Anti-Pattern Summary

- **Never** generate placeholder code or stub implementations without flagging them
- **Never** skip traceability (US → AC → TC → Task → Code)
- **Never** modify the constitution without explicit team approval
- **Never** bypass a quality gate, even in low-ceremony mode
- **Never** hardcode domain knowledge in agents — use constitution or `.instructions.md`
- **Never** perform orphan cleanup without confirming the file is truly unused

## Context-Window Discipline

- Keep prompts focused — one phase, one feature at a time
- Use context bridges (`.specify/bridges/`) to compress handoffs between phases
- Prefer `sdd bridge <feature-id>` to generate a context bridge before switching phases
- When context grows large, summarize decisions and continue with the bridge

## Key Paths

| Path | Purpose |
|------|---------|
| `.specify/` | All SDD framework files (templates, schemas, scripts, CLI) |
| `.specify/memory/` | Persistent memory (constitution, decisions, session state) |
| `.specify/specs/{id}/` | Per-feature specification artifacts |
| `.specify/bridges/` | Context bridge files for phase transitions |
| `.github/agents/` | Agent definition files |
| `.github/instructions/` | Shared instruction files (14 total) |
| `.github/prompts/` | Prompt files for common workflows (27 total) |
| `.github/skills/` | Curated skill descriptors |
| `.sdd-modules/` | Installable tech-stack knowledge modules |
| `.sdd-extensions/` | Lifecycle/feature extension packs |
