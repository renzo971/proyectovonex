---
name: stub-scan
keyword-tags: [stub, placeholder, todo, fixme, hack, incomplete, empty-handler, bare-return]
description: Use when reviewing code for incomplete implementations, placeholder stubs, or false-completion markers.
---

# stub-scan

Purpose: detect stub/placeholder patterns that indicate incomplete implementation.

## When to Use

- Before Gate 3 or Gate 4 review to catch false completions.
- After autonomous implementation cycles to verify real work was done.
- As a pre-review lint pass via `sdd doctor --stub-scan`.

## Stub Patterns (Severity: CRITICAL)

These patterns indicate code that is not genuinely implemented:

| # | Pattern | Example |
|---|---------|---------|
| 1 | Empty catch/handler blocks | `catch (e) {}` or `except Exception: pass` |
| 2 | Single-line return with no logic | `return;` in a function that should compute |
| 3 | Hardcoded dummy returns | `return ""`, `return 0`, `return null`, `return []` |
| 4 | `"TBD"` / `"PLACEHOLDER"` string literals | `const name = "TBD"` |

## Stub Patterns (Severity: WARN)

These patterns may be legitimate if annotated with context:

| # | Pattern | Example |
|---|---------|---------|
| 5 | `// TODO` without ticket context | `// TODO fix this later` |
| 6 | `// FIXME` without ticket context | `// FIXME broken edge case` |
| 7 | `// HACK` without justification | `// HACK works for now` |
| 8 | `// PLACEHOLDER` marker | `// PLACEHOLDER — replace with real logic` |

## Suppression Mechanism

A `TODO` is suppressed (downgraded to INFO) when it follows the format:

```
// TODO(TICKET-123): description of deferred work
```

The parenthesized ticket reference signals intentional deferral, not forgotten code.

## Severity Rules

| Condition | Severity |
|-----------|----------|
| Empty handler or bare placeholder (patterns 1–4) | CRITICAL |
| `TODO`/`FIXME`/`HACK`/`PLACEHOLDER` without ticket (5–8) | WARN |
| `TODO(ticket)` with ticket reference | INFO (suppressed) |

## Boundary

- Never approve a Gate with CRITICAL stub findings.
- WARN findings must be explicitly acknowledged in the ship checklist.
- File-pattern exclusions (e.g., `**/examples/**`, `**/tutorials/**`) are configurable in `.sdd/config`.
