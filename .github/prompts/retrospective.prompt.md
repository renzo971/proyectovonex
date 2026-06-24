---
description: Run a structured retrospective after a feature is shipped. Captures learnings, friction points, and proposed updates to constitution and team preferences.
mode: agent
---

Invoke `@brainstorming` or `@analysis` to facilitate a feature retrospective.

## Steps

1. Read `ship-checklist.md` and `analysis-report.md` for the delivered feature.
2. Review gate outcomes (check `.specify/specs/<feature-id>/` for gate artefacts).
3. Load `.specify/memory/team-preferences.md` and `.specify/memory/constitution.md`.
4. Facilitate discussion across six sections (see Output Contract).
5. Save the completed retrospective to `.specify/memory/retrospectives/feature-<slug>.md`.
6. Propose specific, actionable amendments to `constitution.md` and/or `team-preferences.md`.

Alternatively, generate the blank template with: `sdd retrospect --feature <slug>`

## Output Contract

The retrospective document must contain all six sections:

1. **Feature Summary** — one sentence: what was built and why
2. **What Went Smoothly** — process wins, agent quality highlights, spec-code alignment
3. **Friction Points** — gate failures, ambiguous specs, context loss events, rework causes
4. **Reusable Patterns Discovered** — architecture, test, or integration patterns worth repeating
5. **Anti-Patterns Encountered** — project- or stack-specific failure modes
6. **Proposed Updates** — table of: target file | proposed change | priority (🔴/🟡/🟢)
