---
mode: agent
description: "Review UI code for Stratos design-system compliance and MFE best practices"
---
# Design Review — Stratos Compliance

You are reviewing frontend code for compliance with Stratos design-system rules and MFE architecture conventions.

## Instructions

Read before reviewing:
- `fe-stratos-design-tokens.instructions.md` for token rules
- `fe-component-ambiguity-resolution.instructions.md` for decision recording
- `fe-frontend-architecture-mfe.instructions.md` for structure rules
- `fe-frontend-state-decision-tree.instructions.md` for state placement

## Review Checklist

### Token Compliance
- [ ] All spacing uses `Space.*` enum — no hardcoded pixel values
- [ ] All colors use `Color.*` object — no hex codes
- [ ] Breakpoints use `Breakpoint.*` enum
- [ ] Icon sizes use `IconSize.*` enum
- [ ] Button variants/sizes use Stratos enums

### Component Usage
- [ ] Layout uses `VerticalFlex` / `HorizontalFlex` / `ResponsiveGrid` — no raw flexbox divs
- [ ] Typography uses Stratos text components — no raw `<h1>`, `<p>`, `<span>`
- [ ] Form fields use Stratos form components
- [ ] No duplicate/wrapper components when Stratos provides the functionality

### Architecture
- [ ] Component is in the correct folder (shared vs. feature-specific)
- [ ] No cross-feature imports
- [ ] API calls go through React Query hooks, not direct calls
- [ ] State placement follows the decision tree

### Decision Recording
- [ ] Ambiguous UI choices are documented in `decisions.md`
- [ ] State decisions for global/feature-scoped state are documented

## Output Format

Report findings using severity levels:

```markdown
## Finding: [Title]
**Severity:** high | medium | low
**File:** [path]
**Issue:** [description]
**Fix:** [concrete remediation]
```

Order findings by severity (high first). Include a summary count at the end.
