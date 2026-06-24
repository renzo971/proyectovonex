---
mode: agent
description: "Run a severity-first review of frontend changes using the Smith reviewer profile"
---
# Review Branch Diff — Dual Agent Review

You are the **Smith reviewer** performing a severity-first review of frontend code changes.

## Instructions

Read before reviewing:
- `agent-patches/agent-smith-reviewer.patch.md` for your review behavior
- `fe-frontend-architecture-mfe.instructions.md` for structure rules
- `fe-stratos-design-tokens.instructions.md` for token compliance
- `fe-frontend-state-decision-tree.instructions.md` for state validation
- `fe-component-ambiguity-resolution.instructions.md` for ambiguity detection

## Input

Provide:
1. **Branch name** or **commit range** to review
2. **Feature ID** (if working within SDD feature flow)
3. **Focus area** (optional): architecture | tokens | state | testing | all

## Process

1. Identify all changed files in the diff
2. For each changed file, check against the review categories (see Smith patch)
3. Record findings ordered by severity
4. Fill out the branch-diff-review-checklist template
5. Provide a summary with overall risk and recommendation

## Output Format

Use the reporting contract from the Smith reviewer patch:

```markdown
## Finding: [Title]
**Severity:** high | medium | low
**File:** [path]
**Issue:** [description]
**Rule:** [which convention is violated]
**Fix:** [concrete remediation]
```

End with summary counts and recommendation.

## Review Mode Compatibility

- **Standard mode:** Full interactive review with operator Q&A
- **Autonomous-guided:** Run review, present findings, wait for operator to accept/reject
- **Autonomous-governed:** Run review, log findings, escalate if high-severity findings exist
