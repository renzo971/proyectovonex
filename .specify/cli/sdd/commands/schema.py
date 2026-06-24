"""`sdd schema show <command>` — Wave 26 §B.13.

Print the JSON Schema that the given command's `--json` envelope conforms to.

The base envelope schema lives at `.specify/schemas/cli-output.schema.json`;
per-command refinements (when present) live at
`.specify/schemas/cli-output/<command>.schema.json` and override the `data`
sub-schema. When no refinement exists, the base envelope schema is returned
verbatim so consumers can still pin a stable contract.
"""

from __future__ import annotations

import argparse
import json
import sys
from copy import deepcopy
from pathlib import Path

from sdd.utils.config import find_repo_root
from sdd.utils import output


def add_schema_parser(subparsers: argparse._SubParsersAction) -> None:  # type: ignore[type-arg]
    p = subparsers.add_parser(
        "schema",
        help="introspect CLI JSON output schemas (Wave 26 §B.13)",
        description=(
            "Print the JSON Schema for a given command's --json envelope. Per-command "
            "refinements (when present) override the `data` sub-schema."
        ),
    )
    sp = p.add_subparsers(dest="schema_action", metavar="<action>")
    sp.required = True

    show = sp.add_parser("show", help="show the JSON envelope schema for a command")
    show.add_argument(
        "command",
        metavar="<command>",
        help="CLI command name (e.g. doctor, gate, module, status)",
    )
    show.add_argument(
        "--pretty",
        action="store_true",
        default=False,
        help="pretty-print the JSON output",
    )


def run_schema(args: argparse.Namespace) -> int:
    if getattr(args, "schema_action", None) != "show":
        output.error("usage: sdd schema show <command>")
        return 2

    try:
        repo_root = find_repo_root()
    except FileNotFoundError as exc:
        output.error(str(exc))
        return 2

    base_path = repo_root / ".specify" / "schemas" / "cli-output.schema.json"
    if not base_path.exists():
        output.error(f"missing envelope schema: {base_path.relative_to(repo_root)}")
        return 1
    try:
        envelope_schema = json.loads(base_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        output.error(f"invalid envelope schema JSON: {exc}")
        return 1

    command = args.command
    refined_path = (
        repo_root / ".specify" / "schemas" / "cli-output" / f"{command}.schema.json"
    )
    schema = deepcopy(envelope_schema)
    if refined_path.exists():
        try:
            data_shape = json.loads(refined_path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as exc:
            output.error(f"invalid per-command schema JSON: {exc}")
            return 1
        # The refinement file describes the `data` sub-schema only.
        schema.setdefault("properties", {})["data"] = data_shape

    text = (
        json.dumps(schema, indent=2, sort_keys=True)
        if getattr(args, "pretty", False)
        else json.dumps(schema, sort_keys=True)
    )
    sys.stdout.write(text + "\n")
    return 0
