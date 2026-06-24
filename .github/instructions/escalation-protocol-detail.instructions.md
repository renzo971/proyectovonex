---
applyTo: ".specify/**,.github/agents/**"
description: Escalation artifact fields, flowchart, status view, and resolution workflow
---

# Escalation Protocol Detail

See [escalation-protocol.instructions.md](escalation-protocol.instructions.md) for the three-level model.

## Escalation Artifact Fields

Every Level-2 escalation should record:
- the question
- up to three options with trade-offs
- the agent recommendation and rationale
- affected downstream tasks
- impact assessment if each option is chosen

## Decision Flow

```text
local ambiguity -> Resolve
scope-affecting ambiguity -> Escalate
plan-invalidating discovery -> Block
```

## Viewing Escalations

`sdd status --escalations` should surface feature, task, summary, pending time, and affected downstream task count.

## Resolution Workflow

1. read the escalation artifact
2. choose an option or provide an alternative
3. record the decision under `## Resolution`
4. mark the task unblocked in `tasks.md`
5. resume dependent work from the resolved artifact

## Level-Specific Follow-Through

- Resolve: document the local decision and continue.
- Escalate: continue only independent work.
- Block: route through stuck-detection and stop the phase.
