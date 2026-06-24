---
name: drift-analysis
description: "Use when: checking spec-vs-code fidelity, finding orphaned acceptance criteria, finding orphaned tests, detecting stale specifications, running sdd analyze drift, auditing traceability health"
tags: [drift, traceability, brownfield, spec-code-fidelity, orphaned, stale]
---

# Drift Analysis Skill

## Purpose

Detect spec-vs-code drift by cross-referencing specification acceptance criteria
against test files via traceability IDs. Surfaces three categories of drift that
erode confidence in long-lived projects.

## Workflow — `sdd analyze drift`

1. **Read specs:** scan `.specify/specs/*/spec.md` for AC identifiers (AC-NNN)
2. **Read tests:** scan test files for traceability references (AC-NNN in comments,
   test names, or `Traces To:` annotations)
3. **Cross-reference:** match each AC to its covering test(s) via traceability IDs
4. **Detect drift:** classify each AC/test into one of three drift categories

## Drift Categories

| Category | Definition | Severity |
|----------|-----------|----------|
| **Orphaned AC** | AC exists in spec but has no matching test | WARN |
| **Orphaned Test** | Test references an AC that no longer exists in any spec | WARN |
| **Stale AC** | AC has a covering test, but the test has not been modified since the last spec change | INFO |

## Output Format

```markdown
| Spec | AC | Status | Test File | Last Verified |
|------|-----|--------|-----------|---------------|
| 001-auth | AC-001 | ✅ Covered | auth.spec.ts | 2026-05-10 |
| 001-auth | AC-002 | ⚠️ Orphaned AC | — | — |
| — | — | ⚠️ Orphaned Test | legacy.spec.ts:TC-099 | 2026-03-15 |
| 002-orders | AC-005 | ℹ️ Stale | orders.spec.ts | 2026-01-20 |
```

## Integration

- Integrates with `sdd status` for projects with ≥ 5 completed specs
- Can be run as a pre-review lint pass via `sdd doctor --drift`
- Results feed into the reviewer agent's Pass 1 (Spec Compliance)

## Suppression

- Mark an AC as intentionally untested: `<!-- drift:suppress AC-NNN reason -->`
- Mark a test as legacy/exempt: `// drift:exempt TC-NNN reason`

## File Pattern Defaults

- Specs: `.specify/specs/*/spec.md`
- Tests: `**/*.spec.ts`, `**/*.test.ts`, `**/*.spec.js`, `**/*.test.js`,
  `**/*Test.java`, `**/*_test.py`, `**/*_test.go`
- Configurable via `.sdd/config` → `drift.spec_patterns` / `drift.test_patterns`
