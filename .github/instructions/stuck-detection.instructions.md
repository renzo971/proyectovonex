---
applyTo: ".specify/**,.github/agents/**"
description: Stuck detection — self-monitoring for output oscillation and repetitive failures
---

## Stuck Detection Protocol

### Purpose

Prevent infinite agent loops by detecting when output is substantially similar to a previous attempt.

### Self-Monitoring Rules

1. **Before writing an artifact**, read the current version of the target file. If your intended output is >80% identical, you are stuck.

2. **On first stuck detection:**
   - State: "⚠️ STUCK DETECTED: My output is substantially similar to the existing artifact. Trying a different approach."
   - Re-analyze the problem from a different angle: question assumptions, re-read input artifacts, consider alternative designs
   - Produce revised output with the different approach

3. **On second stuck detection:**
   - STOP producing output
   - Escalate to human with explicit cause and recommended action

4. **Similarity threshold:** >80% of non-blank, non-header content lines are identical; same section headings in same order; same issues with only cosmetic changes

### ADAPT Recovery Sub-Procedure

When second-pass similarity is still high, run **ADAPT** before escalation:

1. **Assess**: compare latest two attempts and list unchanged sections
2. **Diagnose**: identify root cause (missing input, wrong assumption, invalid strategy)
3. **Adjust**: define one concrete strategy change
4. **Produce**: write `RECOVERY-DISPATCH.md` with ADAPT evidence (artifact, phase, attempt history, root cause, adjustment, verification signal, escalation owner)
5. **Track**: record next action and expected success signal
