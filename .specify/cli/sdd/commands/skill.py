"""`sdd skill` — local and curated skill operations."""

from __future__ import annotations

import argparse
import subprocess

from sdd.utils.config import find_repo_root, script_command, get_env, ps_arg
from sdd.utils import output


_SCRIPT_MAP: dict[str, str] = {
    "list": "skill-list",
    "validate": "skill-validate",
    "run": "skill-run",
    "validate-mapping": "validate-command-taxonomy",
}


def add_skill_parser(subparsers: argparse._SubParsersAction) -> None:  # type: ignore[type-arg]
    p = subparsers.add_parser(
        "skill",
        help="manage local SDD skills",
        description="List, validate, and run skills for the Enterprise SDD workflow.",
    )
    ss = p.add_subparsers(dest="skill_action", metavar="<action>")
    ss.required = True

    list_p = ss.add_parser("list", help="list available skills")
    list_p.add_argument(
        "--scope",
        dest="scope",
        metavar="<agent>",
        default=None,
        help="filter to skills visible to <agent> per .specify/skill-mapping.yaml (Wave 20 §20.C.3)",
    )
    list_p.add_argument(
        "--flat",
        dest="flat",
        action="store_true",
        default=False,
        help="show the full skill catalog (namespace meta-skills + sub-skills) instead of only the cold-start surface (Wave 23 §23.A.8)",
    )

    validate_p = ss.add_parser("validate", help="validate one skill descriptor")
    validate_p.add_argument("name", metavar="<name>", help="skill name without .skill.md suffix")
    validate_p.add_argument(
        "--rationalizations",
        action="store_true",
        default=False,
        help="also verify that the skill contains a non-empty '## Common Rationalizations' section",
    )
    validate_p.add_argument(
        "--eval",
        dest="eval_mode",
        action="store_true",
        default=False,
        help="run the behavioral evaluation manifest (.sdd-eval.yaml) for this skill and write SKILL-EVAL-REPORT.md",
    )

    run_p = ss.add_parser("run", help="run one curated skill against a feature")
    run_p.add_argument("name", metavar="<name>", help="skill name (for example: sdd-auto-implement)")
    run_p.add_argument("feature_id", metavar="<feature-id>", help="feature identifier")
    run_p.add_argument("--dry-run", action="store_true", help="validate and print run plan without executing")

    ss.add_parser(
        "validate-mapping",
        help="validate command taxonomy mapping and curated prompt alignment",
    )

    install_p = ss.add_parser(
        "install",
        help="install a skill under .github/skills/ (Wave 26 §25 #1 A.7)",
        description=(
            "Install a skill after evaluating the project policy "
            "(.sdd-modules/policy.yaml). When no policy is present the install "
            "is allowed (default-permissive)."
        ),
    )
    install_p.add_argument(
        "path", metavar="<path>", help="path to skill directory to install"
    )
    install_p.add_argument(
        "--explain-policy",
        dest="explain_policy",
        action="store_true",
        default=False,
        help="resolve policy + print decision (JSON) without installing",
    )

    adopt_p = ss.add_parser(
        "adopt",
        help="bring an unmanaged on-disk skill under registry control (Wave 27 §26 #3 A.14)",
        description=(
            "Review an unmanaged skill directory (hash + Unicode scan), then register "
            "it in .sdd-modules/registry.json with per-file sha256."
        ),
    )
    adopt_p.add_argument("path", metavar="<path>", help="path to the unmanaged skill directory")
    adopt_p.add_argument(
        "--version",
        dest="adopt_version",
        default="adopted",
        help="version label to record in the registry (default: adopted)",
    )


def run_skill(args: argparse.Namespace) -> int:
    action: str = args.skill_action

    if action == "adopt":
        try:
            repo_root = find_repo_root()
        except FileNotFoundError as exc:
            output.error(str(exc))
            return 2
        return _run_skill_adopt(args, repo_root)

    if action == "install":
        try:
            repo_root = find_repo_root()
        except FileNotFoundError as exc:
            output.error(str(exc))
            return 2
        return _run_skill_install(args, repo_root)

    script_name = _SCRIPT_MAP.get(action)
    if script_name is None:
        output.error(f"Unknown skill action: {action}")
        return 2

    try:
        repo_root = find_repo_root()
    except FileNotFoundError as exc:
        output.error(str(exc))
        return 2

    if action == "validate" and getattr(args, "eval_mode", False):
        return _run_skill_eval(args.name, repo_root)

    if action == "list" and getattr(args, "scope", None):
        return _run_skill_list_scoped(args.scope, repo_root)

    if action == "list" and getattr(args, "flat", False):
        # Wave 23 §23.A.8 — full catalog (namespace meta-skills + sub-skills).
        return _run_skill_list_flat(repo_root)

    if action == "list":
        # Wave 23 §23.A.7 — default cold-start surface (namespace meta-skills only).
        return _run_skill_list_cold_start(repo_root)

    cmd = script_command(script_name, repo_root)
    if action == "validate":
        cmd.append(args.name)
        if getattr(args, "rationalizations", False):
            cmd.append("--rationalizations")
    elif action == "run":
        cmd.extend([args.name, args.feature_id])
        if args.dry_run:
            cmd.append(ps_arg("--dry-run"))

    try:
        result = subprocess.run(cmd, env=get_env(repo_root), cwd=repo_root)
        return result.returncode if result.returncode in (0, 1) else 2
    except Exception as exc:
        output.error(str(exc))
        return 2


def _run_skill_install(args, repo_root) -> int:
    """Install a skill after Wave 26 §25 #1 A.7 policy gate."""
    from pathlib import Path
    from sdd.policy.gate import gate_install, read_skill_capabilities

    src = Path(args.path).resolve()
    if not src.is_dir():
        output.error(f"Skill path is not a directory: {src}")
        return 2

    skill_id = src.name
    caps = read_skill_capabilities(src)
    explain = bool(getattr(args, "explain_policy", False))

    gate_exit = gate_install(
        repo_root,
        category="skills",
        identifier=skill_id,
        manifest_capabilities=caps,
        explain=explain,
    )
    if gate_exit is not None:
        return gate_exit

    target_root = repo_root / ".github" / "skills"
    target_root.mkdir(parents=True, exist_ok=True)
    target = target_root / skill_id
    if target.exists():
        output.warn(f"Skill already installed at {target}; refusing to overwrite")
        return 1

    import shutil
    try:
        shutil.copytree(src, target)
    except OSError as exc:
        output.error(f"Failed to install skill: {exc}")
        return 2

    output.success(f"Skill '{skill_id}' installed to {target.relative_to(repo_root)}")
    return 0


def _run_skill_adopt(args, repo_root) -> int:
    """Wave 27 §26 #3 A.14 — adopt an unmanaged skill directory."""
    from pathlib import Path
    from sdd.utils import artifact_adopt

    raw = Path(args.path)
    directory = raw if raw.is_absolute() else (repo_root / raw)
    if not directory.is_dir():
        output.error(f"Not a directory: {args.path}")
        return 2
    if not (directory / "SKILL.md").exists():
        output.warn(f"No SKILL.md in {args.path} — adopting anyway.")

    result = artifact_adopt.adopt_artifact(
        repo_root, directory, category="skills",
        version=getattr(args, "adopt_version", "adopted"),
    )
    for w in result["unicode_warnings"]:
        output.warn(f"Unicode scan: {w}")
    if result["already"]:
        output.info(f"Skill '{result['name']}' already registered — no change.")
        return 0
    output.success(
        f"Adopted skill '{result['name']}' ({result['files']} file(s), "
        f"manifest {result['manifest'][:12]}…) into registry.json."
    )
    return 0


def _run_skill_eval(skill_name: str, repo_root) -> int:
    """Execute `.sdd-eval.yaml` for a skill and emit SKILL-EVAL-REPORT.md."""
    from sdd.utils import skill_eval

    try:
        result = skill_eval.run_eval(skill_name, repo_root)
    except Exception as exc:
        output.error(f"Skill eval failed: {exc}")
        return 2
    if result is None:
        output.warn(
            f"No .sdd-eval.yaml manifest found for skill '{skill_name}' — skipping (not failing)."
        )
        return 0
    report_path = skill_eval.write_report([result], repo_root)
    output.info(f"Wrote {report_path.relative_to(repo_root)}")
    if not result.threshold_met:
        output.error(
            f"Skill '{skill_name}' eval pass-rate {result.pass_rate:.0%} below threshold "
            f"{result.pass_threshold:.0%}"
        )
        return 1
    output.success(f"Skill '{skill_name}' eval pass-rate {result.pass_rate:.0%} (threshold met)")
    return 0



def _run_skill_list_scoped(agent: str, repo_root) -> int:
    """List skills filtered by agent scope per .specify/skill-mapping.yaml."""
    from sdd.utils import skill_mapping

    entries = skill_mapping.load_mapping(repo_root)
    if not entries:
        output.warn(
            "No .specify/skill-mapping.yaml found — scope filter cannot be applied."
        )
        return 0

    visible = skill_mapping.filter_for_agent(entries, agent)
    print(f"Enterprise SDD — Skills visible to agent '{agent}'")
    print("=" * 60)
    print(f"{'NAME':<28} {'CATEGORY':<10} {'SCOPES':<28} PURPOSE")
    print(f"{'-' * 28:<28} {'-' * 10:<10} {'-' * 28:<28} -------")
    for e in visible:
        scopes_disp = ",".join(e.scopes) if e.scopes else "(global)"
        print(f"{e.id:<28} {e.category:<10} {scopes_disp:<28} {e.purpose}")
    print()
    print(f"{len(visible)} of {len(entries)} skills visible to '{agent}'")
    return 0


def _run_skill_list_cold_start(repo_root) -> int:
    """Wave 23 §23.A.7 — default `sdd skill list` shows the cold-start surface.

    Falls back to the legacy shell-script enumeration when the cold-start
    surface marker is absent (backward compatible).
    """
    from sdd.utils import skill_mapping

    entries = skill_mapping.load_mapping(repo_root)
    surface_ids = skill_mapping.load_cold_start_surface(repo_root)

    if not surface_ids:
        # No cold-start marker — fall through to legacy script-based output.
        cmd = script_command("skill-list", repo_root)
        try:
            result = subprocess.run(cmd, env=get_env(repo_root), cwd=repo_root)
            return result.returncode if result.returncode in (0, 1) else 2
        except Exception as exc:
            output.error(str(exc))
            return 2

    by_id = {e.id: e for e in entries}
    print("Enterprise SDD — Cold-Start Skill Surface (Wave 23)")
    print("=" * 60)
    print(f"{'NAME':<22} {'CATEGORY':<12} PURPOSE")
    print(f"{'-' * 22:<22} {'-' * 12:<12} -------")
    for sid in surface_ids:
        e = by_id.get(sid)
        if e is None:
            print(f"{sid:<22} {'(missing)':<12} (declared in coldStartSurface but not in skills:)")
            continue
        print(f"{e.id:<22} {e.category:<12} {e.purpose}")
    print()
    total = len(entries)
    print(f"{len(surface_ids)} cold-start meta-skills shown ({total} total skills available)")
    print("Run `sdd skill list --flat` for the full catalog.")
    return 0


def _run_skill_list_flat(repo_root) -> int:
    """Wave 23 §23.A.8 — full catalog: filesystem-discovered skills + namespace meta-skills."""
    from sdd.utils import skill_mapping

    entries = skill_mapping.load_mapping(repo_root)
    by_id = {e.id: e for e in entries}

    fs_skills: dict[str, str] = {}  # id -> source dir label
    for label, base in (
        ("github", repo_root / ".github" / "skills"),
        ("specify", repo_root / ".specify" / "skills"),
    ):
        if not base.exists():
            continue
        for d in sorted(base.iterdir()):
            if d.is_dir() and (d / "SKILL.md").exists():
                fs_skills.setdefault(d.name, label)

    all_ids = sorted(set(fs_skills.keys()) | set(by_id.keys()))

    print("Enterprise SDD — Full Skill Catalog (--flat)")
    print("=" * 70)
    print(f"{'NAME':<32} {'CATEGORY':<12} {'SOURCE':<10} PURPOSE")
    print(f"{'-' * 32:<32} {'-' * 12:<12} {'-' * 10:<10} -------")
    for sid in all_ids:
        e = by_id.get(sid)
        cat = e.category if e else "(filesystem)"
        purpose = e.purpose if e else ""
        source = fs_skills.get(sid, "(yaml only)")
        print(f"{sid:<32} {cat:<12} {source:<10} {purpose}")
    print()
    namespace_count = sum(1 for e in entries if e.category == "namespace")
    print(
        f"{len(all_ids)} total skills "
        f"({namespace_count} namespace meta-skills + {len(all_ids) - namespace_count} sub-skills/local)"
    )
    return 0
