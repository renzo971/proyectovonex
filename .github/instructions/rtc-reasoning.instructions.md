---
applyTo: ".github/agents/spec.agent.md,.github/agents/requirement-analyst.agent.md,.github/agents/architect.agent.md,.github/agents/review.agent.md,.github/agents/security-reviewer.agent.md"
description: RTC reasoning protocol — opt-in structured reasoning for high-stakes agent decisions
---

## RTC Reasoning Protocol

Prepend a structured `## Reasoning` section when `--with-reasoning`, ceremony level 4-5, or high-stakes classification activates the protocol.

## High-Stakes Triggers

- More than 3 components or modules affected
- Auth, encryption, payment, PII, public contract, or gate logic touched
- `HOTSPOTS.md` marks any touched file as `Critical` or `Elevated`

## Required Sections

When active, the reasoning block MUST contain exactly:

1. **Restate**
2. **Ideate**
3. **Reflect**
4. **Score**
5. **Respond**

Use a real comparison table in `Score`, keep `Reasoning` before the normal artifact, and never replace the normal template with the reasoning block.

See [rtc-reasoning-examples.instructions.md](rtc-reasoning-examples.instructions.md) for the output layout, section requirements, boundary rules, and activation examples.
