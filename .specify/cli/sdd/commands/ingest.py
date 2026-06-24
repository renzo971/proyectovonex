"""`sdd ingest <path>` — brownfield document ingestion."""

from __future__ import annotations

import argparse
import subprocess

from sdd.utils.config import find_repo_root, script_command, get_env, ps_arg
from sdd.utils import output


def add_ingest_parser(subparsers: argparse._SubParsersAction) -> None:  # type: ignore[type-arg]
    p = subparsers.add_parser(
        "ingest",
        help="ingest existing project docs into SDD structure",
        description=(
            "Classify and map brownfield project documents into SDD artifact slots. "
            "Produces an ingest-mapping.md report in .specify/ for human review."
        ),
    )
    p.add_argument(
        "path",
        metavar="<path>",
        help="path to directory or file containing existing project documentation",
    )
    p.add_argument(
        "--dry-run",
        action="store_true",
        help="scan and classify without generating mapping artifacts",
    )


def run_ingest(args: argparse.Namespace) -> int:
    try:
        repo_root = find_repo_root()
    except FileNotFoundError as exc:
        output.error(str(exc))
        return 2

    cmd = script_command("skill-run", repo_root) + ["ingest-docs", args.path]
    if args.dry_run:
        cmd.append(ps_arg("--dry-run"))

    try:
        result = subprocess.run(cmd, env=get_env(repo_root), cwd=repo_root)
        return result.returncode if result.returncode in (0, 1) else 2
    except Exception as exc:
        output.error(str(exc))
        return 2
