"""`sdd memory status|sync|doctor <feature-id>` — memory lifecycle operations."""

from __future__ import annotations

import argparse
import subprocess

from sdd.utils.config import find_repo_root, script_command, get_env
from sdd.utils import output
from sdd.io import add_json_flags, wrap_envelope


_SCRIPT_MAP: dict[str, str] = {
    "status": "memory-status",
    "sync": "memory-sync",
    "doctor": "memory-doctor",
}


def add_memory_parser(subparsers: argparse._SubParsersAction) -> None:  # type: ignore[type-arg]
    p = subparsers.add_parser(
        "memory",
        help="manage structured memory lifecycle",
        description="Inspect, sync, and diagnose feature memory freshness and consistency.",
    )
    ms = p.add_subparsers(dest="memory_action", metavar="<action>")
    ms.required = True

    for action, help_text in (
        ("status", "show memory freshness and conflict indicators"),
        ("sync", "synchronize memory artifacts for a feature"),
        ("doctor", "run memory diagnostics and fail on issues"),
    ):
        sp = ms.add_parser(action, help=help_text)
        sp.add_argument("feature_id", metavar="<feature-id>", help="feature identifier")

    # Wave 23 §23.A.14 — `sdd memory list --stale`
    list_p = ms.add_parser("list", help="list memory files with freshness info")
    list_p.add_argument(
        "--stale",
        action="store_true",
        default=False,
        help="show only memories with last_referenced_at > 90 days (Wave 23 §23.A.14)",
    )
    list_p.add_argument(
        "--threshold-days",
        type=float,
        default=90.0,
        help="staleness threshold in days (default: 90)",
    )
    list_p.add_argument(
        "--duplicates",
        action="store_true",
        default=False,
        help="show decision/lesson entries whose fingerprints collide (Wave 27 §26 #1)",
    )

    # Wave 27 §26 #1 — `sdd memory index` rebuilds the derived index.
    index_p = ms.add_parser(
        "index",
        help="rebuild the derived memory index (.specify/memory/.index.json)",
        description=(
            "Rebuild the disposable, derived index over canonical decision/lesson "
            "markdown. The markdown stays canonical; the index is regenerable and "
            "not committed."
        ),
    )
    add_json_flags(index_p)


def run_memory(args: argparse.Namespace) -> int:
    action: str = args.memory_action
    if action == "index":
        return wrap_envelope(args, "memory", _run_memory_index)
    if action == "list":
        if getattr(args, "duplicates", False):
            return _run_memory_duplicates(args)
        return _run_memory_list(args)
    script_name = _SCRIPT_MAP.get(action)
    if script_name is None:
        output.error(f"Unknown memory action: {action}")
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


def _run_memory_list(args: argparse.Namespace) -> int:
    """Wave 23 §23.A.14 — list memory files; with --stale, filter to old ones."""
    try:
        repo_root = find_repo_root()
    except FileNotFoundError as exc:
        output.error(str(exc))
        return 2

    from sdd.utils import memory_ranking

    threshold = float(getattr(args, "threshold_days", 90.0))
    only_stale = bool(getattr(args, "stale", False))
    records = memory_ranking.load_all(repo_root)
    if only_stale:
        records = [r for r in records if r.days_since_hit > threshold and not r.decay_floor]

    title = f"Stale memories (> {threshold:.0f}d)" if only_stale else "All memories"
    print(f"Wave 23 §23.A.14 — {title}")
    print("=" * 78)
    print(f"{'NAME':<32} {'AGE(d)':>10} {'REFS':>6} {'DECAY_FLOOR':>13}")
    print(f"{'-' * 32:<32} {'-' * 10:>10} {'-' * 6:>6} {'-' * 13:>13}")
    for r in records:
        print(
            f"{r.path.name:<32} {r.days_since_hit:>10.1f} {r.reference_count:>6} "
            f"{('yes' if r.decay_floor else 'no'):>13}"
        )
    print()
    print(f"{len(records)} memory file(s) shown.")
    return 0


def _run_memory_index(args: argparse.Namespace) -> int:
    """Wave 27 §26 #1 — rebuild the derived memory index."""
    try:
        repo_root = find_repo_root()
    except FileNotFoundError as exc:
        output.error(str(exc))
        return 2

    from sdd.utils import memory_index

    index = memory_index.write_index(repo_root)
    entries = index.get("entries", [])
    dup_count = sum(1 for e in entries if e.get("duplicate_of"))
    print("Wave 27 §26 #1 — derived memory index rebuilt")
    print("=" * 78)
    print(f"Index file : {memory_index.INDEX_FILE}")
    print(f"Entries    : {len(entries)}")
    print(f"Duplicates : {dup_count}")
    print(f"Generated  : {index.get('generated_at', '')}")
    return 0


def _run_memory_duplicates(args: argparse.Namespace) -> int:
    """Wave 27 §26 #1 — surface fingerprint collisions from the derived index."""
    try:
        repo_root = find_repo_root()
    except FileNotFoundError as exc:
        output.error(str(exc))
        return 2

    from sdd.utils import memory_index

    index = memory_index.load_index(repo_root)
    if index is None:
        index = memory_index.build_index(repo_root)
    groups = memory_index.duplicate_groups(index)

    print("Wave 27 §26 #1 — duplicate memory entries")
    print("=" * 78)
    if not groups:
        print("No fingerprint collisions found.")
        return 0
    for group in groups:
        authoritative = next((e for e in group if not e.get("duplicate_of")), group[0])
        print(f"\nfingerprint {group[0].get('fingerprint', '')[:12]}…")
        for e in group:
            marker = "AUTH" if e is authoritative else "dup "
            print(f"  [{marker}] {e.get('id', '')}  ({e.get('title', '')})")
    print()
    print(f"{len(groups)} collision group(s) found.")
    return 0
