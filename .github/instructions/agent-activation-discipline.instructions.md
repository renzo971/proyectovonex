---
applyTo: ".github/agents/**"
description: Ordered activation guardrail — read mandatory-startup-files in declared order, never infer a startup-file value, emit one confirmation line per step (Wave 27 §26 #5).
---

## Agent Activation Discipline

Every agent that writes artifacts or makes decisions **MUST** follow this ordered
startup sequence before producing any primary output.

### Rule A — Execute startup reads in declared order

The agent frontmatter declares `mandatory-startup-files:` as an **ordered list**.
Execute each file read in that exact order, one at a time, before doing any analysis
or generation. Do not skip or reorder entries.

### Rule B — Never infer what a startup file provides

If a startup file exists, **read it** — do not guess, recall, or summarise from memory
what it contains. Startup files (constitution, team-preferences, context-bridge,
feature-meta) are the authoritative source for their content.

If a declared startup file is missing:
- `constitution.md` → **STOP** and instruct the user to run `@constitution` first.
- All other startup files → emit an INFO note and continue (they are optional context).

### Rule C — Emit a one-line confirmation per startup step

Before starting primary output, emit one line per file read:

```
[startup] constitution.md — read ✓
[startup] team-preferences.md — read ✓
[startup] context-bridge.md — not found, continuing
```

This makes the activation sequence visible and auditable. Omit the block only when
the hosting platform suppresses all tool-call output.

### Cross-references

- §23 #2 — `constitution-reading.instructions.md` (session startup checklist)
- §13 — Karpathy behavioral discipline (deliberate execution, no assumed context)
- `sdd doctor --activation-discipline` — CI check that all agents declare the block

### Design boundary

This instruction does not change WHAT agents produce — only the order and transparency
of startup reads. It must not be used to introduce new startup files without a plan
entry and gate.
