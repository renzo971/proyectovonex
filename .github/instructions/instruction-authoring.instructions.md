---
applyTo: ".github/instructions/**,.github/skills/**/SKILL.md"
description: Authoring contract for instruction and skill sizing, co-location, and single-source rule ownership
---

## Instruction Authoring Contract

### Sizing Rules

- Global or directory-scoped instruction files (`*.instructions.md`) must be **<= 50 lines**.
- Skill files (`SKILL.md`) must be **<= 80 lines**.
- Frontmatter `description:` fields (agents, instructions, prompts, skills) must be **<= 100 chars (WARN)** and **<= 200 chars (ERROR)** — Wave 23 §23.A.19.
- If content exceeds the limit, split into:
  - a compact **core** file with mandatory operational rules
  - an optional **detail/catalog** companion referenced from the core

### Co-Location Rule

- Put guidance closest to where it is used:
  - global behavior -> `.github/instructions/`
  - file-type behavior -> narrow `applyTo` instruction
  - reusable decision framework -> `SKILL.md`
- Do not place operational rules only in plan/changelog files.

### DRY Corollary

- One rule, one canonical owner file.
- Other files should reference the owner; avoid copy-paste variants.
- If two files diverge on the same rule, consolidate to one source and link to it.

### Keep / Split / Reclassify Decision

1. Keep as instruction when the rule must auto-load by `applyTo`.
2. Split when a single instruction exceeds line limits.
3. Reclassify to skill only when all are true:
   - applies across multiple files,
   - requires a non-trivial decision framework,
   - has a detectable activation pattern.

### Boundary

- Never add wave/version history text inside operational rule bodies.
- Keep historical rationale in evolution/plan/changelog files, not in runtime instruction content.