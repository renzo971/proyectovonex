# sdd-ambiguity-score

Purpose: score specification artifacts for ambiguity and recommend PASS or BLOCK before Gate 1.

## Input

- Specification artifact (e.g., `.specify/specs/<feature-id>/spec.md`, `business-context.md`, or any spec-phase document)

## Scoring Scale

Evaluate each user story, acceptance criterion, and NFR against five ambiguity dimensions. Score each item 1–5:

| Score | Label | Meaning |
|:-----:|-------|---------|
| 1 | **Crystal Clear** | Fully testable, unambiguous, no assumptions needed |
| 2 | **Minor Gap** | Small clarification needed but intent is obvious |
| 3 | **Moderate Ambiguity** | Multiple valid interpretations; needs stakeholder input |
| 4 | **High Ambiguity** | Vague terms, missing boundaries, untestable as written |
| 5 | **Opaque** | Cannot determine intent; must be rewritten |

### Ambiguity Dimensions

1. **Measurability** — Are acceptance criteria testable with concrete values?
2. **Completeness** — Are edge cases, error paths, and boundaries defined?
3. **Consistency** — Does this item conflict with other items or the constitution?
4. **Specificity** — Are actors, data types, and limits explicitly named?
5. **Terminology** — Are domain terms defined in the glossary or constitution?

## Execution Flow

1. Read the target specification artifact.
2. For each user story / AC / NFR:
   - Evaluate against each of the 5 dimensions.
   - Compute a per-item average score (rounded to 1 decimal).
   - Flag items scoring ≥ 3.0 as needing clarification.
3. Compute the overall artifact score (average of all per-item scores).
4. Issue a recommendation: PASS or BLOCK.

## Recommendation Logic

| Overall Score | Recommendation | Action |
|:-------------:|:--------------:|--------|
| 1.0 – 2.0 | **PASS** | Proceed to Gate 1 |
| 2.1 – 2.9 | **PASS with warnings** | Proceed but resolve flagged items during clarification |
| 3.0 – 5.0 | **BLOCK** | Return to specification phase; resolve high-ambiguity items before Gate 1 |

## Output Contract

Produce a deterministic summary report with the following sections:

```markdown
# Ambiguity Score Report

## Summary
- **Artifact:** [file path]
- **Items Scored:** [count]
- **Overall Score:** [X.X / 5.0]
- **Recommendation:** PASS | PASS with warnings | BLOCK

## Item Scores

| Item | Measurability | Completeness | Consistency | Specificity | Terminology | Average | Flag |
|------|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| US-001 | 2 | 1 | 1 | 2 | 1 | 1.4 | — |
| AC-001.1 | 4 | 3 | 2 | 3 | 2 | 2.8 | ⚠️ |
| NFR-001 | 5 | 4 | 3 | 4 | 3 | 3.8 | 🛑 |

## Flagged Items

### AC-001.1 (Score: 2.8 ⚠️)
- **Issue:** [description of the ambiguity]
- **Suggestion:** [how to resolve it]

### NFR-001 (Score: 3.8 🛑)
- **Issue:** [description of the ambiguity]
- **Suggestion:** [how to resolve it]
```
