---
applyTo: ".specify/**,.github/agents/**"
description: Context Bridge Protocol — phase-scoped artifact loading to prevent context rot
---

## Context Bridge Protocol

### Purpose

Prevent context rot by starting each phase from file artifacts, not accumulated conversation
history. This ensures agents get clean, relevant context regardless of conversation length.

### Rules

1. **Start from artifacts, not conversation:** At the beginning of your work, read the
   required artifacts listed in your Input section — do NOT rely on information from
   earlier in the conversation unless it matches what the files say.

2. **Read the context bridge first (if it exists):** Before reading individual artifacts,
   check for `.specify/specs/NNN/context-bridge.md`. If it exists, read it first to get
   a compressed summary of prior phases. Then read your phase-specific artifacts for detail.

3. **Phase-scoped loading:** Only load artifacts relevant to your phase. Do not read
   artifacts from later phases that haven't been created yet. The manifest below defines
   what each phase should load.

4. **Regenerate on phase entry:** If you are the first agent in a new phase, recommend
   that the user run `sdd bridge <feature-id>` to generate a fresh context summary.

### Phase Artifact Manifests

| Phase | Agent(s) | Required Artifacts | Optional Artifacts | Never Load |
|-------|----------|--------------------|--------------------|------------|
| 0 | Constitution | `.specify/memory/constitution.md` | — | specs/* |
| 1 | Requirement Analyst, Clarification, Brainstorming | `business-context.md`, `spec.md`, `clarifications.md` | `context-bridge.md` | `plan.md`, `tasks.md`, `test-cases.md` |
| 2 | Architect, API Champion, Messaging Champion | `spec.md`, `clarifications.md`, `plan.md`, contracts | `context-bridge.md`, `business-context.md` | `tasks.md`, `test-cases.md` |
| 3 | Test Explorer, Gherkin Analyst, SW Engineer (PLANNING), Analysis | `spec.md`, `plan.md`, `test-cases.md`, `tasks.md` | `context-bridge.md`, contracts | — |
| 4 | Test Engineer, SW Engineer (IMPL) | `tasks.md`, `plan.md`, `test-cases.md`, contracts | `context-bridge.md`, `spec.md` | — |
| 5 | Review | ALL artifacts | `context-bridge.md` | — |

### Context Bridge Staleness

The context bridge is regenerated on demand (via `sdd bridge`). If the bridge file's
timestamp is older than the newest artifact, agents should note: "Context bridge may
be stale — recommend re-running `sdd bridge <feature-id>`."

### Fix Attempt Tracking — `fix_attempt_count`

Tracks consecutive fix attempts without test improvement for loop detection.
See `context-bridge-detail.instructions.md` for schema and escalation thresholds.
