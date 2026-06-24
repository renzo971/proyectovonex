"""Shared policy-gate helpers for `sdd <noun> install` commands.

Wave 26 §25 #1 — A.5–A.9 wire each install path through `Policy.is_allowed`
BEFORE any disk write. Default-permissive: when no `.sdd-modules/policy.yaml`
exists, all installs proceed (preserves Wave 20 behaviour).
"""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Iterable

from sdd.utils import output


def gate_install(
    repo_root: Path,
    category: str,
    identifier: str,
    *,
    manifest_capabilities: Iterable[str] | None = None,
    explain: bool = False,
) -> int | None:
    """Run the policy gate for an install.

    Returns:
        - `None` when the gate passes and the caller should proceed.
        - An integer exit code when the gate denied (or `--explain-policy`
          dry-ran successfully — exit 0 in that case).

    The caller must NOT touch the filesystem until this returns `None`.
    """

    from sdd.policy import (
        PolicyError,
        PolicyResolutionError,
        load_policy,
        locate_policy_file,
    )
    from sdd.policy.loader import policy_to_dict

    policy_file = locate_policy_file(repo_root)

    if policy_file is None:
        # Default-permissive: no policy, no gate. Preserves prior behaviour.
        if explain:
            print(json.dumps({
                "category": category,
                "identifier": identifier,
                "decision": "allowed",
                "reason": "no policy file (default-permissive)",
                "policy_file": None,
            }, indent=2))
            return 0
        return None

    try:
        policy = load_policy(policy_file)
    except PolicyResolutionError as exc:
        output.error(f"Policy resolution failed: {exc}")
        return 2
    except PolicyError as exc:
        output.error(f"Policy error: {exc}")
        return 2

    allowed, reason = policy.is_allowed(
        category, identifier, manifest_capabilities=manifest_capabilities
    )

    if explain:
        payload = {
            "category": category,
            "identifier": identifier,
            "decision": "allowed" if allowed else "denied",
            "reason": reason,
            "policy_file": str(policy_file),
            "resolved": policy_to_dict(policy),
            "manifest_capabilities": list(manifest_capabilities or []),
        }
        print(json.dumps(payload, indent=2))
        return 0

    if not allowed:
        output.error(f"Install of {category[:-1]} '{identifier}' refused — {reason}")
        return 1

    output.info(f"Policy gate passed for {category[:-1]} '{identifier}'")
    return None


def read_module_capabilities(module_dir: Path) -> list[str]:
    """Read `capabilities` from a module's `module.json`, if present."""

    manifest = module_dir / "module.json"
    if not manifest.exists():
        return []
    try:
        data = json.loads(manifest.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError):
        return []
    caps = data.get("capabilities", [])
    if isinstance(caps, list):
        return [str(c) for c in caps]
    return []


def read_extension_capabilities(extension_dir: Path) -> list[str]:
    """Read `capabilities` from an extension's `sdd-extension.json`."""

    manifest = extension_dir / "sdd-extension.json"
    if not manifest.exists():
        return []
    try:
        data = json.loads(manifest.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError):
        return []
    caps = data.get("capabilities", [])
    if isinstance(caps, list):
        return [str(c) for c in caps]
    return []


def read_skill_capabilities(skill_dir: Path) -> list[str]:
    """Read `capabilities` from a skill descriptor.

    Skills declare capabilities in YAML frontmatter of `SKILL.md`.
    """

    skill_md = skill_dir / "SKILL.md"
    if not skill_md.exists():
        return []
    try:
        text = skill_md.read_text(encoding="utf-8")
    except OSError:
        return []
    if not text.startswith("---"):
        return []
    end = text.find("\n---", 3)
    if end == -1:
        return []
    frontmatter = text[3:end]
    try:
        import yaml
        data = yaml.safe_load(frontmatter) or {}
    except Exception:
        return []
    caps = data.get("capabilities", [])
    if isinstance(caps, list):
        return [str(c) for c in caps]
    return []
