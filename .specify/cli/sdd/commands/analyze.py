"""`sdd analyze <feature-id>` — run consistency analysis."""

from __future__ import annotations

import argparse
import subprocess

from sdd.utils.config import find_repo_root, script_command, get_env
from sdd.utils import output


def add_analyze_parser(subparsers: argparse._SubParsersAction) -> None:  # type: ignore[type-arg]
    p = subparsers.add_parser(
        "analyze",
        help="analyze spec consistency",
        description="Run analyze-consistency.sh to check cross-artifact consistency.",
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
        "--gaps",
        action="store_true",
        default=False,
        help="run only gap-closure analysis (reverse traceability) instead of full gate validation",
    )
    p.add_argument(
        "--hotspots",
        action="store_true",
        default=False,
        help="compute composite-risk hotspots (LoC × churn × complexity) for files in the diff and emit HOTSPOTS.md",
    )
    p.add_argument(
        "--since",
        metavar="RANGE",
        default=None,
        help="git history window for hotspot churn (default: HEAD~100..HEAD); only used with --hotspots",
    )
    p.add_argument(
        "--provenance",
        action="store_true",
        default=False,
        help="list untraced files on disk with no authorizing task (Wave 27 §26 #2 A.11)",
    )


def run_analyze(args: argparse.Namespace) -> int:
    try:
        repo_root = find_repo_root()
    except FileNotFoundError as exc:
        output.error(str(exc))
        return 2

    if getattr(args, "provenance", False):
        return _run_provenance(repo_root)

    from sdd.utils.feature_resolver import resolve_feature_id
    explicit = args.feature_id or getattr(args, "feature_flag", None)
    feature_id = resolve_feature_id(repo_root, explicit)
    if not feature_id:
        output.error(
            "Could not resolve feature id. Provide it positionally, with --feature, set "
            "SDD_FEATURE, or run from inside a feature workspace with feature.lock.json."
        )
        return 2

    cmd = script_command("analyze-consistency", repo_root) + [feature_id]
    if getattr(args, "gaps", False):
        cmd.append("--gaps")
    if getattr(args, "hotspots", False):
        cmd.append("--hotspots")
        if getattr(args, "since", None):
            cmd += ["--since", str(args.since)]
    try:
        result = subprocess.run(cmd, env=get_env(repo_root), cwd=repo_root)
        return result.returncode if result.returncode in (0, 1) else 2
    except Exception as exc:
        output.error(str(exc))
        return 2


_SOURCE_ROOTS = ("src", "lib", "app")


def _run_provenance(repo_root) -> int:
    """Wave 27 §26 #2 A.11 — list files on disk with no authorizing task.

    Reverse-gap complement to the forward `--gaps`: scans common source roots
    and reports files absent from the forward traceability file set.
    """
    from sdd.utils import traceability

    tracked = traceability.tracked_files(repo_root)
    untraced: list[str] = []
    for root_name in _SOURCE_ROOTS:
        root = repo_root / root_name
        if not root.is_dir():
            continue
        for f in sorted(root.rglob("*")):
            if not f.is_file():
                continue
            rel = f.relative_to(repo_root).as_posix()
            if rel not in tracked:
                untraced.append(rel)

    print("Wave 27 §26 #2 A.11 — provenance (untraced files)")
    print("=" * 78)
    if not untraced:
        output.success("No untraced files — every source file maps to an authorizing task.")
        return 0
    for rel in untraced:
        print(f"  UNTRACED  {rel}")
    print()
    print(f"{len(untraced)} untraced file(s) found.")
    return 0
