"""`sdd adapters generate` — generate IDE adapter files from canonical agent definitions."""

from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path

from sdd.utils.config import find_repo_root, scripts_dir, get_env
from sdd.utils import output


def add_adapters_parser(subparsers: argparse._SubParsersAction) -> None:  # type: ignore[type-arg]
    p = subparsers.add_parser(
        "adapters",
        help="manage IDE adapter files",
        description="Generate IDE-specific adapter files from canonical agent definitions.",
    )
    as_ = p.add_subparsers(dest="adapters_action", metavar="<action>")
    as_.required = True

    gen = as_.add_parser(
        "generate",
        help="generate all adapter files from canonical definitions",
    )
    gen.add_argument(
        "--target",
        metavar="TARGET",
        choices=("vscode", "cursor", "claude", "windsurf", "codex", "all"),
        default="all",
        help="which adapter target to generate (default: all)",
    )
    gen.add_argument(
        "--dry-run",
        action="store_true",
        default=False,
        help="print what would be generated without writing files",
    )
    gen.add_argument(
        "--feature-id",
        metavar="FEATURE_ID",
        default=None,
        help="optional feature id used for dynamic model routing",
    )


def run_adapters(args: argparse.Namespace) -> int:
    action: str = args.adapters_action

    if action == "generate":
        return _run_generate(args)

    output.error(f"Unknown adapters action: {action}")
    return 2


def _run_generate(args: argparse.Namespace) -> int:
    try:
        repo_root = find_repo_root()
    except FileNotFoundError as exc:
        output.error(str(exc))
        return 2

    script = scripts_dir(repo_root) / "generate-adapters.py"
    if not script.exists():
        output.error(f"Adapter generator not found: {script}")
        return 2

    cmd = [sys.executable, str(script)]
    if args.target != "all":
        cmd += ["--target", args.target]
    if args.feature_id:
        cmd += ["--feature-id", args.feature_id]
    if getattr(args, "dry_run", False):
        cmd.append("--dry-run")

    try:
        result = subprocess.run(cmd, env=get_env(repo_root), cwd=repo_root)
        return result.returncode if result.returncode in (0, 1) else 2
    except Exception as exc:
        output.error(str(exc))
        return 2
