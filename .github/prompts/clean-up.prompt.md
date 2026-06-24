---
description: Deep code cleanup — remove dead code, fix inconsistencies, improve quality
mode: agent
---

Run a **deep code cleanup** on the codebase.

Invoke `@refactoring` to analyze and identify:

- Dead code — unused classes, methods, fields
- Failed previous implementations — incomplete or abandoned code
- Commented-out code blocks
- Unused files and imports
- Debug statements and debug comments
- Redundant or duplicated logic
- Naming inconsistencies
- Architecture violations against constitution

The refactoring agent will produce a prioritized cleanup plan in
`refactoring-plan.md` with traceability to constitution principles.

After approval, hand off to `@software-engineer` for implementation.
