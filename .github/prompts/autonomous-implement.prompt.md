---
mode: agent
description: "Execute one bounded autonomous implementation cycle following the autonomy policy."
tools: ["run_in_terminal", "read_file", "replace_string_in_file", "create_file", "grep_search", "file_search"]
---

# Autonomous Implement — Single-Cycle Bounded Execution

You are executing one bounded autonomous implementation cycle. Follow the autonomy policy instruction exactly.

## Pre-Conditions

Before starting, read the execution mode from `.specify/specs/{{ feature-id }}/.feature-meta.json`:
- If `executionMode` is `standard`, STOP. This prompt is only for autonomous modes.
- If `autonomyBudget` is reached, STOP and report budget exhausted.
- If `lastAutonomyStatus` is `blocked` or `escalated`, STOP and report the pending issue.

## Cycle Protocol

### Step 1 — Read State From Files Only

Read these files fresh (do NOT rely on prior session context):
- `.specify/specs/{{ feature-id }}/tasks.md` — current task backlog
- `.specify/specs/{{ feature-id }}/todo.md` — if exists, current autonomous progress
- `.specify/specs/{{ feature-id }}/lessons.md` — if exists, accumulated learnings
- `.specify/specs/{{ feature-id }}/context-bridge.md` — if exists, phase context
- `.specify/specs/{{ feature-id }}/.feature-meta.json` — execution mode and autonomy state

### Step 2 — Select Exactly One Item

From `tasks.md`, find the next item that is:
- Not yet completed
- Not blocked by another item
- Executable within the autonomy policy (no forbidden actions required)

If no eligible item exists, STOP and set `lastAutonomyStatus: completed`.

### Step 3 — Write Cycle Intent Before Code Changes

Append to `todo.md`:

```markdown
## Cycle N — [Item ID]
**Started:** [timestamp]
**Intent:** [what will be done]
**Assumptions:** [key assumptions]
**Acceptance Target:** [how to verify success]
```

### Step 4 — Implement Only That Item

- Make only the changes required for this single item
- Follow all existing SDD conventions and instructions
- Keep changes focused and minimal

### Step 5 — Run Bounded Checks/Tests

- Run relevant tests or checks for the changed item
- Record pass/fail results
- If tests fail, attempt a bounded fix (up to `autonomyMaxIterations` retries)
- If fix fails, escalate

### Step 6 — Write Evidence to Files

Update `todo.md` with the evidence block:

```markdown
### Cycle N Evidence
- **Item ID:** TXXX
- **Rationale:** [why selected, how implemented]
- **Touched Artifacts:** [file list]
- **Tests/Checks Run:** [test names and results]
- **Traceability:** [links to spec.md, tasks.md entries]
- **Confidence Score:** N/5
- **Risk Classification:** low | medium | high | critical
- **Outcome:** success | partial | failed | escalated
- **Next Recommended Action:** [see below]
```

Update `.feature-meta.json`:
- Increment cycle count (track in `todo.md`)
- Update `lastAutonomyStatus` to `running`, `completed`, `escalated`, or `blocked`

Update `lessons.md` if any learning was captured.

### Step 7 — Stop and Determine Next Action

**If `executionMode` is `autonomous-guided`:**
> ⏸️ Cycle complete. Requesting operator approval.
>
> **Completed:** [Item ID] — [brief description]
> **Confidence:** N/5
> **Next Item:** [Item ID] — [brief description]
>
> Please review the evidence in `todo.md` and approve the next cycle, or switch to `standard` mode.

**If `executionMode` is `autonomous-governed`:**
> ✅ Cycle complete. Next cycle is eligible.
>
> **Completed:** [Item ID] — [brief description]
> **Confidence:** N/5
> **Escalation Triggers Fired:** none
>
> The next cycle should start in a **fresh session**. Do NOT continue in this session.

If any escalation trigger fired, regardless of mode:
> ⚠️ Escalation required. Autonomous execution paused.
>
> **Trigger:** [description]
> **Recommendation:** Switch to `standard` mode and resolve manually.

## Constraints

- **ONE item per cycle** — never implement two items in the same session
- **Fresh context** — never continue from a previous session's state
- **File-first** — all state must be persisted to files before stopping
- **Constitution supremacy** — all SDD rules apply; autonomy adds constraints, never weakens them
- **Gate enforcement** — never bypass or weaken gate validation
