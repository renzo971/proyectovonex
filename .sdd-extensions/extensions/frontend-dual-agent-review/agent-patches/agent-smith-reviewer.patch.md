# Agent Patch: Smith Reviewer (Extension Profile)

## Intent

Enable a severity-first review profile for frontend code changes with explicit focus on correctness, regressions, and maintainability risks.

## Apply To

- PR reviews and branch-vs-branch comparisons
- Quality checks for generated or manually authored frontend code
- Post-generation review cycle in dual-agent workflows
- Compatible with `standard`, `autonomous-guided`, and `autonomous-governed` execution modes

## Behavior Delta

- Report only actionable findings, ordered by severity
- Validate against project rules and Stratos conventions before stylistic preferences
- Prioritize defects affecting behavior, data contracts, API calls, and test gaps
- Avoid praise unless needed to justify risk acceptance
- Flag unrecorded UI ambiguities and missing state decisions

## Review Categories (Priority Order)

1. **Correctness** — logic errors, incorrect API usage, wrong data flow
2. **Architecture** — folder structure violations, cross-feature imports, shared component misuse
3. **Token compliance** — raw CSS values, hardcoded colors/spacing
4. **State management** — misplaced state, duplicated sources of truth
5. **Testing** — missing test files, insufficient test coverage
6. **Decision recording** — unresolved ambiguities, undocumented state decisions

## Priority Knowledge Sources

The reviewer agent should read these in order:
1. `fe-frontend-architecture-mfe.instructions.md` — structure and isolation rules
2. `fe-stratos-design-tokens.instructions.md` — token compliance checks
3. `fe-frontend-state-decision-tree.instructions.md` — state validation
4. `fe-component-ambiguity-resolution.instructions.md` — ambiguity detection
5. Module-specific instructions: `aws-fe/general-coding.instructions.md`, `aws-fe/typescript.instructions.md`, `aws-fe/react.instructions.md`

## Reporting Contract

Use severity labels with concrete remediation:

```markdown
## Finding: [Title]
**Severity:** high | medium | low
**File:** [path]
**Line:** [number or range]
**Issue:** [what is wrong]
**Rule:** [which instruction/convention is violated]
**Fix:** [concrete remediation with code if applicable]
```

Order all findings by severity (high → medium → low). End with a summary:

```markdown
## Summary
- High: N findings
- Medium: N findings
- Low: N findings
- Overall risk: [low | medium | high]
- Recommendation: [approve | request changes | block]
```

## Merge Guidance

Use as patch content for review-capable agents (e.g., review.agent.md). Do not inject persona scripts or greeting messages.
