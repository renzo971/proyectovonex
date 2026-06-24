---
description: Bootstrap a new project from scratch — runs the full SDD pipeline from Phase 0
mode: agent
---

Start a **new project** using the Enterprise SDD workflow.

## Steps

0. **Feature Directory**: Run `.specify/scripts/new-feature.sh 'feature-name'` to create the feature directory with templates.

1. **Phase 0 — Constitution**: Invoke `@constitution` to establish the project foundation.
   - Define project identity, tech stack, quality standards, architecture principles
   - Produces: `constitution.md`

2. **Phase 1 — Requirements**: Invoke `@requirement-analyst` in **Vision Mode**.
   - Capture high-level business context and user stories
   - Produces: `business-context.md`, `spec.md`

3. **Phase 1.3 — Clarification**: Invoke `@clarification` if ambiguities exist.
   - Produces: `clarifications.md`

4. **Phase 2 — Design**: Invoke `@architect` for technical design.
   - Produces: `plan.md`, `data-model.md`

5. Continue through the remaining phases as needed.

> **Tip:** For ideation before Phase 0, invoke `@brainstorming` first.
