---
applyTo: ".specify/**,.github/agents/**,.github/instructions/**"
description: Session reset and handoff protocol to prevent context drift across long-running feature work
---

## Session Discipline

### Mandatory Reset Triggers

Start a new session/process when ANY occurs:

1. Phase boundary crossed (e.g., Design -> Preparation, Preparation -> Implementation).
2. Context pressure risk appears (large history, repeated retries, or thin responses).
3. Role pivot occurs (spec/design reasoning -> implementation/testing execution).

### SESSION-HANDOFF.md Protocol

Before closing a session, update `SESSION-HANDOFF.md` with:

- active feature id + current phase
- completed tasks and produced artifacts
- unresolved blockers / open questions
- exact next command or next agent invocation
- assumptions that require verification

Next session must read `SESSION-HANDOFF.md` before doing new work.

### Lightweight Feedback Loop

At session start:
- load constitution + team preferences + SESSION-HANDOFF.md
- verify the next action still matches current artifacts

At session end:
- record what changed and what remains
- trim stale assumptions from the handoff

### Skill Design Test (Decision Tree)

Use this sequence before creating a new skill:

1. Is the guidance needed across multiple files or artifacts?
   - If NO: keep it as a scoped instruction.
2. Does it require a non-trivial decision framework (not a short checklist)?
   - If NO: keep it as instruction or agent boundary rule.
3. Is there a detectable activation pattern (file type, trigger phrase, phase, or command flag)?
   - If NO: keep it as instruction.

If all three answers are YES, create a skill.
