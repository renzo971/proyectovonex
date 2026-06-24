"""`sdd gate <id> <N>` — validate a spec gate."""

from __future__ import annotations

import argparse
import subprocess

from sdd.utils.config import find_repo_root, script_command, get_env
from sdd.utils import output


def add_gate_parser(subparsers: argparse._SubParsersAction) -> None:  # type: ignore[type-arg]
    p = subparsers.add_parser(
        "gate",
        help="validate a spec gate",
        description=(
            "Validate a feature gate. Standard usage: 'sdd gate <feature-id> <N>' for "
            "gates 1–5. Wave 20 also supports 'sdd gate post-merge <feature-id>' for "
            "post-merge integration verification (runs build_command + test_command "
            "from .specify/config.yaml)."
        ),
    )
    p.add_argument(
        "id",
        metavar="<feature-id|post-merge>",
        nargs="?",
        default=None,
        help="feature identifier (optional — resolved via --feature, $SDD_FEATURE, feature.lock.json, branch heuristic) — or the literal 'post-merge' to invoke the post-merge gate",
    )
    p.add_argument(
        "n",
        metavar="<N|feature-id>",
        nargs="?",
        default=None,
        help="gate number 1–5 — or, when 'id' is 'post-merge', the feature identifier",
    )
    p.add_argument(
        "--feature",
        dest="feature_flag",
        metavar="ID",
        default=None,
        help="feature identifier (alternative to the positional argument; consulted by the resolver chain)",
    )
    p.add_argument(
        "--tdd",
        action="store_true",
        default=False,
        help="enforce TDD mode at gate 2 — verify test stubs exist for every implementation task "
             "(overrides constitution tdd_mode setting)",
    )
    p.add_argument(
        "--hooks",
        action="store_true",
        default=False,
        help="execute post-gate hooks (notify, auto-commit, trigger-next, export-report) after gate validation",
    )
    p.add_argument(
        "--convergence",
        action="store_true",
        default=False,
        help="run multi-model convergence review in addition to standard gate validation",
    )
    p.add_argument(
        "--synthesize",
        action="store_true",
        default=False,
        help="[Gate 4 only] synthesise review, security, and test evidence into a Gate 4 release packet using release-triad-synthesis.prompt.md",
    )
    p.add_argument(
        "--with-reasoning",
        action="store_true",
        default=False,
        help="activate the RTC reasoning protocol for review/security-reviewer agents during this gate validation",
    )
    from sdd.io import add_json_flags
    add_json_flags(p)


def run_gate(args: argparse.Namespace) -> int:
    from sdd.io import wrap_envelope
    return wrap_envelope(args, "gate", lambda: _run_gate_inner(args))


def _run_gate_inner(args: argparse.Namespace) -> int:
    try:
        repo_root = find_repo_root()
    except FileNotFoundError as exc:
        output.error(str(exc))
        return 2

    from sdd.utils.feature_resolver import resolve_feature_id

    # Wave 20 — Post-merge gate dispatch: `sdd gate post-merge [<feature-id>]`
    if str(args.id).lower() == "post-merge":
        explicit = args.n or getattr(args, "feature_flag", None)
        feature_id = resolve_feature_id(repo_root, explicit)
        if not feature_id:
            output.error(
                "Could not resolve feature id for post-merge gate. Provide it as the second "
                "positional argument, with --feature, $SDD_FEATURE, or run from a workspace "
                "with feature.lock.json."
            )
            return 2
        cmd = script_command("gate-post-merge", repo_root) + [feature_id]
        try:
            result = subprocess.run(cmd, env=get_env(repo_root), cwd=repo_root)
            return result.returncode if result.returncode in (0, 1) else 2
        except Exception as exc:
            output.error(str(exc))
            return 2

    # Standard numeric gate (1–5)
    if args.n is None:
        output.error(
            "Gate number missing. Usage: sdd gate <feature-id> <N>  (or  sdd gate post-merge <feature-id>)."
        )
        return 2
    try:
        gate_n = int(args.n)
    except (TypeError, ValueError):
        output.error(
            f"Invalid gate number: {args.n!r}. Expected 1–5 or use 'sdd gate post-merge <feature-id>'."
        )
        return 2
    if gate_n < 1 or gate_n > 5:
        output.error(f"Gate number must be 1–5 (got {gate_n}).")
        return 2

    explicit = args.id or getattr(args, "feature_flag", None)
    feature_id = resolve_feature_id(repo_root, explicit)
    if not feature_id:
        output.error(
            "Could not resolve feature id. Provide it positionally, with --feature, set "
            "SDD_FEATURE, or run from inside a feature workspace with feature.lock.json."
        )
        return 2

    cmd = script_command("validate-gate", repo_root) + [str(feature_id), str(gate_n)]
    env = get_env(repo_root)
    if getattr(args, "tdd", False):
        env["SDD_TDD_MODE"] = "1"
    if getattr(args, "hooks", False):
        env["SDD_GATE_HOOKS"] = "1"
    if getattr(args, "convergence", False):
        env["SDD_CONVERGENCE"] = "1"
    if getattr(args, "synthesize", False):
        env["SDD_SYNTHESIZE"] = "1"
    if getattr(args, "with_reasoning", False):
        env["SDD_WITH_REASONING"] = "1"
    try:
        result = subprocess.run(cmd, env=env, cwd=repo_root)
        rc = result.returncode if result.returncode in (0, 1) else 2
    except Exception as exc:
        output.error(str(exc))
        return 2

    # Wave 23 §23.B.5 — record artifact-integrity hashes for any artifacts the
    # gate produced. Best-effort; never blocks success.
    if rc == 0:
        try:
            from sdd.utils import artifact_integrity

            artifact_integrity.record_phase_artifacts(
                repo_root, str(feature_id), phase=str(gate_n), written_by=f"sdd-gate-{gate_n}"
            )
        except Exception:
            pass
    return rc
