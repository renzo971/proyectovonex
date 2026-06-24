"""`sdd route <feature-id>` - show dynamic model routing per agent."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path
from typing import Any

from sdd.utils.config import find_repo_root
from sdd.utils import output

DEFAULT_MODEL_MAP: dict[str, str] = {
    "deep": "Claude Opus 4.6",
    "standard": "Claude Sonnet 4.6",
    "light": "Claude Sonnet 4.6",
}


def add_route_parser(subparsers: argparse._SubParsersAction) -> None:  # type: ignore[type-arg]
    p = subparsers.add_parser(
        "route",
        help="show model routing for a feature",
        description="Display the resolved model tier per agent for the given feature.",
    )
    p.add_argument("feature_id", metavar="<feature-id>", help="feature identifier")


def _resolve_model_map(repo_root: Path) -> dict[str, str]:
    constitution = repo_root / ".specify" / "memory" / "constitution.md"
    if not constitution.exists():
        return DEFAULT_MODEL_MAP.copy()

    text = constitution.read_text(encoding="utf-8")
    section_m = re.search(
        r"## Article VI: Model Configuration\s*\n(.*?)(?=\n## Article|\Z)",
        text,
        re.DOTALL,
    )
    if not section_m:
        return DEFAULT_MODEL_MAP.copy()

    section = section_m.group(1)
    mapping = DEFAULT_MODEL_MAP.copy()
    for tier in ("deep", "standard", "light"):
        m = re.search(
            rf"\|\s*{re.escape(tier)}\s*\|\s*[^|]+\|\s*([^|\n]+)\|",
            section,
            re.IGNORECASE,
        )
        if m:
            mapping[tier] = m.group(1).strip()
    return mapping


def _load_canonical_agents(repo_root: Path) -> list[dict[str, Any]]:
    # Prefer the composed agent set (core + module contributions) when available.
    # Fall back to agents-canonical.json for clean installs without any module contributions.
    composed_path = repo_root / ".specify" / "adapters" / "agents-composed.json"
    canonical_path = repo_root / ".specify" / "adapters" / "agents-canonical.json"

    if composed_path.exists():
        data = json.loads(composed_path.read_text(encoding="utf-8"))
    elif canonical_path.exists():
        data = json.loads(canonical_path.read_text(encoding="utf-8"))
    else:
        raise FileNotFoundError(
            f"Missing agent definitions: neither agents-composed.json nor agents-canonical.json found in .specify/adapters/"
        )

    return data.get("agents", [])


def _load_ceremony_level(repo_root: Path, feature_id: str) -> str:
    meta = repo_root / ".specify" / "specs" / feature_id / ".feature-meta.json"
    if not meta.exists():
        meta = repo_root / ".sdd" / "worktrees" / feature_id / ".specify" / "specs" / feature_id / ".feature-meta.json"
    if not meta.exists():
        raise FileNotFoundError(f"Feature metadata not found: {meta}")
    payload = json.loads(meta.read_text(encoding="utf-8-sig"))
    return str(payload.get("ceremonyLevel", "standard")).strip().lower()


def _resolve_tier(ceremony: str, agent_slug: str, recommended_tier: str) -> str:
    if ceremony == "ultra-light":
        return "light"
    if ceremony == "full":
        if agent_slug in {"analysis", "architect"}:
            return "deep"
        return "standard"
    if recommended_tier in {"deep", "standard", "light"}:
        return recommended_tier
    return "standard"


def run_route(args: argparse.Namespace) -> int:
    try:
        repo_root = find_repo_root()
        agents = _load_canonical_agents(repo_root)
        ceremony = _load_ceremony_level(repo_root, args.feature_id)
        model_map = _resolve_model_map(repo_root)
    except FileNotFoundError as exc:
        output.error(str(exc))
        return 2
    except json.JSONDecodeError as exc:
        output.error(f"Invalid JSON while resolving route: {exc}")
        return 2

    print(f"Feature: {args.feature_id}")
    print(f"Ceremony: {ceremony}")
    print("")

    for agent in sorted(agents, key=lambda item: str(item.get("slug", ""))):
        slug = str(agent.get("slug", "unknown"))
        recommended = str(agent.get("model-tier", "standard"))
        tier = _resolve_tier(ceremony, slug, recommended)
        model = model_map.get(tier, DEFAULT_MODEL_MAP["standard"])
        print(f"{slug} -> {tier} ({model})")

    return 0
