#!/usr/bin/env python3
"""generate-adapters.py — generate IDE adapter files from canonical agent definitions.

Reads:
  .specify/adapters/agents-canonical.json
  .specify/memory/constitution.md  (Article VI for model-tier → model mapping)

Generates adapters for:
  VS Code (Copilot): .github/agents/*.agent.md        (validate / regenerate frontmatter)
  Cursor:            .cursor/rules/*.mdc
  Claude Code:       .claude/commands/*.md + CLAUDE.md
  Windsurf:          .windsurfrules
  Codex:             agents.md
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from textwrap import dedent
from typing import Any

# ---------------------------------------------------------------------------
# Model-tier → concrete model mapping
# (can be overridden by Article VI in constitution.md)
# ---------------------------------------------------------------------------
DEFAULT_MODEL_MAP: dict[str, str] = {
    "deep": "Claude Opus 4.6",
    "standard": "Claude Sonnet 4.6",
    "light": "Claude Sonnet 4.6",
}


def resolve_routed_tier(ceremony: str, agent_slug: str, recommended_tier: str) -> str:
    """Resolve effective model tier from ceremony + agent role."""
    if ceremony == "ultra-light":
        return "light"
    if ceremony == "full":
        if agent_slug in {"analysis", "architect"}:
            return "deep"
        return "standard"
    if recommended_tier in {"deep", "standard", "light"}:
        return recommended_tier
    return "standard"


def load_feature_ceremony(repo_root: Path, feature_id: str) -> str:
    meta_path = repo_root / ".specify" / "specs" / feature_id / ".feature-meta.json"
    if not meta_path.exists():
        meta_path = repo_root / ".sdd" / "worktrees" / feature_id / ".specify" / "specs" / feature_id / ".feature-meta.json"
    if not meta_path.exists():
        raise FileNotFoundError(f"Feature metadata not found: {meta_path}")
    payload = json.loads(meta_path.read_text(encoding="utf-8-sig"))
    return str(payload.get("ceremonyLevel", "standard")).strip().lower()


def apply_dynamic_routing(agents: list[dict[str, Any]], ceremony: str) -> list[dict[str, Any]]:
    routed: list[dict[str, Any]] = []
    for agent in agents:
        updated = dict(agent)
        slug = str(updated.get("slug", ""))
        recommended = str(updated.get("model-tier", "standard"))
        updated["model-tier"] = resolve_routed_tier(ceremony, slug, recommended)
        routed.append(updated)
    return routed


def resolve_model_map(repo_root: Path) -> dict[str, str]:
    """Try to read Article VI from constitution.md; fall back to defaults."""
    constitution = repo_root / ".specify" / "memory" / "constitution.md"
    if not constitution.exists():
        return DEFAULT_MODEL_MAP.copy()

    text = constitution.read_text()
    # Look for an Article VI: Model Configuration section
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
        # Skip Provider column and capture the Model column (third column)
        tier_pat = re.escape(tier)
        m = re.search(rf"\|\s*{tier_pat}\s*\|\s*[^|]+\|\s*([^|\n]+)\|", section, re.IGNORECASE)
        if m:
            mapping[tier] = m.group(1).strip()

    return mapping


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def load_canonical(repo_root: Path) -> list[dict[str, Any]]:
    # Prefer the composed agent set (core + module contributions) when available.
    # Fall back to agents-canonical.json for clean installs without any module contributions.
    composed_path = repo_root / ".specify" / "adapters" / "agents-composed.json"
    canonical_path = repo_root / ".specify" / "adapters" / "agents-canonical.json"

    if composed_path.exists():
        data = json.loads(composed_path.read_text())
    elif canonical_path.exists():
        data = json.loads(canonical_path.read_text())
    else:
        print(f"ERROR: neither agents-composed.json nor agents-canonical.json found in .specify/adapters/", file=sys.stderr)
        sys.exit(2)

    return data["agents"]


def slug_to_title(slug: str) -> str:
    return slug.replace("-", " ").title()


def tools_yaml(tools: list[str]) -> str:
    return "[" + ", ".join(f"'{t}'" for t in tools) + "]"


# ---------------------------------------------------------------------------
# VS Code / Copilot adapter  (.github/agents/*.agent.md)
# ---------------------------------------------------------------------------

def generate_vscode(
    agents: list[dict[str, Any]],
    model_map: dict[str, str],
    repo_root: Path,
    dry_run: bool,
) -> int:
    agents_dir = repo_root / ".github" / "agents"
    agents_dir.mkdir(parents=True, exist_ok=True)
    written = 0

    for agent in agents:
        slug: str = agent["slug"]
        tier: str = agent.get("model-tier", "standard")
        model: str = model_map.get(tier, DEFAULT_MODEL_MAP["standard"])
        path = agents_dir / f"{slug}.agent.md"

        if not path.exists():
            print(f"  SKIP  {path.name} (file not found — not regenerating)")
            continue

        text = path.read_text()

        # Update model: line to match resolved model
        updated = re.sub(
            r"^(model:\s*)(.+)$",
            lambda m: f"{m.group(1)}{model}",
            text,
            flags=re.MULTILINE,
        )
        # Ensure model-tier is present after model: line
        if "model-tier:" not in updated:
            updated = re.sub(
                r"^(model:\s*.+)$",
                lambda m: m.group(0) + f"\nmodel-tier: {tier}",
                updated,
                flags=re.MULTILINE,
            )
        else:
            updated = re.sub(
                r"^model-tier:\s*.+$",
                f"model-tier: {tier}",
                updated,
                flags=re.MULTILINE,
            )

        if updated == text:
            print(f"  OK    {path.name}")
            continue

        if dry_run:
            print(f"  WOULD UPDATE  {path.name}")
        else:
            path.write_text(updated)
            print(f"  UPDATED  {path.name}")
        written += 1

    return written


# ---------------------------------------------------------------------------
# Cursor adapter  (.cursor/rules/*.mdc)
# ---------------------------------------------------------------------------

def _cursor_mdc(agent: dict[str, Any], model_map: dict[str, str]) -> str:
    name: str = agent["name"]
    desc: str = agent.get("description", "")
    tools: list[str] = agent.get("tools", [])
    tier: str = agent.get("model-tier", "standard")
    model: str = model_map.get(tier, DEFAULT_MODEL_MAP["standard"])
    phase: str = agent.get("phase", "")
    instructions: list[str] = agent.get("instructions", [])

    instr_block = "\n".join(f"  - {i}" for i in instructions) if instructions else "  []"

    return dedent(f"""\
        ---
        description: {desc.splitlines()[0] if desc else name}
        globs: []
        alwaysApply: false
        ---

        # {name} Agent

        **Phase:** {phase}
        **Model:** {model} (tier: {tier})
        **Tools:** {', '.join(tools)}

        ## Instructions

        {instr_block}

        ## Description

        {desc}
        """)


def generate_cursor(
    agents: list[dict[str, Any]],
    model_map: dict[str, str],
    repo_root: Path,
    dry_run: bool,
) -> int:
    rules_dir = repo_root / ".cursor" / "rules"
    rules_dir.mkdir(parents=True, exist_ok=True)
    written = 0

    for agent in agents:
        slug: str = agent["slug"]
        path = rules_dir / f"{slug}.mdc"
        content = _cursor_mdc(agent, model_map)

        if path.exists() and path.read_text() == content:
            print(f"  OK    {path.name}")
            continue

        if dry_run:
            print(f"  WOULD WRITE  {path.name}")
        else:
            path.write_text(content)
            print(f"  WRITE  {path.name}")
        written += 1

    return written


# ---------------------------------------------------------------------------
# Claude Code adapter  (.claude/commands/*.md + CLAUDE.md)
# ---------------------------------------------------------------------------

def _claude_command_md(agent: dict[str, Any], model_map: dict[str, str]) -> str:
    name: str = agent["name"]
    slug: str = agent["slug"]
    desc: str = agent.get("description", "")
    tier: str = agent.get("model-tier", "standard")
    model: str = model_map.get(tier, DEFAULT_MODEL_MAP["standard"])
    phase: str = agent.get("phase", "")
    tools: list[str] = agent.get("tools", [])
    instructions: list[str] = agent.get("instructions", [])
    handoffs: list[dict] = agent.get("handoffs", [])

    instr_lines = "\n".join(f"- {i}" for i in instructions) if instructions else "*(none)*"
    handoff_lines = (
        "\n".join(f"- **{h['label']}**" + (f" → `{h['agent']}`" if h.get("agent") else "") for h in handoffs)
        if handoffs
        else "*(none)*"
    )

    return dedent(f"""\
        # {name}

        **Slash command:** `/{slug}`
        **Phase:** {phase}
        **Model:** {model} (tier: {tier})
        **Tools:** {', '.join(tools)}

        ## Description

        {desc}

        ## Instructions

        {instr_lines}

        ## Handoffs

        {handoff_lines}
        """)


def _claude_md(agents: list[dict[str, Any]], model_map: dict[str, str]) -> str:
    lines = [
        "# Enterprise SDD — Claude Code Integration",
        "",
        "This file is auto-generated by `sdd adapters generate`.",
        "",
        "## Available Agents",
        "",
        "| Slash Command | Agent | Phase | Tier |",
        "|---------------|-------|-------|------|",
    ]
    for agent in agents:
        slug = agent["slug"]
        name = agent["name"]
        phase = agent.get("phase", "")
        tier = agent.get("model-tier", "standard")
        lines.append(f"| `/{slug}` | {name} | {phase} | {tier} |")

    lines += [
        "",
        "## Model Tiers",
        "",
    ]
    for tier, model in model_map.items():
        lines.append(f"- **{tier}** → `{model}`")

    lines.append("")
    return "\n".join(lines)


def generate_claude(
    agents: list[dict[str, Any]],
    model_map: dict[str, str],
    repo_root: Path,
    dry_run: bool,
) -> int:
    commands_dir = repo_root / ".claude" / "commands"
    commands_dir.mkdir(parents=True, exist_ok=True)
    written = 0

    for agent in agents:
        slug: str = agent["slug"]
        path = commands_dir / f"{slug}.md"
        content = _claude_command_md(agent, model_map)

        if path.exists() and path.read_text() == content:
            print(f"  OK    {path.name}")
            continue

        if dry_run:
            print(f"  WOULD WRITE  {path.name}")
        else:
            path.write_text(content)
            print(f"  WRITE  {path.name}")
        written += 1

    # Generate CLAUDE.md at repo root
    claude_md_path = repo_root / "CLAUDE.md"
    claude_md_content = _claude_md(agents, model_map)
    if not claude_md_path.exists() or claude_md_path.read_text() != claude_md_content:
        if dry_run:
            print("  WOULD WRITE  CLAUDE.md")
        else:
            claude_md_path.write_text(claude_md_content)
            print("  WRITE  CLAUDE.md")
        written += 1
    else:
        print("  OK    CLAUDE.md")

    return written


# ---------------------------------------------------------------------------
# Windsurf adapter  (.windsurfrules)
# ---------------------------------------------------------------------------

def generate_windsurf(
    agents: list[dict[str, Any]],
    model_map: dict[str, str],
    repo_root: Path,
    dry_run: bool,
) -> int:
    path = repo_root / ".windsurfrules"
    lines = [
        "# Enterprise SDD — Windsurf Rules",
        "# Auto-generated by `sdd adapters generate`",
        "",
        "## Available Agents",
        "",
    ]

    for agent in agents:
        name = agent["name"]
        slug = agent["slug"]
        tier = agent.get("model-tier", "standard")
        model = model_map.get(tier, DEFAULT_MODEL_MAP["standard"])
        phase = agent.get("phase", "")
        desc_first_line = (agent.get("description") or "").splitlines()[0]

        lines += [
            f"### {name} (`{slug}`)",
            f"- **Phase:** {phase}",
            f"- **Model:** {model} (tier: {tier})",
            f"- {desc_first_line}",
            "",
        ]

    content = "\n".join(lines)

    if path.exists() and path.read_text() == content:
        print("  OK    .windsurfrules")
        return 0

    if dry_run:
        print("  WOULD WRITE  .windsurfrules")
    else:
        path.write_text(content)
        print("  WRITE  .windsurfrules")
    return 1


# ---------------------------------------------------------------------------
# Codex adapter  (agents.md)
# ---------------------------------------------------------------------------

def generate_codex(
    agents: list[dict[str, Any]],
    model_map: dict[str, str],
    repo_root: Path,
    dry_run: bool,
) -> int:
    path = repo_root / "agents.md"
    lines = [
        "# Enterprise SDD Agents",
        "",
        "> Auto-generated by `sdd adapters generate`. Do not edit manually.",
        "",
        "## Agent Registry",
        "",
        "| Name | Slug | Phase | Tier | Model |",
        "|------|------|-------|------|-------|",
    ]

    for agent in agents:
        name = agent["name"]
        slug = agent["slug"]
        phase = agent.get("phase", "")
        tier = agent.get("model-tier", "standard")
        model = model_map.get(tier, DEFAULT_MODEL_MAP["standard"])
        lines.append(f"| {name} | `{slug}` | {phase} | {tier} | `{model}` |")

    lines += [
        "",
        "## Model Tier Mapping",
        "",
        "| Tier | Model |",
        "|------|-------|",
    ]
    for tier, model in model_map.items():
        lines.append(f"| {tier} | `{model}` |")

    lines += ["", "## Agent Details", ""]

    for agent in agents:
        name = agent["name"]
        slug = agent["slug"]
        desc = agent.get("description", "")
        tier = agent.get("model-tier", "standard")
        phase = agent.get("phase", "")
        tools = agent.get("tools", [])
        instructions = agent.get("instructions", [])

        lines += [
            f"### {name}",
            "",
            f"**Slug:** `{slug}` | **Phase:** {phase} | **Tier:** {tier}",
            "",
            desc,
            "",
            f"**Tools:** {', '.join(f'`{t}`' for t in tools)}",
            "",
        ]
        if instructions:
            lines.append("**Instructions:**")
            for i in instructions:
                lines.append(f"- `{i}`")
            lines.append("")

    content = "\n".join(lines)

    if path.exists() and path.read_text() == content:
        print("  OK    agents.md")
        return 0

    if dry_run:
        print("  WOULD WRITE  agents.md")
    else:
        path.write_text(content)
        print("  WRITE  agents.md")
    return 1


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

_TARGETS = ("vscode", "cursor", "claude", "windsurf", "codex")


def build_arg_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        prog="generate-adapters.py",
        description="Generate IDE adapter files from canonical agent definitions.",
    )
    p.add_argument(
        "--target",
        choices=(*_TARGETS, "all"),
        default="all",
        help="which adapter target to generate (default: all)",
    )
    p.add_argument(
        "--dry-run",
        action="store_true",
        default=False,
        help="print what would be done without writing files",
    )
    p.add_argument(
        "--repo-root",
        metavar="PATH",
        default=None,
        help="override repo root detection",
    )
    p.add_argument(
        "--feature-id",
        metavar="FEATURE_ID",
        default=None,
        help="feature id used to apply dynamic model routing",
    )
    return p


def find_repo_root(start: Path | None = None) -> Path:
    current = (start or Path.cwd()).resolve()
    for directory in [current, *current.parents]:
        if (directory / ".specify").is_dir():
            return directory
    raise FileNotFoundError(
        "Could not locate .specify/ directory. "
        "Run this script from inside an Enterprise SDD repository."
    )


def main() -> None:
    parser = build_arg_parser()
    args = parser.parse_args()

    if args.repo_root:
        repo_root = Path(args.repo_root).resolve()
    else:
        try:
            repo_root = find_repo_root()
        except FileNotFoundError as exc:
            print(f"ERROR: {exc}", file=sys.stderr)
            sys.exit(2)

    print(f"Repo root: {repo_root}")
    print(f"Target:    {args.target}")
    print(f"Dry run:   {args.dry_run}")
    print()

    agents = load_canonical(repo_root)
    ceremony = None
    if args.feature_id:
        try:
            ceremony = load_feature_ceremony(repo_root, args.feature_id)
        except (FileNotFoundError, json.JSONDecodeError) as exc:
            print(f"ERROR: {exc}", file=sys.stderr)
            sys.exit(2)
        agents = apply_dynamic_routing(agents, ceremony)

    model_map = resolve_model_map(repo_root)

    print(f"Loaded {len(agents)} agents")
    if ceremony:
        print(f"Routing: ceremony={ceremony} feature={args.feature_id}")
    print(f"Model map: {model_map}")
    print()

    targets = list(_TARGETS) if args.target == "all" else [args.target]

    generators = {
        "vscode": generate_vscode,
        "cursor": generate_cursor,
        "claude": generate_claude,
        "windsurf": generate_windsurf,
        "codex": generate_codex,
    }

    total_changes = 0
    for target in targets:
        print(f"--- {target} ---")
        fn = generators[target]
        n = fn(agents, model_map, repo_root, args.dry_run)
        total_changes += n
        print()

    if args.dry_run:
        print(f"Dry run complete — {total_changes} file(s) would be changed.")
    else:
        print(f"Done — {total_changes} file(s) changed.")


if __name__ == "__main__":
    main()
