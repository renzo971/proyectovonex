---
name: sdd-doctor
namespace: true
keyword-tags: [doctor, drift, integrity, unicode, sizing, lint, install-health, framework-health]
description: Diagnostic namespace meta-skill — module verify, drift, hidden Unicode, sizing.
---

# sdd-doctor (namespace meta-skill)

Purpose: lightweight router for diagnostic and integrity work.

## When to Use

- Running `sdd doctor` and interpreting the output.
- The user reports framework health issues or suspected drift.
- Auditing the install for integrity, sizing, or hidden-Unicode risk.

## Routed Sub-Skills

| Trigger keywords | Sub-skill | Purpose |
|------------------|-----------|---------|
| `agent lint`, `agent design`, `boundary rules audit` | `sdd-agent-lint` | Lint agent files for boundary/design issues |
| `module verify`, `module integrity`, `hash drift` | (uses `module_integrity` utility) | Module integrity verification |
| `hidden unicode`, `homoglyph`, `BiDi` | (uses `hidden-unicode-scan` instruction) | Hidden Unicode scanning |
| `instruction size`, `description length`, `> 50 lines` | (uses `instruction-authoring` instruction + `sdd doctor --description-length`) | Sizing/description-length lint (Wave 23 §A) |
| `drift`, `orphaned AC`, `orphaned test`, `stale AC` | `drift-analysis` | Detect spec/test/code drift — orphaned AC, orphaned tests, stale AC (Wave 24) |
| `artifact integrity`, `drift detected` | (uses Wave 23 §B, deferred to next wave) | Artifact integrity (Phase B of Wave 23) |

## Invocation Guidance

1. Default to `sdd doctor` (no flag) for the full health check.
2. For deep dives, use `sdd doctor --description-length` (Wave 23) or per-module `sdd module verify`.
3. Treat all FAIL conditions as blocking; WARN as actionable but non-blocking.

## Boundary

- Never silently ignore a FAIL.
- Never weaken a doctor check to make it pass — fix the root cause.
