"""`sdd resume <feature-id>` — resume an in-progress feature."""

from __future__ import annotations

import argparse
import subprocess

from sdd.utils.config import find_repo_root, script_command, get_env
from sdd.utils import output


def add_resume_parser(subparsers: argparse._SubParsersAction) -> None:  # type: ignore[type-arg]
    p = subparsers.add_parser(
        "resume",
        help="resume an in-progress feature",
        description="Run resume-feature.sh to restore context for a paused feature.",
    )
    p.add_argument("feature_id", metavar="<feature-id>", help="feature identifier")


def run_resume(args: argparse.Namespace) -> int:
    try:
        repo_root = find_repo_root()
    except FileNotFoundError as exc:
        output.error(str(exc))
        return 2

    cmd = script_command("resume-feature", repo_root) + [args.feature_id]
    try:
        result = subprocess.run(cmd, env=get_env(repo_root), cwd=repo_root)
        return result.returncode if result.returncode in (0, 1) else 2
    except Exception as exc:
        output.error(str(exc))
        return 2
