---
mode: agent
description: "5-phase audit workflow that scans instruction, agent, and skill files for context debt — producing a prioritized CONTEXT-DEBT.md report."
---

# Context Debt Audit

> **Purpose:** Identify stale, bloated, or misclassified context files that degrade agent performance.

---

## Phase 1 — Inventory

Scan all `.github/instructions/`, `.github/agents/`, `.github/skills/`, and `.specify/templates/` files. For each, record: file name, line count, last-modified date (if available from git), and primary topic.

## Phase 2 — Sizing Violations

Flag files that exceed sizing contracts:
- Instructions: > 50 lines (companions: > 200 lines)
- Skills: > 80 lines
- Agents: > 120 lines

## Phase 3 — Staleness Detection

Flag files where:
- Content references removed CLI commands, renamed modules, or deprecated features
- Cross-references point to files that no longer exist
- Wave-attribution boilerplate remains in file body text

## Phase 4 — Misclassification

Apply the Skill Design Test to every instruction:
1. Does it contain a multi-step **procedure** an agent must follow? → Should be a skill
2. Does it contain a **reference catalog** (pattern tables, checklists)? → Should be a skill
3. Is it a short **always-on reminder** (≤ 50 lines)? → Correct as instruction

Flag misclassified files with recommended reclassification.

## Phase 5 — Report

Save findings to `.specify/reports/CONTEXT-DEBT.md`:

```markdown
# Context Debt Report

**Generated:** [date]
**Scope:** [file count] files audited

## Summary
| Category | Count | Severity |
|----------|:-----:|:--------:|
| Sizing violations | [n] | High |
| Stale references | [n] | Medium |
| Misclassified files | [n] | Medium |
| Wave-attribution residue | [n] | Low |

## Findings
<!-- One entry per finding: file, category, detail, recommended action -->
```
