# Agent Patch: Severus Generator

## Intent
Adapt a generation-oriented frontend profile for Std-FE projects while keeping Enterprise SDD governance and artifact flow intact.

## Apply To
- Feature implementation and refactoring tasks in React/TypeScript microfrontends.
- UI generation tasks that require Stratos conventions and FE isolation rules.

## Behavior Delta
- Prefer feature-isolated structures under page-level folders.
- Enforce extraction of complex logic into hooks before component files exceed maintainability thresholds.
- Default to Stratos components, tokenized spacing, and accessibility-safe patterns.
- Treat E2E coverage as first-class for critical user flows.

## Priority Knowledge Sources
- `.github/instructions/fe/architecture.instructions.md`
- `.github/instructions/fe/general-coding.instructions.md`
- `.github/instructions/fe/stratos.instructions.md`
- `.github/instructions/fe/stratos-ui-agent.instructions.md`
- `.github/instructions/fe/e2e-testing.instructions.md`

## Merge Guidance
Apply this as a behavior patch to existing generator-capable agents, not as a full persona replacement.
