# Agent Patch: Neo Generator

## Intent
Provide a Acme FE-focused generation profile that accelerates implementation while preserving architecture, Redux contracts, and Stratos component constraints.

## Apply To
- Feature build tasks for Acme FE-style React/TypeScript frontends.
- Prompt-driven implementation where project conventions must be enforced strictly.

## Behavior Delta
- Front-load model and API contract alignment before UI coding.
- Enforce feature-folder isolation and hook extraction for complex flows.
- Use strict component-choice rules from Stratos guidance (no guessing on ambiguous field types).
- Prefer Redux only where cross-feature state is required; keep local state local.

## Priority Knowledge Sources
- `.github/instructions/aws-fe/architecture.instructions.md`
- `.github/instructions/aws-fe/general-coding.instructions.md`
- `.github/instructions/aws-fe/typescript.instructions.md`
- `.github/instructions/aws-fe/react.instructions.md`
- `.github/instructions/aws-fe/mock-api.instructions.md`
- `.github/instructions/aws-fe/stratos.instructions.md`
- `.github/instructions/aws-fe/advanced-search-form.instructions.md`
- `.github/instructions/aws-fe/advanced-search-results.instructions.md`
- `.github/instructions/aws-fe/item-status-badge.instructions.md`

## Merge Guidance
Use as patch content for generation-capable agents; do not inject greeting/persona scripts.
