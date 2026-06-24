---
mode: "agent"
description: Concern-ordered ship-time checkpoint preview — re-orders Gate 4 release-triad evidence by risk class so the most critical hunks are reviewed when operator focus is highest
tools: ["read_file", "create_file", "write_file"]
---

# Checkpoint Preview — Concern-Ordered Ship-Time Review

You are producing the **operator's pre-ship checkpoint**. Three streams of evidence have already been synthesised at Gate 4 by `release-triad-synthesis.prompt.md`:

1. Code review findings
2. Security review findings
3. Test-engineer evidence

Your job is to re-order those findings — and the diff itself — by **concern class**, so the most critical hunks are reviewed when operator attention is highest, not last in the scroll buffer.

This is **not** a new review pass. You consume the existing triad synthesis artifact and the diff; you never re-evaluate code quality.

---

## Instructions

### Step 1 — Collect Inputs

Read:
- `.specify/specs/<feature-id>/gate4-release-packet.md` (the triad synthesis output)
- The active diff (typically `git diff <merge-base>..HEAD --stat` and `git diff <merge-base>..HEAD`)
- `.specify/specs/<feature-id>/HOTSPOTS.md` if present (Phase A hotspot artifact)

If the triad synthesis artifact is missing, abort with a clear diagnostic — do NOT generate a preview without upstream evidence.

### Step 2 — Classify Hunks by Concern

For every hunk in the diff, assign **exactly one** concern class (in priority order):

| Class | Definition |
|---|---|
| **Security** | Hunks flagged by the security reviewer; hunks touching auth, authz, crypto, secrets, input validation, PII, or SQL/HTML injection surfaces |
| **Architecture** | Hunks introducing or modifying a public API, module boundary, persistence schema, or messaging contract; hunks flagged as `Critical` or `Elevated` in `HOTSPOTS.md` |
| **Behavior** | Hunks changing user-visible behavior, business logic, or test outcomes that are neither Security nor Architecture |
| **Style/Docs** | Hunks limited to formatting, renames, doc strings, comments, README/markdown edits |

A hunk that qualifies for multiple classes is assigned to the **highest-priority class** (Security > Architecture > Behavior > Style/Docs).

### Step 3 — Assemble the Preview Artifact

Write the preview to `.specify/specs/<feature-id>/CHECKPOINT-PREVIEW.md` using this layout:

```markdown
# Ship-Time Checkpoint Preview

> **Feature:** <feature-id>
> **Generated:** <ISO timestamp>
> **Source artifacts:** gate4-release-packet.md · HOTSPOTS.md (if present) · diff <merge-base>..HEAD
> **Triad verdict:** <GO | GO with conditions | NO-GO>

---

## Section 1 — Security (review first)

For every hunk classified as Security:

### Hunk: `<file>:<line-range>`
- **Concern (one line):** <what changed and why this is security-relevant>
- **Triad finding (if any):** <reference to gate4-release-packet finding ID>
- **Operator review:** ☐ Reviewed: yes ☐ Reviewed: no ☐ Skip with reason: ___

If no Security hunks exist:
> No Security-class changes in this diff.

---

## Section 2 — Architecture (review second)

Same per-hunk format as Section 1. If `HOTSPOTS.md` flags the file, add the line:
> **Hotspot:** `<bucket>` (score Δ vs base: <pct>%)

---

## Section 3 — Behavior (review third)

Same per-hunk format. Behavior hunks may be summarised in groups when more than 10 share the same module.

---

## Section 4 — Style/Docs (skim last)

Aggregate count and file list only. Per-hunk detail is unnecessary for this class.

---

## Operator Acknowledgement

Shipping is blocked until **every Security and Architecture hunk** is marked
`Reviewed: yes` or `Skip with reason: <reason>`.

- ☐ All Security hunks acknowledged
- ☐ All Architecture hunks acknowledged
- ☐ Behavior changes spot-checked
- ☐ Style/Docs accepted

**Operator:** _______________________  **Date:** _______________________
```

### Step 4 — Communicate Block Conditions

If the upstream triad verdict is `NO-GO`, the preview MUST display the verdict prominently in the header and a single-line warning:
> **NO-GO from Gate 4 — preview is informational only; ship is blocked until upstream blockers are resolved.**

### Step 5 — Hand Off

After writing the artifact, return a one-line summary to the caller:
> Preview written to `.specify/specs/<feature-id>/CHECKPOINT-PREVIEW.md` (S=<n> · A=<n> · B=<n> · D=<n>). Ship blocked on Security/Architecture acknowledgements.

---

## Boundary Rules

**Always Do:**
- Re-use existing triad evidence — never re-evaluate findings.
- Preserve the per-hunk operator acknowledgement field; ship blocking depends on it.
- Order classes Security → Architecture → Behavior → Style/Docs without exception.
- Reference `HOTSPOTS.md` when it exists; surface hotspot bucket on Architecture hunks.

**Ask First:**
- Before grouping more than 10 Behavior hunks under a single summary — the operator may prefer the full list.
- Before omitting Style/Docs entirely — count + file list is the minimum.

**Never Do:**
- Never produce a preview when `gate4-release-packet.md` is missing.
- Never re-classify a Security or Architecture hunk to a lower class to reduce operator workload.
- Never auto-fill the `Reviewed: yes` checkboxes.
- Never override or alter the upstream Gate 4 verdict.
