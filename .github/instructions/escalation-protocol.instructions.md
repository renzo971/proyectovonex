---
applyTo: ".specify/**,.github/agents/**"
description: Mid-execution escalation protocol — three decision levels for handling ambiguity
---

## Escalation Protocol

Use escalation when ambiguity affects delivery but does not always require a full stop.

## Three Levels

| Level | Use When | Result |
|-------|----------|--------|
| **Resolve** | Trivial ambiguity with no downstream impact | Document choice and continue. |
| **Escalate** | Scope-affecting ambiguity with independent work still possible | Write an escalation artifact and continue unrelated work. |
| **Block** | Plan-invalidating discovery | Stop work and route through stuck-detection. |

## Core Rules

- Resolve only when the decision is low-risk and local.
- Escalate when downstream tasks, scope, or architecture depend on the answer.
- Block when the current spec or design is fundamentally invalid.
- Escalation handles ambiguity; stuck-detection handles execution failure.

See [escalation-protocol-detail.instructions.md](escalation-protocol-detail.instructions.md) for artifact fields, flowchart, `sdd status --escalations`, and resolution workflow.
