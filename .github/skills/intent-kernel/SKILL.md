---
name: intent-kernel
namespace: false
keyword-tags: [intent, brief, brain-dump, ticket, kernel, 5-field, intake, distil, spec-seed]
description: Distil a raw brief/brain-dump/ticket into a 5-field intent kernel ready to seed Phase 1 spec (Wave 27 §26 #4).
---

# intent-kernel

Purpose: convert messy raw input (brain dump, ticket, transcript, PRD fragment) into a
tight 5-field kernel that any downstream Phase 1 spec can consume directly. The kernel
is an **intake aid, not a primary artifact** — it is always subordinate to the formal
`spec.md` produced in Phase 1 and never satisfies Gate 1 on its own.

## When to Use

- The user has a rough idea and wants to reach `spec.md` faster without losing fidelity.
- `sdd new --from-brief <file>` invokes this skill to pre-populate the spec scaffold.
- Triggered via `sdd-specify` namespace when `brief`, `brain-dump`, `intake`, `kernel`,
  or `distil` appear in the active context.

## Input

- Raw brief: plain text file, ticket body, meeting transcript, brain dump, or PRD fragment.
- Optional: `constitution.md` (used as guardrail; loaded via `mandatory-startup-files`).

## Execution Flow

1. Read the raw input from the provided file.
2. Extract or infer each of the five kernel fields; use `[NEEDS CLARIFICATION]` for any
   that cannot be derived from the input (never invent content).
3. Build the `sources:` provenance list from the input file paths / references used.
4. Write the kernel block to standard output (or seed it into the spec scaffold when
   called via `sdd new --from-brief`).

## Output Contract — 5-Field Kernel

```markdown
## Intent Kernel

| Field | Content |
|-------|---------|
| Problem | <one sentence — the core user/system problem being solved> |
| Capabilities | <comma-separated list of functional outcomes the solution must deliver> |
| Constraints | <hard technical, regulatory, or timeline constraints; none if truly absent> |
| Non-goals | <explicit out-of-scope items to prevent scope creep> |
| Success signal | <observable, measurable condition that proves the problem is solved> |

**Sources:** <file1>, <file2>, …
```

## Boundary

- **Kernel ≠ spec.** The kernel does not replace `spec.md`, does not satisfy Gate 1,
  and is not an authoritative artifact. It is discardable once the spec is written.
- Never invent Capabilities or Constraints — use `[NEEDS CLARIFICATION]`.
- Never gate or block the Phase 1 spec process; always hand off to the `@requirement-analyst`
  or `@clarification` agent immediately after kernel delivery.

## Invocation via sdd-specify

Triggered by: `brief`, `brain-dump`, `intake`, `kernel`, `distil`, `seed spec`.
