---
applyTo: ".specify/**,.github/agents/review*"
description: Detailed elaboration on convergence review multi-model artifact validation
---

# Convergence Review — Detailed Protocol

See [convergence-review.instructions.md](convergence-review.instructions.md) for trigger criteria and quick reference.

## Multi-Model Convergence Workflow

Convergence review routes the same artifact to multiple AI models for independent evaluation, then converges on consensus.

### Integration Points per Gate

**Gate 1 (Spec)**: Review spec completeness and requirement coverage from multiple perspectives

**Gate 2 (Design)**: Review architecture decisions and contract definitions for blind spots

**Gate 4 (Ship)**: Review ship checklist for missed risks from multiple perspectives

## Round Structure & Convergence Rules

- Max 2 review rounds to prevent infinite loops
- Models review independently — do not share one model's findings before collecting all reviews
- Convergence rule: findings must appear in ≥2 independent reviews to be significant
- Stall detection: if >80% of findings are identical across rounds, escalate decision rather than loop

## Constraints & Governance

- **Opt-in only** — convergence review is never mandatory; adds review time and model cost
- **Full artifact scope** — review the entire artifact, not cherry-picked sections
- **Independent analysis** — models must review without seeing other models' intermediate findings
- **Consensus required** — converge findings only when ≥2 models independently identify the same issue

## Output Format

Produce a convergence report with:
- Reviewed artifact name and version
- Round 1 findings from each model
- Round 2 findings (if applicable)
- Converged findings (appears in ≥2 reviews)
- Dissenting findings (appears in only 1 review)
- Operator recommendation (proceed / request changes / escalate)
