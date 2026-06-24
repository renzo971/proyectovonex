"""Wave 26 §25 #3 — Reusable argparse + capture helpers for `--json` commands.

Goals:
- Single source of truth for adding `--json` and `--pretty` flags.
- Lightweight wrapper that runs an existing command body, captures any text
  written to stdout, and emits a schema-valid envelope. Commands gain
  scriptable output without rewriting every print/output.* call site.

Schema: `.specify/schemas/cli-output.schema.json`.
"""

from __future__ import annotations

import argparse
import contextlib
import io
import sys
from typing import Callable

from sdd.io.json_envelope import emit_envelope, route_logs_to_stderr


def add_json_flags(parser: argparse.ArgumentParser) -> None:
    """Attach `--json` and `--pretty` to a subcommand parser (Wave 26 §B.10/§B.11).

    `--pretty` is a modifier; consumers should reject it when `--json` is not
    set (validated inside `wrap_envelope`).
    """
    parser.add_argument(
        "--json",
        dest="json",
        action="store_true",
        default=False,
        help="emit a JSON envelope on stdout (schema: cli-output.schema.json)",
    )
    parser.add_argument(
        "--pretty",
        dest="pretty",
        action="store_true",
        default=False,
        help="pretty-print the JSON envelope (only valid with --json)",
    )


def wrap_envelope(
    args: argparse.Namespace,
    command: str,
    runner: Callable[[], int],
) -> int:
    """Run `runner` and, when `--json` is set, emit a JSON envelope.

    The envelope contains:
      - `data.output_text` — captured stdout of the human-readable run
      - `data.exit_code` — the integer exit code returned by `runner`

    When `--json` is not set, the runner is invoked normally and its return
    value is forwarded unchanged.
    """
    if not getattr(args, "json", False):
        if getattr(args, "pretty", False):
            sys.stderr.write("warning: --pretty has no effect without --json\n")
        return runner()

    buf = io.StringIO()
    rc = 0
    try:
        with route_logs_to_stderr(), contextlib.redirect_stdout(buf):
            rc = runner()
    except SystemExit as exc:
        rc = int(exc.code or 0)
    captured = buf.getvalue()
    data = {
        "exit_code": int(rc),
        "output_text": captured,
    }
    errors: list[dict] = []
    if rc not in (0, None):
        errors.append({
            "code": "non_zero_exit",
            "message": f"{command} exited with code {rc}",
        })
    emit_envelope(
        command,
        data=data,
        errors=errors,
        ok=(rc == 0),
        pretty=bool(getattr(args, "pretty", False)),
    )
    return int(rc)
