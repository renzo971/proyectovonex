---
applyTo: ".specify/**,.github/agents/**"
description: Structured memory protocol — persistent project context across features
---

## Structured Memory Protocol

### Purpose

Maintain project-level memory that persists across features. This prevents re-discovering
the same patterns, repeating the same mistakes, and losing institutional knowledge between
feature conversations.

### Memory Files

All files live in `.specify/memory/` alongside the existing `constitution.md`:

| File | Purpose | Updated By | Scope |
|------|---------|------------|-------|
| `constitution.md` | Project principles and standards | Constitution agent | Project-wide (manual) |
| `session-state.md` | Current feature + phase status | Gate scripts + agents | Active feature |
| `decisions.md` | Architectural decisions with rationale | Architect, SW Engineer | Project-wide (append) |
| `lessons.md` | What worked and what didn't | All agents (after corrections) | Project-wide (append) |
| `research-cache.md` | External research findings | Research-performing agents | Project-wide (with expiry) |
| `metrics-log.md` | Gate pass/fail history | Gate scripts (auto) | Project-wide (append) |

### Agent Responsibilities

1. **At phase start:** Read `session-state.md` to understand current feature context
2. **At phase start:** Scan `lessons.md` for relevant prevention rules from past features
3. **When making decisions:** Check `decisions.md` for prior decisions on similar topics;
   append new decisions when significant trade-offs are made
4. **When researching:** Check `research-cache.md` first — if a recent, relevant entry
   exists, use it instead of re-researching. Append new findings after research.
5. **After corrections/failures:** Append to `lessons.md` with root cause and prevention rule
6. **Never delete entries** from decisions.md, lessons.md, or metrics-log.md (append-only)

### Reading Priority

When loading memory files, agents should read in this order:
1. `constitution.md` (always — project invariants)
2. `session-state.md` (always — current context)
3. `lessons.md` (scan for applicable prevention rules)
4. `decisions.md` (if making architectural choices)
5. `research-cache.md` (if researching or evaluating options)
6. `metrics-log.md` (if reviewing project health or trends)
