"""`sdd sync push|pull <feature-id>` — sync tasks with GitHub Issues."""

from __future__ import annotations

import argparse
import subprocess
from pathlib import Path

from sdd.utils.config import find_repo_root, script_command, get_env
from sdd.utils import output

_SCRIPT_MAP: dict[str, str] = {
    "push": "tasks-to-issues",
    "pull": "issues-to-tasks",
}


def add_sync_parser(subparsers: argparse._SubParsersAction) -> None:  # type: ignore[type-arg]
    p = subparsers.add_parser(
        "sync",
        help="sync tasks with GitHub Issues",
        description="Push local tasks to GitHub Issues or pull issue updates back.",
    )
    ss = p.add_subparsers(dest="sync_action", metavar="<action>")
    ss.required = True

    push_p = ss.add_parser("push", help="push tasks to GitHub Issues")
    push_p.add_argument("feature_id", metavar="<feature-id>", help="feature identifier")

    pull_p = ss.add_parser("pull", help="pull GitHub Issues into tasks")
    pull_p.add_argument("feature_id", metavar="<feature-id>", help="feature identifier")


def run_sync(args: argparse.Namespace) -> int:
    action: str = args.sync_action

    script_name = _SCRIPT_MAP.get(action)
    if script_name is None:
        output.error(f"Unknown sync action: {action}")
        return 2

    try:
        repo_root = find_repo_root()
    except FileNotFoundError as exc:
        output.error(str(exc))
        return 2

    cmd = script_command(script_name, repo_root) + [args.feature_id]
    try:
        result = subprocess.run(cmd, env=get_env(repo_root), cwd=repo_root)
        return result.returncode if result.returncode in (0, 1) else 2
    except Exception as exc:
        output.error(str(exc))
        return 2
