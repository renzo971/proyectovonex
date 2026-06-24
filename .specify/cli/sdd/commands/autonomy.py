"""`sdd autonomy status [feature-id]` — show autonomy execution status."""

from __future__ import annotations

import argparse
import subprocess

from sdd.utils.config import find_repo_root, script_command, get_env
from sdd.utils import output


def add_autonomy_parser(subparsers: argparse._SubParsersAction) -> None:  # type: ignore[type-arg]
    p = subparsers.add_parser(
        "autonomy",
        help="manage autonomous execution modes",
        description="Inspect and manage autonomous execution status for features.",
    )
    sub = p.add_subparsers(dest="autonomy_command", metavar="<sub-command>")
    sub.required = True

    sp = sub.add_parser(
        "status",
        help="show autonomy status for a feature",
        description="Display execution mode, budget consumption, and provenance summary.",
    )
    sp.add_argument(
        "feature_id",
        metavar="<feature-id>",
        nargs="?",
        default=None,
        help="feature identifier; omit to scan current directory",
    )


def run_autonomy(args: argparse.Namespace) -> int:
    try:
        repo_root = find_repo_root()
    except FileNotFoundError as exc:
        output.error(str(exc))
        return 2

    handler_map = {
        "status": _run_status,
    }

    handler = handler_map.get(args.autonomy_command)
    if handler is None:
        output.error(f"Unknown sub-command: {args.autonomy_command}")
        return 2

    return handler(args, repo_root)


def _run_status(args: argparse.Namespace, repo_root) -> int:
    cmd = script_command("autonomy-status", repo_root)
    if args.feature_id:
        cmd.append(args.feature_id)

    try:
        result = subprocess.run(cmd, env=get_env(repo_root), cwd=repo_root)
        return result.returncode if result.returncode in (0, 1) else 2
    except Exception as exc:
        output.error(str(exc))
        return 2
