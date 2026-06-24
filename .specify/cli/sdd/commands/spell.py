"""`sdd spell <prompt-name> [--guide <name>]` — run a prompt by name against feature context."""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path

from sdd.utils.config import find_repo_root, scripts_dir, get_env
from sdd.utils import output


def add_spell_parser(subparsers: argparse._SubParsersAction) -> None:  # type: ignore[type-arg]
    p = subparsers.add_parser(
        "spell",
        help="run a prompt by name against feature context",
        description="Execute a prompt from .github/prompts/ against the current feature.",
    )
    p.add_argument(
        "prompt_name",
        metavar="<prompt-name>",
        help="name of the prompt file (without .prompt.md extension)",
    )
    p.add_argument(
        "-f",
        "--feature",
        metavar="<feature-id>",
        default=None,
        help="feature ID to run against (default: inferred from current context)",
    )
    p.add_argument(
        "-g",
        "--guide",
        metavar="<guide-name>",
        default=None,
        help="optional guidance name (e.g., api-only, event-only)",
    )
    p.add_argument(
        "--dry-run",
        action="store_true",
        default=False,
        help="show what would be executed without running",
    )


def run_spell(args: argparse.Namespace) -> int:
    try:
        repo_root = find_repo_root()
    except FileNotFoundError as exc:
        output.error(str(exc))
        return 2

    prompt_name: str = args.prompt_name
    feature_id: str | None = args.feature
    guide_name: str | None = getattr(args, "guide", None)
    dry_run: bool = getattr(args, "dry_run", False)

    # Try to find the prompt file
    prompt_file = repo_root / ".github" / "prompts" / f"{prompt_name}.prompt.md"
    if not prompt_file.exists():
        output.error(f"Prompt not found: {prompt_file}")
        output.info("Available prompts:")
        prompts_dir = repo_root / ".github" / "prompts"
        if prompts_dir.exists():
            for p in sorted(prompts_dir.glob("*.prompt.md")):
                clean_name = p.stem.replace(".prompt", "")
                output.info(f"  - {clean_name}")
        return 2

    # Build context bridge (if feature specified or inferred)
    context_bridge = ""
    if feature_id:
        feature_dir = repo_root / ".specify" / "specs" / feature_id
        if feature_dir.exists():
            context_bridge = _build_context_for_feature(feature_dir, repo_root)
        else:
            output.warn(f"Feature not found: {feature_id}")

    # Prepare display
    output.info(f"Running prompt: {prompt_name}")
    if feature_id:
        output.info(f"Feature context: {feature_id}")
    if guide_name:
        output.info(f"Guidance: {guide_name}")

    if dry_run:
        output.warn("DRY RUN - would collect the following:")
        output.info(f"  Prompt: {prompt_file}")
        if context_bridge:
            output.info(f"  Context bridge: {len(context_bridge)} chars")
        return 0

    # Read the prompt file
    prompt_content = prompt_file.read_text(encoding="utf-8")

    # Build the copyable markdown block
    md_lines: list[str] = []
    md_lines.append(f"# sdd spell: {prompt_name}")
    md_lines.append("")
    if feature_id:
        md_lines.append(f"**Feature:** `{feature_id}`")
        md_lines.append("")

    if context_bridge:
        md_lines.append("## Context Bridge")
        md_lines.append("")
        md_lines.append(context_bridge)
        md_lines.append("")

    md_lines.append("## Prompt")
    md_lines.append("")
    md_lines.append(prompt_content)

    result = "\n".join(md_lines)
    print(result)

    return 0


def _build_context_for_feature(feature_dir: Path, repo_root: Path) -> str:
    """Build a context bridge for a feature."""
    lines: list[str] = []

    # Feature metadata
    meta_file = feature_dir / ".feature-meta.json"
    if meta_file.exists():
        try:
            meta = json.loads(meta_file.read_text())
            lines.append(f"### Feature Metadata")
            lines.append(f"- **Name:** {meta.get('featureName', 'Unknown')}")
            lines.append(f"- **ID:** {meta.get('featureId', 'Unknown')}")
            if meta.get("phase"):
                lines.append(f"- **Phase:** {meta['phase']}")
            lines.append("")
        except json.JSONDecodeError:
            pass

    # Specification excerpt
    spec_file = feature_dir / "spec.md"
    if spec_file.exists():
        content = spec_file.read_text(encoding="utf-8")
        lines.append("### Specification (excerpt)")
        lines.append(content[:500])
        lines.append("")

    # Key decisions
    decisions_file = repo_root / ".specify" / "memory" / "decisions.md"
    if decisions_file.exists():
        content = decisions_file.read_text(encoding="utf-8")
        lines.append("### Key Decisions (excerpt)")
        lines.append(content[:300])
        lines.append("")

    # Constitution excerpt (Article I — Project Identity)
    constitution_file = repo_root / ".specify" / "memory" / "constitution.md"
    if constitution_file.exists():
        content = constitution_file.read_text(encoding="utf-8")
        # Extract Article I as the most relevant context
        import re
        match = re.search(r"(## Article I[:\s].*?)(?=## Article|$)", content, re.DOTALL)
        if match:
            lines.append("### Constitution (Article I)")
            lines.append(match.group(1).strip()[:400])
            lines.append("")

    return "\n".join(lines)
