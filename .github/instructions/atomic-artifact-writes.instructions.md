---
description: "Wave 26 §B.6 — Use sdd.io.atomic_write_* for every artifact write under the CLI."
applyTo: 'enterprise-sdd/.specify/cli/sdd/**/*.py'
---

# Atomic Artifact Writes

> Wave 26 §B.1, §B.5 — convergence of OpenSpec/Driver-AI/Spec-Driven-Workflow.
> The CLI must never leave half-written artifacts behind on crash, kill, or
> concurrent invocation.

Authoritative helpers: [`sdd.io.atomic_write_text`](../../.specify/cli/sdd/io/atomic.py),
[`sdd.io.atomic_write_json`](../../.specify/cli/sdd/io/atomic.py),
[`sdd.io.atomic_write_yaml`](../../.specify/cli/sdd/io/atomic.py).

## Always Do
- Route every artifact write under `.specify/**`, `.sdd-modules/**`, or
  `.sdd-extensions/**` through `sdd.io.atomic_write_*`.
- Choose the helper that matches the payload (`atomic_write_text` for Markdown
  / freeform text, `atomic_write_json` for `.json`, `atomic_write_yaml` for
  `.yaml`).
- Let the helper create parent directories — do not pre-call `mkdir`.
- Keep determinism: pass `sort_keys=True` for JSON unless the payload key order
  is part of an external contract (e.g. installer registries).

## Ask First
- Migrating an append-only ledger or rotating log: `os.replace` would clobber
  history. Open a discussion before touching `_write_ledger_atomic` or similar
  ordered-append helpers.
- Adding a write site outside the CLI source tree: confirm the artifact lives
  under an SDD-owned directory before importing `sdd.io`.

## Never Do
- Call `Path.write_text(...)`, `Path.write_bytes(...)`, or
  `json.dump(open(..., "w"), ...)` against `.specify/**`, `.sdd-modules/**`, or
  `.sdd-extensions/**`. The `lint-atomic-writes` workflow (Wave 26 §B.5) and
  `sdd doctor --atomic-write-discipline` (Wave 26 §B.7) fail the build on any
  unallow-listed hit.
- Suppress lint hits by adding to `_audit/atomic-write-allowlist.txt` without a
  rationale comment in the same PR.
- Wrap the helpers in a try/except that swallows `OSError` — atomic writes are
  intentionally fail-loud; the caller decides recovery.

## Verification
- Local: `cd enterprise-sdd && grep -RInE '\.write_text\(|\.write_bytes\(|json\.dump\(open\(' .specify/cli/sdd --include='*.py'`.
- CI: the `lint-atomic-writes` workflow blocks merges on regressions.
- Runtime: `sdd doctor --atomic-write-discipline` produces a JSON envelope
  listing every offending file (empty `data.violations` → green).
