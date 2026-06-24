# source-citation-check

Purpose: audit one or more SDD artifacts for citation completeness — verify that all external-knowledge claims include an `## External References` section with non-empty entries.

## When to Use

- After Gate 1 spec is complete, before submitting for Gate 2 design review
- During Gate 4 code review for any artifact that was modified in the current feature
- Operator triggers via `sdd skill run source-citation-check <feature-id>`
- Recommended whenever `source-verification.instructions.md` was active during authoring

## Input

- One or more artifact files:
  - `.specify/specs/<feature-id>/spec.md`
  - `.specify/specs/<feature-id>/plan.md`
  - `.specify/specs/<feature-id>/business-context.md`
  - Any other markdown artifact where external knowledge was expected

## Execution Flow

1. For each target artifact:
   a. Read the full file content.
   b. Scan for any of the following signals that indicate an external-knowledge claim:
      - Library method calls (e.g., `somelib.method(...)`)
      - Protocol or standard names (e.g., "OAuth 2.0", "RFC 7519", "GDPR Article")
      - Third-party service behaviour descriptions (e.g., "S3 returns 404 when...", "Kafka guarantees...")
      - Numeric limits or constants likely originating from vendor documentation
   c. For each detected signal, check whether the artifact has an `## External References` section.
   d. For each `## External References` section, verify:
      - At least one row is present (table is not empty)
      - Each row has a non-blank `Source` and `Relevant Section` column
      - `[ASSUMPTION]` entries have a note explaining what verification is needed
   e. Classify each finding:
      - `MISSING_SECTION`: external knowledge signal found, but no `## External References` section
      - `EMPTY_TABLE`: section exists but table has no data rows
      - `MISSING_SOURCE`: a row exists but the Source column is blank
      - `MISSING_SECTION_REF`: a row exists but the Relevant Section column is blank
      - `ASSUMPTION_NO_NOTE`: `[ASSUMPTION]` row has no explanatory note
      - `PASS`: section present and all rows complete

2. Aggregate all findings across artifacts.
3. Classify overall verdict:
   - `PASS`: zero findings
   - `PASS with warnings`: only `MISSING_SOURCE` or `MISSING_SECTION_REF` findings
   - `FAIL`: any `MISSING_SECTION` or `EMPTY_TABLE` finding

4. Produce the output report.

## Output Contract

```markdown
# Source Citation Check Report

## Summary
- **Feature:** [feature-id] — [feature name]
- **Artifacts Reviewed:** [count]
- **Findings:** [count by type]
- **Verdict:** PASS | PASS with warnings | FAIL

## Findings

| Artifact | Finding Type | Signal Found | Detail |
|----------|:------------:|--------------|--------|
| `spec.md` | MISSING_SECTION | "JWT.sign(...)" | No ## External References section |
| `plan.md` | PASS | — | Section present, all rows complete |

## Recommendations
- [specific actions to resolve each FAIL finding]
```

## Common Rationalizations

| Rationalization | Why it fails | Correct behavior |
|-----------------|:------------:|-----------------|
| "This is a well-known library — everyone knows how it works" | "Well-known" is relative to context and version. Library semantics change between major versions; citing the version in External References makes the spec version-safe. | Add an External References row with the library docs URL and the exact version referenced. |
| "The spec is too short to need citations" | Citation requirements are triggered by external-knowledge signals, not document length. A one-line spec citing an OAuth flow still needs an RFC link. | Check for external-knowledge signals using the DETECT step; add the `## External References` section even if the artifact is short. |
| "We'll add the citations during review" | Citations added during review were not present when the spec was authored — the authoring agent may have made claims that differ from the actual source. Citations must be added at CITE time (when the source was actually consulted). | Run this skill before submission, not after. If the source was not consulted during authoring, use `[ASSUMPTION]` and re-verify before the next gate. |
| "The constitution already covers this" | Constitution coverage applies only to project-specific decisions. External library APIs, protocols, and regulatory text are outside constitution scope. | Verify that the claim is actually present in the constitution before omitting the citation. |
