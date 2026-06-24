---
applyTo: ".specify/**,.github/agents/**"
description: Mandatory structured question format for all agent interactions requiring user input
---

## Team Preferences Load

At session start, read `.specify/memory/team-preferences.md` if it exists, apply uncommented entries silently, and let direct user instructions override them for the current session only.

## Structured Question Format

When user input is required, do not ask free-form questions. Use:

- one `##` topic header
- sequential `Q1`, `Q2`, `Q3` question labels
- 3-5 options with lettered choices
- explicit trade-offs when relevant
- an `Other` option last

## Priority Tiers

- **P1 - Critical Assumptions**: must be answered before dependent work proceeds.
- **P2 - Important Preferences**: recommended default allowed, but the assumption must be documented.
- **P3 - Deferred Preferences**: defer or batch if a reasonable convention exists.

When multiple approaches are valid and no artifact decides the issue, present options with trade-offs instead of silently choosing one.

See [question-format-examples.instructions.md](question-format-examples.instructions.md) for the exact markdown shape, worked examples, and tier-tagging pattern.
