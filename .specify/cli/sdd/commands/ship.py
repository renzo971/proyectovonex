"""`sdd ship <feature-id>` - squash merge and cleanup worktree."""

from __future__ import annotations

import argparse
import subprocess

from sdd.utils.config import find_repo_root, script_command, get_env, ps_arg
from sdd.utils import output


def add_ship_parser(subparsers: argparse._SubParsersAction) -> None:  # type: ignore[type-arg]
    p = subparsers.add_parser(
        "ship",
        help="ship a feature worktree branch",
        description="Squash merge a feature branch and clean up its worktree.",
    )
    p.add_argument(
        "feature_id",
        metavar="<feature-id>",
        nargs="?",
        default=None,
        help="feature identifier (optional — falls back to --feature, $SDD_FEATURE, feature.lock.json, branch-name heuristic)",
    )
    p.add_argument(
        "--feature",
        dest="feature_flag",
        metavar="ID",
        default=None,
        help="feature identifier (alternative to the positional argument)",
    )
    p.add_argument(
        "--base",
        metavar="BASE_BRANCH",
        default=None,
        help="base branch to squash-merge into (default: repository default branch)",
    )
    p.add_argument(
        "--preview",
        action="store_true",
        default=False,
        help="render concern-ordered ship-time checkpoint preview (Security → Architecture → Behavior → Style/Docs); ship blocks until Security/Architecture acknowledgements are recorded",
    )


def run_ship(args: argparse.Namespace) -> int:
    try:
        repo_root = find_repo_root()
    except FileNotFoundError as exc:
        output.error(str(exc))
        return 2

    from sdd.utils.feature_resolver import resolve_feature_id
    explicit = args.feature_id or getattr(args, "feature_flag", None)
    feature_id = resolve_feature_id(repo_root, explicit)
    if not feature_id:
        output.error(
            "Could not resolve feature id. Provide it positionally, with --feature, set "
            "SDD_FEATURE, or run from inside a feature workspace with feature.lock.json."
        )
        return 2

    cmd = script_command("worktree-ship", repo_root) + [feature_id]
    if args.base:
        cmd += [ps_arg("--base"), args.base]
    if getattr(args, "preview", False):
        cmd += [ps_arg("--preview")]

    try:
        result = subprocess.run(cmd, env=get_env(repo_root), cwd=repo_root)
        return result.returncode if result.returncode in (0, 1) else 2
    except Exception as exc:
        output.error(str(exc))
        return 2
