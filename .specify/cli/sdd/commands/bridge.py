"""`sdd bridge <feature-id> [phase]` — generate a context bridge.

Wave 23 §23.A.11–§23.A.13/§23.A.22–§23.A.25 add three flags:
- `--explain`         show per-memory time-decay scoring decisions (no bridge run)
- `--context-check`   report current memory + instructions + bridge token footprint
- `--no-record-hits`  do NOT bump memory `last_referenced_at` (test-only escape hatch)
"""

from __future__ import annotations

import argparse
import os
import subprocess

from sdd.utils.config import find_repo_root, script_command, get_env
from sdd.utils import output


def add_bridge_parser(subparsers: argparse._SubParsersAction) -> None:  # type: ignore[type-arg]
    p = subparsers.add_parser(
        "bridge",
        help="generate a context bridge for a feature",
        description="Run context-bridge.sh to compress prior-phase context into a bridge file.",
    )
    p.add_argument(
        "feature_id",
        metavar="<feature-id>",
        nargs="?",
        default=None,
        help="feature identifier (omit when using --explain or --context-check)",
    )
    p.add_argument(
        "phase",
        metavar="[phase]",
        nargs="?",
        default=None,
        help="optional target phase (e.g. 2.1, 3.1)",
    )
    p.add_argument(
        "--explain",
        action="store_true",
        default=False,
        help="show per-memory time-decay scoring decisions and exit (Wave 23 §23.A.13)",
    )
    p.add_argument(
        "--context-check",
        dest="context_check",
        action="store_true",
        default=False,
        help="report current memory + instructions context footprint vs the active model window (Wave 23 §23.A.22)",
    )
    p.add_argument(
        "--model",
        dest="model",
        default=None,
        help="model id used to size the context window (default: $SDD_MODEL or gpt-4o-mini)",
    )
    p.add_argument(
        "--no-record-hits",
        dest="no_record_hits",
        action="store_true",
        default=False,
        help="do NOT bump memory frontmatter timestamps (test-only escape hatch)",
    )


def run_bridge(args: argparse.Namespace) -> int:
    try:
        repo_root = find_repo_root()
    except FileNotFoundError as exc:
        output.error(str(exc))
        return 2

    if getattr(args, "explain", False):
        return _run_explain(repo_root)
    if getattr(args, "context_check", False):
        return _run_context_check(repo_root, getattr(args, "model", None))

    if not args.feature_id:
        output.error("feature_id is required unless --explain or --context-check is used")
        return 2

    cmd = script_command("context-bridge", repo_root) + [args.feature_id]
    if args.phase:
        cmd.append(args.phase)

    try:
        result = subprocess.run(cmd, env=get_env(repo_root), cwd=repo_root)
        rc = result.returncode if result.returncode in (0, 1) else 2
    except Exception as exc:
        output.error(str(exc))
        return 2

    # Wave 23 §23.A.11 — record hits on memories included in this bridge.
    if rc == 0 and not getattr(args, "no_record_hits", False):
        try:
            from sdd.utils import memory_ranking

            records = memory_ranking.load_all(repo_root)
            included = [r for r in records if r.decay_floor or r.score() >= 0.1]
            n = memory_ranking.record_hits(included)
            output.info(f"Bridge recorded hits on {n} memory file(s) (Wave 23 §23.A.11).")
        except Exception as exc:  # pragma: no cover
            output.warn(f"Memory hit recording skipped: {exc}")
    return rc


def _run_explain(repo_root) -> int:
    from sdd.utils import memory_ranking

    records = memory_ranking.load_all(repo_root)
    if not records:
        output.warn("No memory files found under .specify/memory/")
        return 0
    print(memory_ranking.explain_table(records))
    print()
    print(
        f"{sum(1 for r in records if r.decay_floor or r.score() >= 0.1)} of "
        f"{len(records)} memories would be included in the bridge."
    )
    _explain_dedup(repo_root)
    return 0


def _explain_dedup(repo_root) -> None:
    """Wave 27 §26 #1 A.5/A.6 — annotate authoritative vs. suppressed entries.

    Decay/inclusion scoring (§23 #4) is unchanged. The derived index only
    deduplicates fingerprint-colliding decision/lesson entries: the authoritative
    record (highest reference_count, then most recent) is kept, the rest are
    suppressed from the bridge body.
    """
    from sdd.utils import memory_index

    index = memory_index.load_index(repo_root)
    if index is None:
        index = memory_index.build_index(repo_root)
    groups = memory_index.duplicate_groups(index)
    if not groups:
        return

    print()
    print("Wave 27 §26 #1 — dedup (memory triad: integrity §23 #3 + recency §23 #4 + authority #1)")
    print("-" * 78)
    suppressed = 0
    for group in groups:
        authoritative = next((e for e in group if not e.get("duplicate_of")), group[0])
        print(f"fingerprint {group[0].get('fingerprint', '')[:12]}…")
        for e in group:
            if e is authoritative:
                print(f"  [authoritative] {e.get('id', '')}  (refs={e.get('reference_count', 0)})")
            else:
                suppressed += 1
                print(f"  [suppressed]    {e.get('id', '')} → {e.get('duplicate_of', '')}")
    print()
    print(f"{suppressed} duplicate entr(y/ies) suppressed; authoritative records retained.")


def _run_context_check(repo_root, model: str | None) -> int:
    from sdd.utils import memory_ranking, tokenizer

    chosen_model = model or os.environ.get("SDD_MODEL") or tokenizer.DEFAULT_MODEL
    window = tokenizer.model_window(chosen_model)

    parts: list[tuple[str, str]] = []
    for r in memory_ranking.load_all(repo_root):
        if r.decay_floor or r.score() >= 0.1:
            parts.append((f"memory/{r.path.name}", r.body))

    instructions_dir = repo_root / ".github" / "instructions"
    if instructions_dir.exists():
        for f in sorted(instructions_dir.glob("*.instructions.md")):
            parts.append((f"instructions/{f.name}", f.read_text(encoding="utf-8")))

    total = 0
    method = "heuristic"
    rows: list[tuple[str, int]] = []
    for label, text in parts:
        tc = tokenizer.count_tokens(text, model=chosen_model)
        method = tc.method
        total += tc.tokens
        rows.append((label, tc.tokens))

    status, ratio = tokenizer.utilisation_status(total, window)

    print(f"Wave 23 §23.A.22 — Context utilisation check (model={chosen_model}, method={method})")
    print("=" * 72)
    print(f"{'COMPONENT':<48} {'TOKENS':>10}")
    print(f"{'-' * 48:<48} {'-' * 10:>10}")
    for label, tokens in rows:
        print(f"{label:<48} {tokens:>10}")
    print("-" * 72)
    print(f"{'TOTAL':<48} {total:>10}")
    print(f"{'WINDOW':<48} {window:>10}")
    print(f"{'UTILISATION':<48} {ratio*100:>9.1f}%")
    print(f"\nStatus: {status}  (WARN @ 60%, CRITICAL @ 70%)")
    if status == "CRITICAL":
        print()
        print(tokenizer.session_discipline_recommendation())
        return 1
    return 0
