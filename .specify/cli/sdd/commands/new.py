"""`sdd new <name>` — create a new feature spec scaffold."""

from __future__ import annotations

import argparse
import subprocess

from sdd.utils.config import find_repo_root, script_command, get_env, ps_arg
from sdd.utils import output


def add_new_parser(subparsers: argparse._SubParsersAction) -> None:  # type: ignore[type-arg]
    p = subparsers.add_parser(
        "new",
        help="create a new feature spec",
        description="Scaffold a new feature specification under .specify/specs/.",
    )
    p.add_argument("name", metavar="<name>", help="short kebab-case feature name")
    p.add_argument(
        "-l",
        "--level",
        metavar="LEVEL",
        default=None,
        help="ceremony level (1=minimal … 4=enterprise)",
    )
    p.add_argument(
        "--template",
        metavar="TEMPLATE",
        default=None,
        help="optional scaffold template name (e.g., standard, full)",
    )
    p.add_argument(
        "--dry-run",
        action="store_true",
        default=False,
        help="show what would be created without writing files",
    )
    p.add_argument(
        "--worktree",
        action="store_true",
        default=False,
        help="create an isolated git worktree for this feature",
    )
    p.add_argument(
        "--execution-mode",
        metavar="MODE",
        default=None,
        choices=("standard", "autonomous-guided", "autonomous-governed"),
        help="execution mode for the new feature",
    )
    p.add_argument(
        "--autonomy-budget",
        metavar="N",
        type=int,
        default=None,
        help="maximum autonomous cycles (used with non-standard execution modes)",
    )
    p.add_argument(
        "--progressive",
        action="store_true",
        default=False,
        help="enable progressive planning (sketch-then-refine) for multi-phase features",
    )
    p.add_argument(
        "--with-reasoning",
        action="store_true",
        default=False,
        help="activate the RTC reasoning protocol (Restate → Ideate → Reflect → Score → Respond) for spec/architect agents on this feature",
    )
    p.add_argument(
        "--on-branch",
        action="store_true",
        default=False,
        help="create the feature workspace without asserting any specific branch-name pattern; pins feature.lock.json to the current branch (works on release/*, hotfix/*, free-form names)",
    )
    p.add_argument(
        "--from-brief",
        metavar="FILE",
        dest="from_brief",
        default=None,
        help="seed the Phase 1 spec scaffold from a raw brief/brain-dump/ticket file via the intent-kernel (Wave 27 §26 #4 B.2)",
    )


def run_new(args: argparse.Namespace) -> int:
    try:
        repo_root = find_repo_root()
    except FileNotFoundError as exc:
        output.error(str(exc))
        return 2

    cmd = script_command("new-feature", repo_root) + [args.name]
    if args.level is not None:
        cmd += ["-l", str(args.level)]
    if args.template is not None:
        cmd += [ps_arg("--template"), str(args.template)]
    if getattr(args, "dry_run", False):
        cmd += [ps_arg("--dry-run")]
    if getattr(args, "worktree", False):
        cmd += [ps_arg("--worktree")]
    if getattr(args, "execution_mode", None) is not None:
        cmd += [ps_arg("--execution-mode"), str(args.execution_mode)]
    if getattr(args, "autonomy_budget", None) is not None:
        cmd += [ps_arg("--autonomy-budget"), str(args.autonomy_budget)]
    if getattr(args, "progressive", False):
        cmd += [ps_arg("--progressive")]
    if getattr(args, "with_reasoning", False):
        cmd += [ps_arg("--with-reasoning")]
    if getattr(args, "on_branch", False):
        cmd += [ps_arg("--on-branch")]

    try:
        result = subprocess.run(cmd, env=get_env(repo_root), cwd=repo_root)
        rc = result.returncode if result.returncode in (0, 1) else 2
    except Exception as exc:
        output.error(str(exc))
        return 2

    # Wave 23 §23.B.5 — record artifact-integrity hashes for any spec.md /
    # business-context.md the script produced. Best-effort; never blocks success.
    if rc == 0 and not getattr(args, "dry_run", False):
        try:
            from sdd.utils import artifact_integrity
            from sdd.utils.feature_resolver import resolve_feature_id

            feature_id = resolve_feature_id(repo_root, None) or args.name
            artifact_integrity.record_phase_artifacts(
                repo_root, feature_id, phase="1", written_by="sdd-new"
            )
        except Exception:
            pass

    # Wave 27 §26 #4 B.2 — seed spec.md from intent kernel when --from-brief is given.
    if rc == 0 and not getattr(args, "dry_run", False) and getattr(args, "from_brief", None):
        rc = _seed_spec_from_brief(repo_root, args.name, args.from_brief)

    return rc


def _seed_spec_from_brief(repo_root, feature_name: str, brief_file: str) -> int:
    """Wave 27 §26 #4 B.2 — prepend an intent-kernel block to spec.md.

    The kernel is an intake aid only (Constraint #4); it is inserted as a clearly
    labelled section BEFORE the spec body so Phase 1 work can refine / replace it.
    The spec/Gate 1 path is unchanged — the kernel never satisfies a gate.
    """
    from pathlib import Path

    brief_path = Path(brief_file) if Path(brief_file).is_absolute() else repo_root / brief_file
    if not brief_path.is_file():
        output.warn(f"--from-brief: file not found: {brief_file} — spec created without kernel.")
        return 0

    try:
        brief_text = brief_path.read_text(encoding="utf-8")
    except OSError as exc:
        output.warn(f"--from-brief: cannot read {brief_file}: {exc} — continuing without kernel.")
        return 0

    from sdd.utils.feature_resolver import resolve_feature_id
    from sdd.utils import artifact_integrity

    feature_id = resolve_feature_id(repo_root, None) or feature_name
    spec_candidates = list((repo_root / ".specify" / "specs").glob(f"*{feature_name}*/spec.md"))
    if not spec_candidates:
        spec_candidates = list((repo_root / ".specify" / "specs").glob(f"**/spec.md"))
    if not spec_candidates:
        output.warn("--from-brief: spec.md not found after scaffold — kernel not injected.")
        return 0

    spec_path = sorted(spec_candidates)[-1]  # pick the newest
    existing = spec_path.read_text(encoding="utf-8")

    truncated = brief_text[:2000]
    if len(brief_text) > 2000:
        truncated += "\n… [truncated — see source brief for full text]"

    kernel_block = (
        "\n\n---\n"
        "## Intent Kernel *(intake aid — not a primary artifact; see `intent-kernel` skill)*\n"
        "\n"
        "| Field | Content |\n"
        "|-------|---------|\n"
        "| Problem | [NEEDS CLARIFICATION from brief below] |\n"
        "| Capabilities | [NEEDS CLARIFICATION] |\n"
        "| Constraints | [NEEDS CLARIFICATION] |\n"
        "| Non-goals | [NEEDS CLARIFICATION] |\n"
        "| Success signal | [NEEDS CLARIFICATION] |\n"
        "\n"
        f"**Sources:** `{brief_file}`\n"
        "\n"
        "### Raw Brief\n"
        "\n"
        "```\n"
        f"{truncated}\n"
        "```\n"
        "\n"
        "> **Next step:** invoke `@requirement-analyst` or `@clarification` to fill in the\n"
        "> kernel fields and then write the full spec. The kernel is discardable once spec.md\n"
        "> is written. It does NOT satisfy Gate 1.\n"
        "---\n"
    )

    from sdd.io import atomic_write_text
    atomic_write_text(spec_path, existing + kernel_block)
    output.success(f"Intent kernel seeded into {spec_path.relative_to(repo_root)} (Wave 27 §26 #4).")
    output.info("REMINDER: the kernel is subordinate to spec.md and does NOT satisfy Gate 1.")
    return 0
