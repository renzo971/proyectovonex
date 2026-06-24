# Prompt Library — Catalog

> **Last updated:** April 17, 2026
> **Total:** 27 prompt files

All prompts are in `.github/prompts/` and can be invoked via `sdd spell <name>` or directly from the IDE prompt picker.

## Full Lifecycle Prompts

| Prompt | Phase | Purpose |
|--------|-------|---------|
| `new-project.prompt.md` | 0–5 | Bootstrap a new project from scratch — full SDD pipeline from Phase 0 |
| `crud-feature.prompt.md` | 0–5 | Standard CRUD feature — full lifecycle from requirements to implementation |
| `api-only.prompt.md` | 0–5 | API-only feature — define and implement REST endpoints without messaging |
| `event-only.prompt.md` | 0–5 | Event-driven feature — async messaging with no direct API endpoints |

## Phase 0 — Foundation & Brainstorming

| Prompt | Purpose |
|--------|---------|
| `brainstorm.prompt.md` | Brainstorm ideas and explore the solution space before committing to specs |
| `scaffold-project.prompt.md` | Scaffold a new project from constitution |

## Phase 1 — Requirements

| Prompt | Purpose |
|--------|---------|
| `requirements-from-issue.prompt.md` | Import requirements from a Jira issue or Confluence page via MCP tools |
| `clarify.prompt.md` | Ask clarification questions about requirements, design, or implementation |
| `bdd-scenarios.prompt.md` | Create BDD/Gherkin test scenarios from user stories |

## Phase 4 — Implementation

| Prompt | Purpose |
|--------|---------|
| `implement-feature.prompt.md` | Implement a feature from existing specification artifacts |
| `plan-implementation.prompt.md` | Convert approved design and tasks into an incremental implementation plan |
| `autonomous-implement.prompt.md` | Execute one bounded autonomous implementation cycle following the autonomy policy |
| `quick-fix.prompt.md` | Quick fix or hotfix — minimal-scope change with targeted testing |

## Phase 5 — Quality & Review

| Prompt | Purpose |
|--------|---------|
| `assert-quality.prompt.md` | Assert quality readiness against constitution and gate criteria |
| `review-functional.prompt.md` | Review feature behavior from functional and user-value perspective |
| `review-code.prompt.md` | Review code changes for maintainability, safety, and constitution alignment |
| `ship-review.prompt.md` | Ship-readiness review — final quality gate before production |
| `verify-consistency.prompt.md` | Run consistency analysis to verify traceability across all artifacts |
| `test-journey.prompt.md` | Build end-to-end journey tests from spec and design artifacts |

## Diagnostic & Analysis

| Prompt | Purpose |
|--------|---------|
| `challenge.prompt.md` | Challenge assumptions in the current design before implementation |
| `challenge-me.prompt.md` | Challenge proposals with constructive criticism and alternative approaches |
| `debug-5-whys.prompt.md` | Debug an issue using a strict 5-Whys chain with evidence |
| `reproduce-bug.prompt.md` | Produce deterministic bug reproduction steps and diagnostics |
| `drift-check.prompt.md` | Check for drift between code, specs, and constitution |
| `clean-up.prompt.md` | Deep code cleanup — remove dead code, fix inconsistencies, improve quality |

## Learning & Memory

| Prompt | Purpose |
|--------|---------|
| `learn-cycle.prompt.md` | Run a structured memory learn cycle for a feature |
| `retrospective.prompt.md` | Run a structured retrospective after a feature is shipped |
