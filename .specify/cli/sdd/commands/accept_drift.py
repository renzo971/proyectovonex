"""`sdd accept-drift <artifact>` — rebaseline an artifact's recorded SHA-256
after a deliberate manual edit, recording the change in the audit log.

Wave 23 §23.B.8.
"""

from __future__ import annotations

import argparse
import os

from sdd.utils.config import find_repo_root
from sdd.utils import output, artifact_integrity


def add_accept_drift_parser(subparsers: argparse._SubParsersAction) -> None:  # type: ignore[type-arg]
    p = subparsers.add_parser(
        "accept-drift",
        help="rebaseline an artifact's recorded SHA-256 after a deliberate edit",
        description=(
            "Recompute the SHA-256 of <artifact> and update its entry in "
            ".specify/.artifact-hashes.json. An audit-log entry is appended "
            "to .specify/.audit-log.jsonl with the old/new hash and the "
            "accepting user (override with --by). Wave 23 §23.B.8."
        ),
    )
    p.add_argument(
        "artifact",
        metavar="<artifact>",
        help="repo-relative path to the artifact (e.g. specs/001-foo/spec.md)",
    )
    p.add_argument(
        "--by",
        dest="accepted_by",
        default=None,
        help="identity to record in the audit log (default: $USER or 'unknown')",
    )


def run_accept_drift(args: argparse.Namespace) -> int:
    try:
        repo_root = find_repo_root()
    except FileNotFoundError as exc:
        output.error(str(exc))
        return 2

    accepted_by = args.accepted_by or os.environ.get("USER") or "unknown"
    drift = artifact_integrity.verify_one(repo_root, args.artifact)
    if drift is None:
        # Either untracked or already clean.
        ledger = artifact_integrity.load_ledger(repo_root)
        if args.artifact not in ledger:
            output.error(
                f"{args.artifact} is not tracked in the artifact-integrity ledger; "
                "nothing to accept."
            )
            return 1
        output.success(f"{args.artifact} already matches the recorded hash — no-op.")
        return 0

    result = artifact_integrity.accept_drift(repo_root, args.artifact, accepted_by=accepted_by)
    if result is None:
        output.error(
            f"Could not accept drift for {args.artifact} (untracked or missing on disk)."
        )
        return 1
    old_sha, new_sha = result
    output.success(
        f"Rebaselined {args.artifact}: {old_sha[:12]}… → {new_sha[:12]}… "
        f"(accepted-by {accepted_by})"
    )
    return 0
