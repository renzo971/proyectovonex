# source-verification

Purpose: in-process verification workflow for external-knowledge claims — DETECT → FETCH → IMPLEMENT → CITE — ensuring no fabricated URLs, signatures, limits, or standards text enter SDD artifacts.

## When to Use

- During any phase where an artifact relies on knowledge outside the current codebase or constitution.
- Operator triggers via `sdd skill run source-verification <feature-id>`.
- Complements `source-citation-check` which audits completed artifacts; this skill operates during authoring.

## Decision Framework — DETECT → FETCH → IMPLEMENT → CITE

### 1. DETECT

Mark any external-knowledge claim with `[NEEDS SOURCE]` before relying on it. Signals include:
- Library method calls (e.g., `somelib.method(...)`)
- Protocol or standard names (e.g., "OAuth 2.0", "RFC 7519", "GDPR Article")
- Third-party service behaviour descriptions
- Numeric limits or constants from vendor documentation

### 2. FETCH

Retrieve the official primary source. Preference order:
1. Vendor documentation (official docs, API reference)
2. RFCs and formal specifications
3. Regulatory text
4. Authoritative secondary sources (OWASP, MDN, etc.)

### 3. IMPLEMENT

- Use only verified information; never substitute training memory for session-verified evidence.
- Surface ambiguity with a clarification item instead of guessing.
- Never fabricate URLs, signatures, limits, or standards text.

### 4. CITE

Add an `## External References` section to the artifact:

```markdown
## External References

| Source | Access Date | Relevant Section | Notes |
|--------|:-----------:|-----------------|-------|
| [URL or document ID] | [YYYY-MM-DD] | [Section / Version / Clause] | |
| [ASSUMPTION: describe the claim] | — | — | Verify before gate |
```

## Scope Boundaries

| Situation | Verification Required? |
|-----------|:----------------------:|
| Constitution fact already read in-session | No |
| Prior verified artifact in the current session | No, cite the prior artifact |
| Library API not verified in project dependencies | Yes |
| Protocol or standard named explicitly | Yes |
| General knowledge inference | Yes, or mark `[ASSUMPTION]` |

## Output Contract

Ensure every external-knowledge claim in the target artifact either has a corresponding entry in `## External References` or is explicitly marked `[ASSUMPTION]`.

## Execution Flow

1. Read the target artifact.
2. Scan for external-knowledge signals (step 1 patterns above).
3. For each signal, check whether a verified source exists.
4. For unverified claims: fetch the primary source or mark `[ASSUMPTION]`.
5. Append or update the `## External References` section.
