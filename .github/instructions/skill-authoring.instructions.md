---
applyTo: "**/*.skill.md"
description: Mandatory authoring standards for all curated SDD skills
---

# Skill Authoring Standards

Every curated skill MUST include:

- a title matching the directory name
- `## Purpose`
- `## When to Use` or `## Trigger`
- `## Steps` or `## Execution Flow`
- `## Output Contract`
- `## Common Rationalizations`

## Common Rationalizations Rules

- minimum three rationalizations
- use exact agent wording
- rebuttal must point back to a concrete step or artifact
- no generic filler excuses

| Rationalization | Redirect |
|-----------------|----------|
| "I already know this pattern." | Re-read the skill and follow the documented steps. |
| "The artifact is probably fine." | Open the artifact and verify before claiming coverage. |
| "I can skip the output contract." | Produce the required output shape so the next step can consume it. |

Use first-person imperative language and explicit artifact names.

See [skill-authoring-detail.instructions.md](skill-authoring-detail.instructions.md) for the required table format, canonical examples, and validator checklist.
