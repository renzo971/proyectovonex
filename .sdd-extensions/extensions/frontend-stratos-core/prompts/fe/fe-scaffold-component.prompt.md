---
mode: agent
description: "Scaffold a new Stratos-styled React component following MFE conventions"
---
# Scaffold Stratos Component

You are scaffolding a new React component for a Stratos-based MFE frontend.

## Instructions

Read the following before generating:
- `.github/instructions/fe/stratos.instructions.md` for component API
- `fe-stratos-design-tokens.instructions.md` for token usage
- `fe-frontend-architecture-mfe.instructions.md` for folder placement
- `fe-component-ambiguity-resolution.instructions.md` for UI decisions

## Input

Provide:
1. **Component name** (PascalCase)
2. **Purpose** (one sentence)
3. **Location** — shared (`client/components/`) or feature-specific (`pages/<Feature>/components/`)
4. **Key props** (list the main inputs)

## Output

Generate:
1. Component file (`<Name>.tsx`) with:
   - TypeScript interface for props
   - Stratos layout primitives (VerticalFlex, HorizontalFlex) with token-based spacing
   - Proper Stratos component usage (no raw HTML when a Stratos equivalent exists)
   - `qa` prop for test identifiers
2. Test file (`<Name>.test.tsx`) with:
   - Render test
   - Key interaction tests
   - Accessibility check (if applicable)
3. Index barrel export update

## Constraints

- Use Space enum for all spacing, Color for all colors
- Use Stratos typography components, not raw `<h1>`/`<p>`
- If a UI choice is ambiguous (e.g., Select vs. Autocomplete), STOP and apply the ambiguity resolution protocol
