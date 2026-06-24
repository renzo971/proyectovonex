"""`sdd module install|remove|list|update` — manage SDD modules."""

from __future__ import annotations

import argparse
import subprocess

from sdd.utils.config import find_repo_root, script_command, get_env
from sdd.utils import output

_SUBCOMMANDS = ("install", "remove", "list", "update")

_SCRIPT_MAP: dict[str, str] = {
    "install": "module-install",
    "remove": "module-remove",
    "list": "module-list",
    "update": "module-install",  # update re-runs install with latest
}


def add_module_parser(subparsers: argparse._SubParsersAction) -> None:  # type: ignore[type-arg]
    p = subparsers.add_parser(
        "module",
        help="manage SDD modules",
        description="Install, remove, list, or update SDD modules.",
    )
    ms = p.add_subparsers(dest="module_action", metavar="<action>")
    ms.required = True

    inst = ms.add_parser("install", help="install a module")
    inst.add_argument("module_name", metavar="<name>", help="module name to install")
    inst.add_argument(
        "--explain-policy",
        dest="explain_policy",
        action="store_true",
        default=False,
        help="resolve policy + print decision (JSON) without installing (Wave 26 §25 #1 A.9)",
    )

    rem = ms.add_parser("remove", help="remove a module")
    rem.add_argument("module_name", metavar="<name>", help="module name to remove")

    ms.add_parser("list", help="list installed modules")

    upd = ms.add_parser("update", help="update an installed module")
    upd.add_argument("module_name", metavar="<name>", help="module name to update")

    ver = ms.add_parser(
        "verify",
        help="verify integrity of an installed module (Wave 20 §20.C.7)",
        description="Recompute file hashes for an installed module and report drift.",
    )
    ver.add_argument("module_name", metavar="<name>", help="module id from registry.json")
    ver_group = ver.add_mutually_exclusive_group()
    ver_group.add_argument(
        "--reset",
        action="store_true",
        help="re-install module from .sdd-modules/modules/<name>/ (overwrites local edits)",
    )
    ver_group.add_argument(
        "--accept",
        action="store_true",
        help="accept current state as new baseline (recompute and persist hashes)",
    )

    adopt = ms.add_parser(
        "adopt",
        help="bring an unmanaged on-disk module under registry control (Wave 27 §26 #3 A.14)",
        description=(
            "Review an unmanaged module directory (hash + Unicode scan), then register "
            "it in .sdd-modules/registry.json with per-file sha256."
        ),
    )
    adopt.add_argument("path", metavar="<path>", help="path to the unmanaged module directory")
    adopt.add_argument(
        "--version",
        dest="adopt_version",
        default="adopted",
        help="version label to record in the registry (default: adopted)",
    )
    from sdd.io import add_json_flags
    add_json_flags(p)


def run_module(args: argparse.Namespace) -> int:
    from sdd.io import wrap_envelope
    return wrap_envelope(args, "module", lambda: _run_module_inner(args))


def _run_module_inner(args: argparse.Namespace) -> int:
    try:
        repo_root = find_repo_root()
    except FileNotFoundError as exc:
        output.error(str(exc))
        return 2

    action: str = args.module_action

    if action == "verify":
        return _run_module_verify(args, repo_root)

    if action == "adopt":
        return _run_module_adopt(args, repo_root)

    if action in ("install", "update"):
        gate_exit = _module_policy_gate(args, repo_root, action)
        if gate_exit is not None:
            return gate_exit

    script_name = _SCRIPT_MAP.get(action)
    if script_name is None:
        output.error(f"Unknown module action: {action}")
        return 2

    cmd = script_command(script_name, repo_root)
    module_name = getattr(args, "module_name", None)
    if module_name:
        cmd.append(module_name)

    try:
        result = subprocess.run(cmd, env=get_env(repo_root), cwd=repo_root)
        return result.returncode if result.returncode in (0, 1) else 2
    except Exception as exc:
        output.error(str(exc))
        return 2


def _run_module_adopt(args, repo_root) -> int:
    """Wave 27 §26 #3 A.14 — adopt an unmanaged module directory."""
    from pathlib import Path
    from sdd.utils import artifact_adopt

    raw = Path(args.path)
    directory = raw if raw.is_absolute() else (repo_root / raw)
    if not directory.is_dir():
        output.error(f"Not a directory: {args.path}")
        return 2

    result = artifact_adopt.adopt_artifact(
        repo_root, directory, category="modules",
        version=getattr(args, "adopt_version", "adopted"),
    )
    for w in result["unicode_warnings"]:
        output.warn(f"Unicode scan: {w}")
    if result["already"]:
        output.info(f"Module '{result['name']}' already registered — no change.")
        return 0
    output.success(
        f"Adopted module '{result['name']}' ({result['files']} file(s), "
        f"manifest {result['manifest'][:12]}…) into registry.json."
    )
    return 0


def _run_module_verify(args, repo_root) -> int:
    """Verify hash integrity of an installed module (Wave 20 §20.C.7)."""
    from sdd.utils import module_integrity

    module_id = args.module_name
    if args.reset:
        output.info(f"Re-installing module '{module_id}' from source…")
        cmd = script_command("module-install", repo_root)
        cmd.append(module_id)
        result = subprocess.run(cmd, env=get_env(repo_root), cwd=repo_root)
        if result.returncode != 0:
            return 1
        output.success(f"Module '{module_id}' re-installed and baseline refreshed")
        return 0

    if args.accept:
        try:
            res = module_integrity.update_baseline(repo_root, module_id)
        except ValueError as exc:
            output.error(str(exc))
            return 1
        output.success(
            f"Accepted current state as new baseline for '{module_id}' "
            f"(manifest sha256: {(res.actual_manifest_sha256 or '')[:12]}…)"
        )
        return 0

    registry = module_integrity.load_registry(repo_root)
    entry = module_integrity.find_module(registry, module_id)
    if entry is None:
        output.error(f"Module '{module_id}' not found in registry.")
        return 1
    res = module_integrity.verify_module(repo_root, entry)
    if not res.has_baseline:
        output.warn(
            f"Module '{module_id}' has no hash baseline yet — run with --accept "
            f"to record one, or reinstall to populate hashes."
        )
        return 0
    if res.is_clean:
        output.success(
            f"Module '{module_id}' is clean (manifest sha256: "
            f"{(res.actual_manifest_sha256 or '')[:12]}…)"
        )
        return 0
    output.error(f"Module '{module_id}' has integrity drift:")
    for d in res.file_drifts:
        if d.actual is None:
            print(f"  - missing: {d.path}")
        else:
            print(f"  - drift:   {d.path}  ({d.expected[:8]} → {d.actual[:8]})")
    if (
        res.expected_manifest_sha256
        and res.actual_manifest_sha256
        and res.expected_manifest_sha256 != res.actual_manifest_sha256
        and not res.file_drifts
    ):
        print(f"  - manifest sha256 mismatch: "
              f"{res.expected_manifest_sha256[:12]} → {res.actual_manifest_sha256[:12]}")
    print()
    print("Resolve with `sdd module verify <id> --reset` (re-install from source) "
          "or `--accept` (record current state as new baseline).")
    return 1


def _module_policy_gate(args, repo_root, action: str) -> int | None:
    """Run Wave 26 §25 #1 policy gate before installing/updating a module.

    Returns `None` to proceed with the install, or an exit code to abort.
    """
    from sdd.policy.gate import gate_install, read_module_capabilities

    module_name = getattr(args, "module_name", None)
    if not module_name:
        return None

    module_dir = repo_root / ".sdd-modules" / "modules" / module_name
    caps = read_module_capabilities(module_dir) if module_dir.exists() else []

    explain = bool(getattr(args, "explain_policy", False))

    return gate_install(
        repo_root,
        category="modules",
        identifier=module_name,
        manifest_capabilities=caps,
        explain=explain,
    )
