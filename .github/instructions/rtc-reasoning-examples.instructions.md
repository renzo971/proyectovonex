---
applyTo: ".github/agents/spec.agent.md,.github/agents/requirement-analyst.agent.md,.github/agents/architect.agent.md,.github/agents/review.agent.md,.github/agents/security-reviewer.agent.md"
description: Output layout, boundary rules, and activation references for RTC reasoning
---

# RTC Reasoning Detail

See [rtc-reasoning.instructions.md](rtc-reasoning.instructions.md) for activation conditions and required labels.

## Output Layout

```markdown
## Reasoning

### Restate
...

### Ideate
- **A - ...**
- **B - ...**

### Reflect
- **A weaknesses:** ...
- **B weaknesses:** ...

### Score
| Criterion | A | B |
|-----------|---|---|
| Fit to constraints | ... | ... |

### Respond
Choosing **B** because ...

---

# <Standard agent artifact starts here, unchanged>
```

## Section Requirements

- `Restate`: deliverable, constraints, and high-stakes or routine classification.
- `Ideate`: at least two genuinely different options, or an explicit one-option justification.
- `Reflect`: at least one specific weakness per option.
- `Score`: real comparison table, not prose.
- `Respond`: chosen option plus at least two criteria that drove the choice.

## Boundary Rules

- Always keep `Reasoning` first.
- Ask first before using the protocol on routine level-1 or level-2 work.
- Never collapse `Reflect` into `Ideate` or replace the normal artifact with the reasoning block.

## Activation Reference

- `sdd new <name> --with-reasoning`
- `sdd gate <id> <N> --with-reasoning`
- ceremony level >= 4
- high-stakes classification triggered by the agent
