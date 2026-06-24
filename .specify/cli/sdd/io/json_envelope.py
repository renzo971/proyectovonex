"""SDD CLI JSON envelope emitter.

Wave 26 §25 #3 — Stable JSON-on-stdout contract for scriptable consumers.

Schema: `.specify/schemas/cli-output.schema.json` (envelope `v1`).

Discipline:
- Envelope goes to **stdout** (one JSON document, single-line by default).
- All logs / progress / warnings render to **stderr**.
- `data` is always a JSON object, never a top-level list (map-form
  discipline; see APM #1317 evidence cited in
  `.github/instructions/cli-json-contract.instructions.md`).
"""

from __future__ import annotations

import contextlib
import json
import logging
import sys
from typing import Iterator


SCHEMA_VERSION = 1


def emit_envelope(
    command: str,
    *,
    data: dict | None = None,
    warnings: list[dict] | None = None,
    errors: list[dict] | None = None,
    ok: bool | None = None,
    pretty: bool = False,
) -> None:
    """Print one envelope JSON document to stdout.

    `command` is a dot-joined identifier (e.g. `doctor`, `module.verify`).

    `data` defaults to an empty object; it MUST be a JSON object — passing
    a list raises `TypeError` (map-form discipline).

    When `ok is None`, the value is derived as `not errors`.
    """
    payload_data = {} if data is None else data
    if not isinstance(payload_data, dict):
        raise TypeError(
            "envelope `data` must be a JSON object (map-form), not "
            f"{type(payload_data).__name__}"
        )
    payload_warnings = list(warnings or [])
    payload_errors = list(errors or [])
    resolved_ok = (not payload_errors) if ok is None else bool(ok)

    envelope = {
        "schema_version": SCHEMA_VERSION,
        "ok": resolved_ok,
        "command": command,
        "data": payload_data,
        "warnings": payload_warnings,
        "errors": payload_errors,
    }

    if pretty:
        text = json.dumps(envelope, indent=2, sort_keys=True, ensure_ascii=False)
    else:
        text = json.dumps(envelope, sort_keys=True, ensure_ascii=False)
    sys.stdout.write(text + "\n")
    sys.stdout.flush()


@contextlib.contextmanager
def route_logs_to_stderr() -> Iterator[None]:
    """Context manager that swaps the root logger to stderr for the duration.

    Existing handlers are removed temporarily and restored on exit. Any
    `logging.*` calls inside the block produce records on stderr only,
    keeping stdout clean for the JSON envelope.
    """
    root = logging.getLogger()
    saved_handlers = list(root.handlers)
    saved_level = root.level
    handler = logging.StreamHandler(stream=sys.stderr)
    handler.setFormatter(logging.Formatter("%(levelname)s %(name)s: %(message)s"))
    for h in saved_handlers:
        root.removeHandler(h)
    root.addHandler(handler)
    if saved_level == logging.NOTSET:
        root.setLevel(logging.INFO)
    try:
        yield
    finally:
        root.removeHandler(handler)
        for h in saved_handlers:
            root.addHandler(h)
        root.setLevel(saved_level)
