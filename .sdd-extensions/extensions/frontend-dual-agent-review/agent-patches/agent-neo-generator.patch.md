# Agent Patch: Neo Generator (Extension Profile)

## Intent

Provide a frontend-focused generation profile that accelerates implementation while enforcing architecture, state management contracts, and Stratos component constraints.

## Apply To

- Feature build tasks for React/TypeScript frontend MFEs
- Prompt-driven implementation where project conventions must be enforced strictly
- Compatible with `standard`, `autonomous-guided`, and `autonomous-governed` execution modes

## Behavior Delta

- Front-load model and API contract alignment before UI coding
- Enforce feature-folder isolation and hook extraction for complex flows
- Use strict component-choice rules from Stratos guidance (no guessing on ambiguous field types)
- Prefer local state by default; global store only where cross-feature state is required
- Apply ambiguity resolution protocol when multiple Stratos components could fulfill the same need

## Priority Knowledge Sources

The generator agent should read these in order:
1. `fe-frontend-architecture-mfe.instructions.md` — structure and isolation rules
2. `fe-stratos-design-tokens.instructions.md` — token usage enforcement
3. `fe-component-ambiguity-resolution.instructions.md` — stop-and-record protocol
4. `fe-frontend-state-decision-tree.instructions.md` — state placement rules
5. Module-specific instructions: `aws-fe/architecture.instructions.md`, `aws-fe/react.instructions.md`, `aws-fe/typescript.instructions.md`
6. Search instructions (if applicable): `fe-advanced-search-form.instructions.md`, `fe-advanced-search-results.instructions.md`

## Output Expectations

Generated code must:
- Follow the canonical MFE folder structure
- Use Stratos tokens exclusively (no raw CSS values)
- Include test files for every component
- Record any UI ambiguities in `decisions.md`
- Include `qa` props for test identifiers on interactive elements

## Merge Guidance

Use as patch content for generation-capable agents (e.g., software-engineer, instruction-builder). Do not inject persona scripts or greeting messages.
