"""Policy loader with `extends:` resolution and ternary inheritance.

Wave 26 §25 #1 — Module/Extension Governance-as-Config.

Schema: `.specify/schemas/policy.schema.json`

Ternary semantics for `allow`/`deny` per category (`modules`, `skills`,
`extensions`, `capabilities`):

- field absent / value is `None` → inherit verbatim from the parent
- value is `[]` (empty list) → explicit override (block parent's set for
  that category)
- value is `[items]` → explicit list

Inheritance combinator (tighten-only):

- For an *allowlist*: child intersects with parent's allowlist.
  When the parent has no allowlist (i.e., everything allowed by default),
  the child's list becomes authoritative on its own.
- For a *denylist*: child's denylist is the union with the parent's.

Cycle detection is capped at 8 levels.
"""

from __future__ import annotations

import json
from dataclasses import dataclass, field
from pathlib import Path
from typing import Iterable

try:  # pragma: no cover - import guard
    import yaml
except ImportError as exc:  # pragma: no cover
    raise ImportError(
        "PyYAML is required for policy loading. Install with `pip install pyyaml`."
    ) from exc


_MAX_EXTENDS_DEPTH = 8

CATEGORY_KEYS = ("modules", "skills", "extensions")


class PolicyError(Exception):
    """Base class for policy errors."""


class PolicySchemaError(PolicyError):
    """Raised when a policy file fails schema validation."""


class PolicyResolutionError(PolicyError):
    """Raised when `extends:` chain resolution fails (cycle, missing parent, depth)."""


@dataclass
class _CategoryRule:
    """Internal representation of one category's allow/deny lists.

    `allow=None` means "no allowlist constraint at this level"; an empty
    list means "explicit empty allowlist" (block everything).
    """

    allow: list[str] | None = None
    deny: list[str] = field(default_factory=list)


@dataclass
class Policy:
    """Resolved policy after `extends:` chain has been merged.

    `source_chain` lists the policy file paths from root → leaf for trace
    reasons.
    """

    rules: dict[str, _CategoryRule]
    capabilities_deny: list[str]
    source_chain: list[Path]

    # ------------------------------------------------------------------
    # Decision API
    # ------------------------------------------------------------------

    def is_allowed(
        self,
        category: str,
        identifier: str,
        *,
        manifest_capabilities: Iterable[str] | None = None,
    ) -> tuple[bool, str]:
        """Return `(allowed, reason)` for installing `identifier` under `category`.

        `manifest_capabilities` lets callers declare what the artifact would
        do (e.g. `["shell-exec"]`); any intersection with `capabilities_deny`
        causes refusal regardless of allowlist match.
        """

        if category not in CATEGORY_KEYS:
            raise ValueError(f"Unknown policy category: {category!r}")

        # 1. Capability denial trumps everything.
        if manifest_capabilities:
            denied = sorted(set(manifest_capabilities) & set(self.capabilities_deny))
            if denied:
                trace = self._format_chain()
                return (
                    False,
                    f"denied: capabilities {denied} are denied by `capabilities.deny` "
                    f"(policy chain: {trace})",
                )

        rule = self.rules.get(category, _CategoryRule())

        # 2. Explicit deny wins.
        if identifier in rule.deny:
            trace = self._format_chain()
            return (
                False,
                f"denied: '{identifier}' appears in `{category}.deny` "
                f"(policy chain: {trace})",
            )

        # 3. Allowlist enforcement.
        if rule.allow is not None and identifier not in rule.allow:
            trace = self._format_chain()
            if not rule.allow:
                return (
                    False,
                    f"denied: `{category}.allow` is explicitly empty — no {category} permitted "
                    f"(policy chain: {trace})",
                )
            return (
                False,
                f"denied: '{identifier}' not in `{category}.allow` "
                f"(policy chain: {trace})",
            )

        return (True, f"allowed by policy chain: {self._format_chain()}")

    def _format_chain(self) -> str:
        return " ← ".join(str(p) for p in self.source_chain) or "<inline>"


# ----------------------------------------------------------------------
# Public loader
# ----------------------------------------------------------------------


def locate_policy_file(repo_root: Path) -> Path | None:
    """Return the project policy file if present, else `None`.

    Looks for `.sdd-modules/policy.yaml` (Wave 26 canonical location).
    """

    candidate = repo_root / ".sdd-modules" / "policy.yaml"
    return candidate if candidate.exists() else None


def load_policy(path: Path) -> Policy:
    """Load a policy from `path`, resolving `extends:` recursively.

    Raises `PolicySchemaError` on invalid structure and
    `PolicyResolutionError` on cycle / missing-parent / depth-exceeded.
    """

    chain: list[Path] = []
    visited: set[Path] = set()
    return _load_with_chain(path.resolve(), chain, visited, depth=0)


def _load_with_chain(
    path: Path,
    chain: list[Path],
    visited: set[Path],
    *,
    depth: int,
) -> Policy:
    if depth > _MAX_EXTENDS_DEPTH:
        raise PolicyResolutionError(
            f"`extends:` chain exceeds maximum depth of {_MAX_EXTENDS_DEPTH}"
        )

    if path in visited:
        raise PolicyResolutionError(
            f"`extends:` cycle detected at {path}"
        )

    if not path.exists():
        raise PolicyResolutionError(f"Policy file not found: {path}")

    visited.add(path)

    try:
        raw = yaml.safe_load(path.read_text(encoding="utf-8"))
    except yaml.YAMLError as exc:
        raise PolicySchemaError(f"YAML parse error in {path}: {exc}") from exc

    if raw is None:
        raw = {}
    if not isinstance(raw, dict):
        raise PolicySchemaError(f"Policy {path} root must be a mapping")

    _validate_shape(raw, path)

    extends = raw.get("extends")
    fetch_failure_default = str(raw.get("fetch_failure_default") or "block").lower()

    parent: Policy | None = None
    if extends is not None:
        parent_path = (path.parent / str(extends)).resolve()
        try:
            parent = _load_with_chain(parent_path, list(chain), set(visited), depth=depth + 1)
        except PolicyResolutionError:
            if fetch_failure_default == "warn":
                parent = None  # treat as root
            else:
                raise

    rules: dict[str, _CategoryRule] = {}
    for category in CATEGORY_KEYS:
        parent_rule = parent.rules.get(category, _CategoryRule()) if parent else _CategoryRule()
        rules[category] = _merge_category(raw.get(category), parent_rule)

    capabilities_deny = _merge_capabilities(
        raw.get("capabilities"),
        parent.capabilities_deny if parent else [],
    )

    source_chain: list[Path] = []
    if parent is not None:
        source_chain.extend(parent.source_chain)
    source_chain.append(path)

    return Policy(
        rules=rules,
        capabilities_deny=capabilities_deny,
        source_chain=source_chain,
    )


# ----------------------------------------------------------------------
# Internals
# ----------------------------------------------------------------------


def _validate_shape(raw: dict, path: Path) -> None:
    """Lightweight schema check (no external jsonschema dependency).

    Enforces the same `additionalProperties: false` invariant as the JSON
    Schema so typos like `denny:` instead of `deny:` are rejected.
    """

    allowed_top = {
        "schema_version",
        "extends",
        "fetch_failure_default",
        "modules",
        "skills",
        "extensions",
        "capabilities",
    }
    extras = set(raw.keys()) - allowed_top
    if extras:
        raise PolicySchemaError(
            f"Unknown top-level keys in {path}: {sorted(extras)} (likely typo)"
        )

    if "schema_version" in raw and raw["schema_version"] != 1:
        raise PolicySchemaError(
            f"Unsupported schema_version in {path}: {raw['schema_version']!r} (expected 1)"
        )

    for category in CATEGORY_KEYS:
        section = raw.get(category)
        if section is None:
            continue
        if not isinstance(section, dict):
            raise PolicySchemaError(
                f"`{category}` in {path} must be a mapping"
            )
        extras = set(section.keys()) - {"allow", "deny"}
        if extras:
            raise PolicySchemaError(
                f"Unknown keys under `{category}` in {path}: {sorted(extras)}"
            )
        for field_name in ("allow", "deny"):
            value = section.get(field_name)
            if value is None:
                continue
            if not isinstance(value, list) or not all(isinstance(x, str) for x in value):
                raise PolicySchemaError(
                    f"`{category}.{field_name}` in {path} must be a list of strings or null"
                )

    caps = raw.get("capabilities")
    if caps is not None:
        if not isinstance(caps, dict):
            raise PolicySchemaError(f"`capabilities` in {path} must be a mapping")
        extras = set(caps.keys()) - {"deny"}
        if extras:
            raise PolicySchemaError(
                f"Unknown keys under `capabilities` in {path}: {sorted(extras)}"
            )
        deny = caps.get("deny")
        if deny is not None and (
            not isinstance(deny, list) or not all(isinstance(x, str) for x in deny)
        ):
            raise PolicySchemaError(
                f"`capabilities.deny` in {path} must be a list of strings or null"
            )


def _merge_category(raw_section, parent_rule: _CategoryRule) -> _CategoryRule:
    """Apply ternary semantics to one category."""

    if raw_section is None:
        # field absent → inherit verbatim
        return _CategoryRule(
            allow=list(parent_rule.allow) if parent_rule.allow is not None else None,
            deny=list(parent_rule.deny),
        )

    raw_allow = raw_section.get("allow") if isinstance(raw_section, dict) else None
    raw_deny = raw_section.get("deny") if isinstance(raw_section, dict) else None

    # Allow combinator
    if raw_allow is None:
        merged_allow = (
            list(parent_rule.allow) if parent_rule.allow is not None else None
        )
    elif raw_allow == []:
        # explicit empty override → no items allowed
        merged_allow = []
    else:
        if parent_rule.allow is None:
            merged_allow = list(raw_allow)
        else:
            # tighten-only: intersect with parent
            merged_allow = [item for item in raw_allow if item in parent_rule.allow]

    # Deny combinator (always tightens via union)
    if raw_deny is None:
        merged_deny = list(parent_rule.deny)
    elif raw_deny == []:
        merged_deny = list(parent_rule.deny)  # explicit empty does not relax denies
    else:
        merged_deny = sorted(set(parent_rule.deny) | set(raw_deny))

    return _CategoryRule(allow=merged_allow, deny=merged_deny)


def _merge_capabilities(raw_caps, parent_deny: list[str]) -> list[str]:
    if raw_caps is None:
        return list(parent_deny)
    deny = raw_caps.get("deny") if isinstance(raw_caps, dict) else None
    if deny is None:
        return list(parent_deny)
    return sorted(set(parent_deny) | set(deny))


def policy_to_dict(policy: Policy) -> dict:
    """Serialise a resolved policy for `--explain-policy` JSON output."""

    return {
        "source_chain": [str(p) for p in policy.source_chain],
        "modules": {
            "allow": policy.rules["modules"].allow,
            "deny": policy.rules["modules"].deny,
        },
        "skills": {
            "allow": policy.rules["skills"].allow,
            "deny": policy.rules["skills"].deny,
        },
        "extensions": {
            "allow": policy.rules["extensions"].allow,
            "deny": policy.rules["extensions"].deny,
        },
        "capabilities": {"deny": policy.capabilities_deny},
    }


__all__ = [
    "CATEGORY_KEYS",
    "Policy",
    "PolicyError",
    "PolicyResolutionError",
    "PolicySchemaError",
    "load_policy",
    "locate_policy_file",
    "policy_to_dict",
]
