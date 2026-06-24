---
applyTo: ".specify/**,.github/agents/**"
description: Autonomy evidence blocks and runtime stop/rollback procedures
---

# Autonomy Policy — Evidence & Rollback Details

See [autonomy-policy.instructions.md](autonomy-policy.instructions.md) for runtime contract.

## Evidence Blocks (Required for Autonomous Modes)

When an agent operates in autonomous-guided or autonomous-governed mode, it MUST record evidence for every decision:

**Evidence block format:**
```
[EVIDENCE: <decision-type>]
Alternatives considered: [list 2-3 alternatives]
Selected: [the chosen action]
Justification: [1-2 sentences]
Confidence: HIGH / MEDIUM / LOW
```

**Decision types requiring evidence:**
- Gate passage/failure decisions
- Handoff triggers
- Artifact acceptance/rejection
- Scope adjustments
- Risk escalations

## Stop Conditions (Autonomous Agents MUST Honor)

An autonomous agent MUST **stop and escalate to human** if:

1. **Ambiguity >2.5** — artifact ambiguity score exceeds 2.5 (use sdd-ambiguity-score skill)
2. **Confidence <MEDIUM** — agent's confidence in a key decision is LOW
3. **Contradiction detected** — spec contradicts constitution or prior decisions
4. **Timeout exceeded** — phase execution exceeds 4 hours of wall-clock time
5. **Blocker encountered** — missing artifact or external dependency

## Rollback Procedures

If an autonomous agent detects a mistake **after** a gate has passed:

1. **Do NOT attempt auto-revert** — the gate verdict stands in version control
2. **Record INCIDENT.md** with:
   - What went wrong
   - Which gate passed incorrectly
   - Recommended human action
   - Severity (CRITICAL / MAJOR / MINOR)
3. **Operator decides** whether to:
   - Accept the risk and continue
   - Invoke manual rollback
   - Re-gate the artifact

**Autonomous mode never auto-reverts gates.** Operators control all rollbacks.
