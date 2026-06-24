---
description: Produce deterministic bug reproduction steps and diagnostics.
mode: agent
---

Invoke `@analysis` to prepare deterministic reproduction for a defect.

## Steps

1. Collect environment, inputs, and preconditions.
2. Provide exact reproduction steps.
3. Define expected vs actual behavior.
4. Propose the narrowest instrumentation for diagnosis.

Output must include sections: Preconditions, Reproduction Steps, Expected vs Actual, Diagnostic Signals, Next Debug Action.
