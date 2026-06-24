# sdd-challenge

Purpose: challenge design and implementation assumptions before execution drift appears.

## Flow

1. Extract top assumptions from `plan.md`, `spec.md`, and current tasks.
2. Try to falsify each assumption with edge cases, constraints, and counterexamples.
3. Score each assumption confidence on a 1-5 scale.
4. Assign risk level (`low`, `medium`, `high`, `critical`).
5. Propose safer alternatives when confidence is low or risk is high.
6. Return a deterministic report with the sections below.

## Output Contract

- Assumptions
- Counter-Evidence
- Confidence Scores
- Risk Levels
- Safer Alternatives
