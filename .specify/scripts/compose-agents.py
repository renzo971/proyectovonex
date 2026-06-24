#!/usr/bin/env python3
"""compose-agents.py — Compose the effective agent set from core canonical + module contributions.

Reads:
  .specify/adapters/agents-canonical.json  (core agents — never modified by modules)
  .sdd-modules/registry.json               (installed modules)
  .sdd-modules/modules/<name>/module.json  (per-module agentContributions)

Writes:
  .specify/adapters/agents-composed.json   (effective agent set used by generate-adapters.py)

Agent composition rules:
  1. Start with the full core agent list from agents-canonical.json.
  2. For each installed module (in registry order), if module.json contains
     'agentContributions.tool-overlays', append those tools to the matching
     core agent's tools list (deduplication: no-op if already present).
  3. For each installed module, if module.json contains
     'agentContributions.agents', append those agents to the composed list.
  4. Validate: no duplicate slugs across core + all contributed agents.
  5. Write agents-composed.json with a composition manifest header.

Usage:
  python compose-agents.py [--repo-root <path>] [--dry-run] [--verbose]
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any


# ---------------------------------------------------------------------------
# Core helpers
# ---------------------------------------------------------------------------

def find_repo_root(start: Path | None = None) -> Path:
    """Walk up from start (or cwd) to find the repo root (.specify/ dir)."""
    candidate = (start or Path.cwd()).resolve()
    for path in [candidate, *candidate.parents]:
        if (path / ".specify").is_dir():
            return path
    raise FileNotFoundError(
        "Could not locate repo root (no .specify/ directory found in path tree)"
    )


def load_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


# ---------------------------------------------------------------------------
# Composition logic
# ---------------------------------------------------------------------------

def compose_agents(repo_root: Path, verbose: bool = False) -> dict[str, Any]:
    """Read canonical + module contributions and return the composed agent dict."""

    # 1. Load core canonical
    canonical_path = repo_root / ".specify" / "adapters" / "agents-canonical.json"
    if not canonical_path.exists():
        print(f"ERROR: agents-canonical.json not found at {canonical_path}", file=sys.stderr)
        sys.exit(2)
    canonical = load_json(canonical_path)
    agents: list[dict[str, Any]] = [dict(a) for a in canonical["agents"]]

    # Index by slug for fast lookup
    slug_index: dict[str, int] = {a["slug"]: i for i, a in enumerate(agents)}

    # Track contributions for the manifest
    applied_overlays: list[dict[str, Any]] = []
    contributed_agents: list[str] = []

    # 2. Load registry
    registry_path = repo_root / ".sdd-modules" / "registry.json"
    if not registry_path.exists():
        if verbose:
            print("No registry.json found — composing core-only (no modules installed).")
        return _build_output(canonical, agents, applied_overlays, contributed_agents)

    registry = load_json(registry_path)
    installed_modules: list[dict[str, Any]] = registry.get("installedModules", [])

    if not installed_modules:
        if verbose:
            print("No modules installed — composing core-only.")
        return _build_output(canonical, agents, applied_overlays, contributed_agents)

    # 3. Process each module
    for module_entry in installed_modules:
        module_name = module_entry.get("name", "")
        module_json_path = repo_root / ".sdd-modules" / "modules" / module_name / "module.json"

        if not module_json_path.exists():
            if verbose:
                print(f"  [skip] {module_name}: no module.json found")
            continue

        module_manifest = load_json(module_json_path)
        contributions: dict[str, Any] = module_manifest.get("agentContributions", {})

        if not contributions:
            if verbose:
                print(f"  [skip] {module_name}: no agentContributions")
            continue

        if verbose:
            print(f"  [process] {module_name}")

        # 3a. Apply tool overlays
        for overlay in contributions.get("tool-overlays", []):
            target_slug = overlay.get("target-agent", "")
            add_tools: list[str] = overlay.get("add-tools", [])

            if target_slug not in slug_index:
                print(
                    f"  WARNING: {module_name} overlay targets unknown agent '{target_slug}' — skipped",
                    file=sys.stderr,
                )
                continue

            idx = slug_index[target_slug]
            existing_tools: list[str] = agents[idx].setdefault("tools", [])
            new_tools = [t for t in add_tools if t not in existing_tools]
            existing_tools.extend(new_tools)

            applied_overlays.append({
                "module": module_name,
                "target-agent": target_slug,
                "added-tools": new_tools,
                "skipped-duplicates": [t for t in add_tools if t not in new_tools],
            })

            if verbose and new_tools:
                print(f"    overlay: {target_slug} ← {new_tools}")

        # 3b. Append contributed agents
        for agent_def in contributions.get("agents", []):
            slug = agent_def.get("slug", "")
            if not slug:
                print(
                    f"  WARNING: {module_name} contributed agent missing 'slug' — skipped",
                    file=sys.stderr,
                )
                continue

            if slug in slug_index:
                print(
                    f"  WARNING: {module_name} contributes agent '{slug}' but slug already exists — skipped",
                    file=sys.stderr,
                )
                continue

            agents.append(dict(agent_def))
            slug_index[slug] = len(agents) - 1
            contributed_agents.append(f"{module_name}:{slug}")

            if verbose:
                print(f"    agent: +{slug} (from {module_name})")

    return _build_output(canonical, agents, applied_overlays, contributed_agents)


def _build_output(
    canonical: dict[str, Any],
    agents: list[dict[str, Any]],
    applied_overlays: list[dict[str, Any]],
    contributed_agents: list[str],
) -> dict[str, Any]:
    return {
        "$schema": "../schemas/agent-definition.schema.json",
        "$generated-by": "compose-agents.py",
        "$note": "Auto-generated — do not edit directly. Modify agents-canonical.json or module.json agentContributions.",
        "coreAgentCount": sum(1 for a in agents if a.get("slug") not in {c.split(":")[1] for c in contributed_agents}),
        "totalAgentCount": len(agents),
        "appliedOverlays": applied_overlays,
        "contributedAgents": contributed_agents,
        "agents": agents,
    }


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Compose the effective agent set from core canonical + module contributions."
    )
    parser.add_argument(
        "--repo-root",
        type=Path,
        default=None,
        help="Path to the repository root. Auto-detected if not supplied.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print the composed output to stdout instead of writing agents-composed.json.",
    )
    parser.add_argument(
        "--verbose", "-v",
        action="store_true",
        help="Print composition steps.",
    )
    args = parser.parse_args(argv)

    try:
        repo_root = find_repo_root(args.repo_root) if args.repo_root is None else args.repo_root.resolve()
    except FileNotFoundError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 2

    if args.verbose:
        print(f"Repo root: {repo_root}")

    composed = compose_agents(repo_root, verbose=args.verbose)

    if args.dry_run:
        print(json.dumps(composed, indent=2, ensure_ascii=False))
        return 0

    output_path = repo_root / ".specify" / "adapters" / "agents-composed.json"
    output_path.write_text(json.dumps(composed, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    total = composed["totalAgentCount"]
    core = composed["coreAgentCount"]
    module_count = total - core
    overlay_count = len(composed["appliedOverlays"])
    print(
        f"✅ agents-composed.json written: {core} core + {module_count} module agents, "
        f"{overlay_count} tool overlay(s) applied"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
