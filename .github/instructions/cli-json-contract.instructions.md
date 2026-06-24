---
description: "Wave 26 §B.14 — Stable JSON envelope contract for `sdd <command> --json` consumers."
applyTo: 'enterprise-sdd/.specify/cli/sdd/commands/**/*.py'
---

# CLI JSON Output Contract

Wave 26 §B.8–§B.13 — every command supporting `--json` MUST emit one JSON object
per invocation, validated against
[.specify/schemas/cli-output.schema.json](../../.specify/schemas/cli-output.schema.json).
Helpers: [`sdd.io.emit_envelope`](../../.specify/cli/sdd/io/json_envelope.py),
[`sdd.io.route_logs_to_stderr`](../../.specify/cli/sdd/io/json_envelope.py),
[`sdd.io.add_json_flags` / `wrap_envelope`](../../.specify/cli/sdd/io/cli_helpers.py).

## Envelope (schema_version: 1)

```json
{ "schema_version": 1, "ok": true, "command": "doctor",
  "data": {}, "warnings": [], "errors": [] }
```

`data` is always an object — top-level arrays are rejected. Use **map-form**
collections (`{id: object}`) so consumers can diff stably. `ok` is derived as
`not errors` when omitted.

## Always Do
- Wire `--json` / `--pretty` once via `add_json_flags(parser)`; `--pretty`
  requires `--json`.
- Wrap command body with `wrap_envelope(args, "<command>", inner)` or, for
  hand-rolled commands, `with route_logs_to_stderr(): ... emit_envelope(...)`.
- Skip `output.success/info/warn` on stdout when `args.json` is true.
- Publish per-command refinements at
  `.specify/schemas/cli-output/<command>.schema.json`; expose via
  `sdd schema show <command>`.

## Ask First
- Streaming or multi-document JSON output (envelope is single-shot by design).
- Bumping `schema_version` (requires deprecation window + CHANGELOG entry).

## Never Do
- Mix human banners and the envelope on stdout.
- Emit a top-level JSON array (`[...]`).
- Set `ok: true` while `errors` is non-empty.
- Hand-roll an envelope dict — go through `emit_envelope`.

## Verification
- `python -m pytest enterprise-sdd/_tests/ -k json`
- `sdd doctor --json --pretty | jq` → object with `schema_version: 1`.
