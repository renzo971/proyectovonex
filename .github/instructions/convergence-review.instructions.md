---
applyTo: ".specify/**,.github/agents/review*,.github/agents/analysis*"
description: Convergence review — trigger criteria and protocol for multi-model artifact validation
---

## Convergence Review — Trigger Criteria and Protocol

### Purpose

Define when and how to invoke multi-model convergence review for high-stakes
specification and design artifacts. Convergence review routes the same artifact to
multiple AI models for independent evaluation, then converges on consensus.

### Trigger Criteria

Convergence review is **recommended** when: (1) artifact affects >3 components, (2) involves authentication/encryption/trust boundaries, (3) operator requests it via `--convergence`, or (4) ambiguity score ≥2.5.

NOT recommended for ultra-light features (bug fixes, config changes) or artifacts already converged.

### How to Invoke

```bash
# During gate validation — adds convergence review to gate checks
sdd gate <feature-id> <N> --convergence

# Standalone — run convergence review on any artifact
# Use the convergence-review prompt directly:
# @review with convergence-review.prompt.md
```

### Integration Points

| Gate | Convergence Review Role |
|------|------------------------|
| Gate 1 (Spec) | Review spec completeness and requirement coverage from multiple perspectives |
| Gate 2 (Design) | Review architecture decisions and contract definitions for blind spots |
| Gate 3 (Prep) | Not typically used — test cases are deterministic |
| Gate 4 (Ship) | Review ship checklist for missed risks from multiple perspectives |

### Protocol Reference

The full convergence review protocol — including round structure, convergence rules,
stall detection, and output format — is defined in the
[convergence-review prompt](../.github/prompts/convergence-review.prompt.md).

### Constraints

- **Opt-in only.** Never mandatory; use when stakes justify overhead.
- **Max 2 rounds.** Prevents infinite review cycles.
- **Independent reviews.** Do not share one model's findings with another before collecting all reviews.
