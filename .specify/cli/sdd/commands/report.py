"""`sdd report <feature-id>` — generate a specification report."""

from __future__ import annotations

import argparse
import subprocess

from sdd.utils.config import find_repo_root, script_command, get_env
from sdd.utils import output


_FORMAT_SKILL_MAP: dict[str, str] = {
    "docx": "sdd-docx-builder",
    "xlsx": "sdd-xlsx-builder",
    "pptx": "sdd-pptx-builder",
}


def add_report_parser(subparsers: argparse._SubParsersAction) -> None:  # type: ignore[type-arg]
    p = subparsers.add_parser(
        "report",
        help="generate a specification report",
        description="Run generate-report.sh to produce a Markdown report for a feature.",
    )
    p.add_argument("feature_id", metavar="<feature-id>", help="feature identifier")
    p.add_argument(
        "--format",
        choices=["md", "docx", "xlsx", "pptx"],
        default="md",
        help="output format (default: md). docx/xlsx/pptx invoke the corresponding builder skill.",
    )


def run_report(args: argparse.Namespace) -> int:
    try:
        repo_root = find_repo_root()
    except FileNotFoundError as exc:
        output.error(str(exc))
        return 2

    fmt: str = getattr(args, "format", "md")

    # For non-Markdown formats, delegate to the appropriate builder skill
    if fmt in _FORMAT_SKILL_MAP:
        skill_name = _FORMAT_SKILL_MAP[fmt]
        cmd = script_command("skill-run", repo_root) + [skill_name, args.feature_id]
        try:
            result = subprocess.run(cmd, env=get_env(repo_root), cwd=repo_root)
            return result.returncode if result.returncode in (0, 1) else 2
        except Exception as exc:
            output.error(str(exc))
            return 2

    # Default: Markdown report via generate-report
    cmd = script_command("generate-report", repo_root) + [args.feature_id]
    try:
        result = subprocess.run(cmd, env=get_env(repo_root), cwd=repo_root)
        return result.returncode if result.returncode in (0, 1) else 2
    except Exception as exc:
        output.error(str(exc))
        return 2
