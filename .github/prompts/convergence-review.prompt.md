---
mode: agent
description: "Orchestrate multi-model convergence review of a specification or design artifact. Routes the same artifact to multiple AI models for independent review, then converges on consensus."
---

# Convergence Review

> **Purpose:** Reduce single-model blind spots for high-stakes artifacts by having multiple AI models independently review the same specification or design, then converging on consensus.

---

## When to Use

- Architecture decisions affecting **>3 components**
- Security-sensitive specifications
- Operator-triggered via `sdd gate --convergence`
- Any artifact where single-model review feels insufficient

This is an **optional enhancement** to Gate 1 and Gate 2 — not a mandatory step.

---

## Protocol

### Round 1 — Independent Review

Route the target artifact to 2–3 model tiers for independent review. Each reviewer:

1. Reads the artifact in full.
2. Classifies concerns by severity:
   - **Critical** — Fundamental flaw that invalidates the artifact
   - **Major** — Significant issue that must be resolved before proceeding
   - **Minor** — Improvement suggestion that does not block progress
3. Produces a structured review:

```markdown
## Model Review: [Model Name]

### Concerns

| # | Severity | Finding | Affected Section | Recommendation |
|---|----------|---------|-----------------|----------------|
| 1 | Critical | [description] | [section ref] | [fix suggestion] |
| 2 | Major | [description] | [section ref] | [fix suggestion] |
| 3 | Minor | [description] | [section ref] | [fix suggestion] |

### Overall Assessment
- **Verdict:** PASS / REVISE / REJECT
- **Confidence:** High / Medium / Low
```

### Convergence Check

After all reviews are collected:

| Condition | Action |
|-----------|--------|
| All reviewers: 0 Critical + 0 Major | ✅ **PASS** — artifact is validated |
| Any Critical or Major concerns | ↩️ **REVISE** — address concerns and proceed to Round 2 |

### Round 2 — Re-Review (Max 1 Revision)

1. Revise the artifact to address Critical and Major concerns from Round 1.
2. Route the revised artifact to the **same reviewers** for re-evaluation.
3. Apply convergence check again.

| Condition | Action |
|-----------|--------|
| All reviewers: 0 Critical + 0 Major | ✅ **PASS** |
| Critical count decreased from Round 1 | ↩️ **Surface to operator** with both positions |
| Critical count did NOT decrease (stall) | ⚠️ **STALL** — surface disagreement to operator |

### Stall Detection

If the number of Critical concerns does not decrease between rounds:

1. **Stop further review cycles** — do not attempt a third round.
2. **Surface both positions** to the operator with:
   - The original concern and the revision that attempted to address it
   - Each reviewer's assessment of why the concern persists
   - A recommendation for which position to adopt
3. The operator makes the final decision.

---

## Output

Save the convergence review report to:
`.specify/specs/<feature-id>/convergence-review-report.md`

```markdown
# Convergence Review Report

**Artifact:** [file path]
**Models:** [list of model names/tiers used]
**Rounds:** [1 or 2]
**Result:** PASS | PASS (after revision) | STALL (operator decision needed)

## Round 1 Summary
[aggregated concerns table]

## Round 2 Summary (if applicable)
[aggregated concerns table]

## Unresolved Disagreements (if any)
[description of stalled items]
```

---

## Constraints

- **Maximum 2 rounds.** Never enter a third review cycle.
- **Independent reviews.** Each model reviews the artifact independently — do not share
  one model's review with another before collecting all reviews.
- **Opt-in only.** This is never a mandatory step. Operators choose when convergence
  review adds value.
