---
applyTo: "**/*.skill.md"
description: Detailed rationalization format, canonical examples, and validation checklist for skill authoring
---

# Skill Authoring Detail

See [skill-authoring.instructions.md](skill-authoring.instructions.md) for the required sections.

## Required Common Rationalizations Format

```markdown
## Common Rationalizations

| Rationalization | Why it fails | Correct behavior |
|-----------------|:------------:|------------------|
| "[Excuse 1]" | [Why this is wrong] | [What to do instead] |
| "[Excuse 2]" | [Why this is wrong] | [What to do instead] |
| "[Excuse 3]" | [Why this is wrong] | [What to do instead] |
```

## Canonical Examples

| Rationalization | Why it fails | Correct behavior |
|-----------------|:------------:|------------------|
| "The feature is too small to need this skill" | Trigger conditions, not perceived size, decide applicability. | Check `## When to Use`; if it matches, run the skill. |
| "I already know the answer - no need to verify" | Confidence is not evidence. | Follow the skill steps and confirm the answer. |
| "We're under time pressure" | Pressure is when skipped quality work becomes most expensive. | Run the skill and record any blocker explicitly. |

## Validation Checklist

` sdd skill validate --rationalizations <skill-name> ` checks for:
- title header present
- `Steps` or `Execution Flow` section present
- `Output Contract` section present
- `Common Rationalizations` section present and non-empty
