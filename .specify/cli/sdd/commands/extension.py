"""`sdd extension validate|doctor <path>` — tailored extension diagnostics."""

from __future__ import annotations

import argparse
import subprocess
from pathlib import Path

from sdd.utils.config import find_repo_root, script_command, get_env, ps_arg
from sdd.utils import output


_ACTION_TO_SCRIPT: dict[str, str] = {
    "validate": "extension-validate",
    "doctor": "extension-doctor",
}


def add_extension_parser(subparsers: argparse._SubParsersAction) -> None:  # type: ignore[type-arg]
    p = subparsers.add_parser(
        "extension",
        help="validate and diagnose SDD extensions",
        description="Validate extension manifests and detect extension conflicts.",
    )
    es = p.add_subparsers(dest="extension_action", metavar="<action>")
    es.required = True

    validate_p = es.add_parser("validate", help="validate an extension manifest")
    validate_p.add_argument("path", metavar="<path>", help="path to extension directory")
    validate_p.add_argument(
        "--format",
        default="generic",
        choices=["generic", "tailored"],
        help="schema profile to enforce",
    )

    doctor_p = es.add_parser("doctor", help="diagnose extension conflicts")
    doctor_p.add_argument("path", metavar="<path>", help="path to extension directory")

    install_p = es.add_parser(
        "install",
        help="install an extension under .sdd-extensions/extensions/ (Wave 26 §25 #1 A.6)",
        description=(
            "Install an extension after evaluating the project policy "
            "(.sdd-modules/policy.yaml). When no policy is present the install "
            "is allowed (default-permissive)."
        ),
    )
    install_p.add_argument(
        "path", metavar="<path>", help="path to extension directory to install"
    )
    install_p.add_argument(
        "--explain-policy",
        dest="explain_policy",
        action="store_true",
        default=False,
        help="resolve policy + print decision (JSON) without installing",
    )
    from sdd.io import add_json_flags
    add_json_flags(p)


def run_extension(args: argparse.Namespace) -> int:
    from sdd.io import wrap_envelope
    return wrap_envelope(args, "extension", lambda: _run_extension_inner(args))


def _run_extension_inner(args: argparse.Namespace) -> int:
    action: str = args.extension_action

    try:
        repo_root = find_repo_root()
    except FileNotFoundError as exc:
        output.error(str(exc))
        return 2

    if action == "install":
        return _run_extension_install(args, repo_root)

    script_name = _ACTION_TO_SCRIPT.get(action)
    if script_name is None:
        output.error(f"Unknown extension action: {action}")
        return 2

    target = Path(args.path)
    cmd = script_command(script_name, repo_root) + [str(target)]
    if action == "validate":
        cmd += [ps_arg("--format"), str(getattr(args, "format", "generic"))]

    try:
        result = subprocess.run(cmd, env=get_env(repo_root), cwd=repo_root)
        rc = result.returncode if result.returncode in (0, 1) else 2
    except Exception as exc:
        output.error(str(exc))
        return 2

    # Wave 27 §26 #6 — FE design-contract token reference-integrity check.
    # Runs after the shell doctor script so shell findings appear first.
    if action == "doctor":
        _run_token_reference_check(target)

    return rc


def _run_extension_install(args, repo_root) -> int:
    """Install an extension after Wave 26 §25 #1 policy gate."""
    from sdd.policy.gate import gate_install, read_extension_capabilities

    src = Path(args.path).resolve()
    if not src.is_dir():
        output.error(f"Extension path is not a directory: {src}")
        return 2

    extension_id = src.name
    caps = read_extension_capabilities(src)
    explain = bool(getattr(args, "explain_policy", False))

    gate_exit = gate_install(
        repo_root,
        category="extensions",
        identifier=extension_id,
        manifest_capabilities=caps,
        explain=explain,
    )
    if gate_exit is not None:
        return gate_exit

    target_root = repo_root / ".sdd-extensions" / "extensions"
    target_root.mkdir(parents=True, exist_ok=True)
    target = target_root / extension_id
    if target.exists():
        output.warn(f"Extension already installed at {target}; refusing to overwrite")
        return 1

    import shutil
    try:
        shutil.copytree(src, target)
    except OSError as exc:
        output.error(f"Failed to install extension: {exc}")
        return 2

    output.success(f"Extension '{extension_id}' installed to {target.relative_to(repo_root)}")
    return 0


def _run_token_reference_check(extension_path: Path) -> None:
    """Wave 27 §26 #6 — FE design-contract token reference-integrity check.

    Scans ``experience*.md`` files under *extension_path* for ``{design-tokens.*}``
    references and verifies each token name exists in a companion
    ``design-tokens*.md`` file.  Unresolved tokens → WARN (INFO-only, never blocks).
    """
    import re

    ext_dir = Path(extension_path)
    if not ext_dir.is_dir():
        return  # nothing to check

    # Collect all declared token names from design-tokens files.
    token_name_re = re.compile(r"^\|\s*`([\w.]+)`")
    declared_tokens: set[str] = set()
    for dt_file in ext_dir.rglob("design-tokens*.md"):
        try:
            for line in dt_file.read_text(encoding="utf-8").splitlines():
                m = token_name_re.match(line)
                if m:
                    declared_tokens.add(m.group(1))
        except (OSError, UnicodeDecodeError):
            pass

    if not declared_tokens:
        # No design-tokens file present — nothing to validate against.
        return

    # Scan experience files for {design-tokens.TOKEN} references.
    ref_re = re.compile(r"\{design-tokens\.([\w.]+)\}")
    warned = False
    for exp_file in ext_dir.rglob("experience*.md"):
        try:
            text = exp_file.read_text(encoding="utf-8")
        except (OSError, UnicodeDecodeError):
            continue
        for ref_match in ref_re.finditer(text):
            token_key = ref_match.group(1)
            if token_key not in declared_tokens:
                rel = (
                    exp_file.relative_to(ext_dir)
                    if exp_file.is_relative_to(ext_dir)
                    else exp_file
                )
                output.warn(
                    f"[token-ref] unresolved token 'design-tokens.{token_key}' in "
                    f"{rel} — add the token to the companion design-tokens file "
                    "(Wave 27 §26 #6)"
                )
                warned = True

    if not warned:
        output.info("[token-ref] all design-token references resolved ✓")
