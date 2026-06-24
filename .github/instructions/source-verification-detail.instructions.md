---
applyTo: "**/*"
description: External reference format, scope boundaries, and gate expectations for source verification
---

# Source Verification Detail

See [source-verification.instructions.md](source-verification.instructions.md) for the DETECT -> FETCH -> IMPLEMENT -> CITE contract.

## External References Block

```markdown
## External References

| Source | Access Date | Relevant Section | Notes |
|--------|:-----------:|-----------------|-------|
| [URL or document ID] | [YYYY-MM-DD] | [Section / Version / Clause] | |
| [ASSUMPTION: describe the claim] | — | — | Verify before gate |
```

## Scope Boundaries

| Situation | Required? |
|-----------|:---------:|
| Constitution fact already read in-session | No |
| Prior verified artifact in the current session | No, cite the prior artifact |
| Library API not verified in project dependencies | Yes |
| Protocol or standard named explicitly | Yes |
| General knowledge inference | Yes, or mark assumption |

## Gate Expectations

- Gate 1: requirement and design artifacts cite external references when used.
- Gate 2: architecture and API contracts cite vendor or protocol sources.
- Gate 3: test cases that rely on external semantics cite the source.
- Gate 4: review flags missing citations as a WARN finding.

The `source-citation-check` skill audits citation completeness after the artifact exists. This instruction governs verification during authoring.
