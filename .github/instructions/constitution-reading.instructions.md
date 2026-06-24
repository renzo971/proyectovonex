---
applyTo: ".specify/**,.github/agents/**"
description: Standardized procedure for reading and applying the project constitution; includes mandatory session startup checklist
---

## Session Startup Checklist

Before producing any artifact:
1. Read `.specify/memory/constitution.md`
2. Read `.specify/memory/team-preferences.md` (if present)
3. Read `.specify/specs/<feature-id>/context-bridge.md` (if continuing a feature)
4. Confirm `ceremonyLevel` from `.specify/specs/<feature-id>/.feature-meta.json`
5. Announce your agent role and phase

**STOP if constitution is missing** — do not proceed without it.

## Constitution Reading Protocol

Read the full constitution **at the start of every task**. Extract relevant constraints: Article I (scope), Article II (tech stack), Article III (quality), Article IV (architecture), Article V (workflow), Article VI (boundaries).

If constitution is missing, instruct the user to run `@constitution` first. Reference specific articles when making decisions. Flag conflicts if your task requires something the constitution prohibits. Propose amendments via Article VII if needed.
