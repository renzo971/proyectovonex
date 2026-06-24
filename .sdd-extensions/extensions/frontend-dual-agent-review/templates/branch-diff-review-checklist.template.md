# Branch Diff Review Checklist

## Feature Information

| Field | Value |
|-------|-------|
| Feature ID | |
| Branch | |
| Base Branch | |
| Review Date | |
| Generator Agent | Neo (generation profile) |
| Reviewer Agent | Smith (review profile) |

---

## Pre-Review Checks

- [ ] Feature spec exists and is up to date
- [ ] Design decisions are recorded in `decisions.md`
- [ ] All UI ambiguities are resolved (no PENDING status)
- [ ] State decisions documented for global/feature-scoped state

## Architecture Review

- [ ] New files follow canonical MFE folder structure
- [ ] No cross-feature imports detected
- [ ] Shared components justified by 2+ consumers
- [ ] API calls go through React Query hooks only
- [ ] Feature-specific components are in `pages/<Feature>/components/`

## Token Compliance

- [ ] All spacing uses `Space.*` enum
- [ ] All colors use `Color.*` object
- [ ] Breakpoints use `Breakpoint.*` enum
- [ ] Button variants use Stratos enums
- [ ] Typography uses Stratos text components

## State Management

- [ ] State location matches the decision tree
- [ ] No API data stored in global store (use React Query)
- [ ] No unnecessary state duplication
- [ ] Form state managed by react-hook-form or local useState

## Testing

- [ ] Every new component has a test file
- [ ] Render tests present for all components
- [ ] Interaction tests for user-facing behavior
- [ ] Edge cases: empty, null, error states tested

## Findings Summary

| Severity | Count | Status |
|----------|:-----:|--------|
| High | | |
| Medium | | |
| Low | | |

**Overall Risk:** low | medium | high
**Recommendation:** approve | request changes | block

## Notes

<!-- Additional context, blockers, follow-up items -->
