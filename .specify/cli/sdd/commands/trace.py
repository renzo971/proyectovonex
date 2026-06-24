"""`sdd trace --reverse <path>` — reverse traceability lookup (Wave 27 §26 #2).

Inverts the forward US→AC→TC→Task→Code chain captured in `tasks.md`: given a
file path, print the originating task / AC / US / spec. Pure read; zero writes,
zero network.

Exit codes (A.9 — mirrors `apm find` CI ergonomics):
- `0` the path is tracked → chain printed
- `1` the path is untracked → clear message
- `2` usage / repo-root error
"""

from __future__ import annotations

import argparse

from sdd.utils.config import find_repo_root
from sdd.utils import output
from sdd.io import add_json_flags, wrap_envelope


def add_trace_parser(subparsers: argparse._SubParsersAction) -> None:  # type: ignore[type-arg]
    p = subparsers.add_parser(
        "trace",
        help="reverse traceability lookup (path → task/AC/US/spec)",
        description=(
            "Invert the forward traceability chain: given a file path, report the "
            "task, acceptance criteria, user stories, and spec that authorized it."
        ),
    )
    p.add_argument(
        "--reverse",
        metavar="<path>",
        dest="reverse",
        default=None,
        help="file path to trace back to its originating task chain",
    )
    add_json_flags(p)


def run_trace(args: argparse.Namespace) -> int:
    return wrap_envelope(args, "trace", lambda: _run_trace_inner(args))


def _run_trace_inner(args: argparse.Namespace) -> int:
    try:
        repo_root = find_repo_root()
    except FileNotFoundError as exc:
        output.error(str(exc))
        return 2

    target = getattr(args, "reverse", None)
    if not target:
        output.error("`sdd trace` requires --reverse <path>")
        return 2

    from sdd.utils import traceability

    matches = traceability.reverse_lookup(repo_root, target)
    if not matches:
        output.warn(f"UNTRACKED: no task authorizes '{target}'")
        return 1

    print(f"Wave 27 §26 #2 — reverse traceability for '{target}'")
    print("=" * 78)
    for t in matches:
        print(f"\nTask  : {t.task_id} — {t.title}")
        print(f"Spec  : {t.spec_file} (feature {t.feature})")
        if t.acceptance_criteria:
            print(f"AC    : {', '.join(t.acceptance_criteria)}")
        if t.user_stories:
            print(f"US    : {', '.join(t.user_stories)}")
        if t.traces_to:
            print(f"Traces: {t.traces_to}")
    print()
    print(f"{len(matches)} authorizing task(s) found.")
    return 0
