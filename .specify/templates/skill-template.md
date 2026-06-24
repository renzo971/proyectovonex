# [Skill Name]

Purpose: [one-line description of what this skill does — complete this before shipping]

## When to Use

- [Observable condition 1 — when should an operator run this skill?]
- [Observable condition 2]
- Operator triggers via `sdd skill run [skill-name] <feature-id>`

## Input

- [List the artifacts or inputs this skill reads]
  - Example: `.specify/specs/<feature-id>/spec.md`
  - Example: a git diff, a PR description, a dependency list

## Execution Flow

1. [Step 1 — imperative voice, specific action]
   - [Sub-step if needed]
2. [Step 2]
3. [Step 3 — always ends with producing the output report]

## Severity Classification (if applicable)

| Severity | Definition | Action |
|----------|------------|--------|
| **Critical** | [definition] | BLOCK |
| **High** | [definition] | BLOCK or WARN |
| **Medium** | [definition] | WARN |
| **Advisory** | [definition] | NOTE |

## Output Contract

```markdown
# [Skill Name] Report

## Summary
- **Feature:** [feature-id] — [feature name]
- **Artifacts Reviewed:** [list]
- **Findings:** [count by severity]
- **Verdict:** PASS | PASS with warnings | FAIL | BLOCK

## Findings

### [Finding #N] — [Title]
- **Severity:** [severity]
- **Description:** [what was found]
- **Recommended Action:** [specific next step]
```

## Common Rationalizations

<!-- REQUIRED: every curated SDD skill must include at least 3 rationalizations.
     Use exact wording an agent or human might produce as an excuse for skipping.
     The rebuttal must reference a specific step or output in this skill. -->

| Rationalization | Why it fails | Correct behavior |
|-----------------|:------------:|-----------------|
| "[Exact excuse 1]" | [Why wrong] | [Correct action referencing a specific step] |
| "[Exact excuse 2]" | [Why wrong] | [Correct action] |
| "[Exact excuse 3]" | [Why wrong] | [Correct action] |
