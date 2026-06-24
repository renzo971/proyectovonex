"""`sdd diff-drift <artifact>` — show what changed between the recorded
artifact-integrity baseline and the current file (hash-only fallback when no
snapshot exists).

Wave 23 §23.B.9.
"""

from __future__ import annotations

import argparse

from sdd.utils.config import find_repo_root
from sdd.utils import output, artifact_integrity


def add_diff_drift_parser(subparsers: argparse._SubParsersAction) -> None:  # type: ignore[type-arg]
    p = subparsers.add_parser(
        "diff-drift",
        help="show drift detail for an artifact (hash-only fallback when no snapshot exists)",
        description=(
            "Compare the recorded SHA-256 of <artifact> against its current "
            "on-disk content. No snapshot subsystem exists yet, so the report "
            "is hash-only when a mismatch is detected. Wave 23 §23.B.9."
        ),
    )
    p.add_argument(
        "artifact",
        metavar="<artifact>",
        help="repo-relative path to the artifact (e.g. specs/001-foo/spec.md)",
    )


def run_diff_drift(args: argparse.Namespace) -> int:
    try:
        repo_root = find_repo_root()
    except FileNotFoundError as exc:
        output.error(str(exc))
        return 2

    report = artifact_integrity.diff_drift(repo_root, args.artifact)
    print(report)
    if report.startswith(("untracked", "missing", "hash mismatch")):
        return 1
    return 0
