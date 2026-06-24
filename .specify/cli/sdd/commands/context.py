"""`sdd context <action>` — feature context operations."""

from __future__ import annotations

import argparse
import json
from datetime import datetime
from pathlib import Path

from sdd.utils.config import find_repo_root
from sdd.utils import output
from sdd.io import atomic_write_text


def add_context_parser(subparsers: argparse._SubParsersAction) -> None:  # type: ignore[type-arg]
    p = subparsers.add_parser(
        "context",
        help="feature context cache operations",
        description="Compile and manage feature context cache files for faster session resumption.",
    )
    ss = p.add_subparsers(dest="context_action", metavar="<action>")
    ss.required = True

    compile_p = ss.add_parser("compile", help="compile a feature context cache file")
    compile_p.add_argument(
        "--feature",
        metavar="<feature-id>",
        required=True,
        help="feature identifier (e.g. 001 or my-feature-slug)",
    )
    compile_p.add_argument(
        "--section",
        metavar="<NAME>",
        default=None,
        help="update only the named marker section (e.g. current-phase) in an existing context file",
    )


def run_context(args: argparse.Namespace) -> int:
    action: str = args.context_action
    if action == "compile":
        return _compile(args)
    output.error(f"Unknown context action: {action}")
    return 2


def _compile(args: argparse.Namespace) -> int:
    try:
        repo_root = find_repo_root()
    except FileNotFoundError as exc:
        output.error(str(exc))
        return 2

    feature_id: str = args.feature
    section_name: str | None = getattr(args, "section", None)
    specs_dir = repo_root / ".specify" / "specs"

    # Locate feature directory by exact name or numeric prefix
    feature_dir = _find_feature_dir(specs_dir, feature_id)
    if feature_dir is None:
        output.error(f"Feature '{feature_id}' not found under {specs_dir}")
        return 2

    slug = feature_dir.name
    output_file = feature_dir / f"feature-{slug}-context.md"

    # --- Section-based upsert mode ---
    if section_name is not None:
        return _upsert_section(output_file, section_name, repo_root)

    lines: list[str] = []
    lines.append(f"# Feature Context Cache: {slug}\n")
    lines.append(f"**Generated:** {datetime.now().strftime('%Y-%m-%d')}\n")
    lines.append(f"**Feature directory:** `.specify/specs/{slug}/`\n")
    lines.append(f"> Auto-compiled by `sdd context compile --feature {feature_id}`.\n")
    lines.append(f"> Reload this file at the start of any session to quickly resume work.\n\n---\n")

    # Parse .feature-meta.json once; used in both Summary and Continuation Hint sections
    meta_path = feature_dir / ".feature-meta.json"
    meta: dict | None = None
    if meta_path.exists():
        try:
            meta = json.loads(meta_path.read_text(encoding="utf-8"))
        except Exception:
            meta = None

    # Feature meta / ceremony level
    if meta is not None:
        ceremony = meta.get("ceremonyLevel", "standard")
        status = meta.get("status", "unknown")
        last_gate = meta.get("lastPassedGate", 0)
        lines.append("## Feature Summary\n\n")
        lines.append("| Field | Value |\n|-------|-------|\n")
        lines.append(f"| Ceremony level | `{ceremony}` |\n")
        lines.append(f"| Status | `{status}` |\n")
        lines.append(f"| Last passed gate | {last_gate} |\n\n")
    else:
        last_gate = 0
        lines.append("## Feature Summary\n\n")
        if meta_path.exists():
            lines.append("> (could not parse `.feature-meta.json`)\n\n")
        else:
            lines.append("> (`.feature-meta.json` not found)\n\n")

    # Artifact inventory
    lines.append("## Available Artifacts\n\n")
    known_artifacts = [
        ("business-context.md", "Business Context"),
        ("spec.md", "Specification (User Stories + AC)"),
        ("clarifications.md", "Clarifications & Decisions"),
        ("plan.md", "Architecture / Plan"),
        ("data-model.md", "Data Model"),
        ("test-cases.md", "Test Cases"),
        ("tasks.md", "Implementation Tasks"),
        ("analysis-report.md", "Analysis Report"),
        ("ship-checklist.md", "Ship Checklist"),
        ("context-bridge.md", "Context Bridge"),
        ("drift-report.md", "Drift Report"),
    ]
    found_any = False
    for filename, label in known_artifacts:
        artifact = feature_dir / filename
        if artifact.exists():
            lines.append(f"- ✅ **{label}** — `.specify/specs/{slug}/{filename}`\n")
            found_any = True
        else:
            lines.append(f"- ❌ {label} — not yet created\n")
    if not found_any:
        lines.append("- (no artifacts found yet)\n")
    lines.append("\n")

    # Open gate blockers via context bridge
    bridge = feature_dir / "context-bridge.md"
    if bridge.exists():
        lines.append("## Last Phase Summary (from context bridge)\n\n")
        bridge_text = bridge.read_text(encoding="utf-8")
        # Extract up to 40 lines to keep the cache compact
        bridge_lines = bridge_text.splitlines()[:40]
        lines.append("```\n")
        lines.append("\n".join(bridge_lines))
        lines.append("\n```\n\n")

    # Continuation hint (uses last_gate resolved above)
    lines.append("## Continuation Hint\n\n")
    next_phase = {
        0: "Phase 1: Requirements — run `@requirement-analyst`",
        1: "Phase 2: Design — run `@architect`",
        2: "Phase 3: Test & Task Prep — run `@test-explorer`",
        3: "Phase 4: Implementation — run `@software-engineer`",
        4: "Phase 5: Review — run `@review`",
        5: "All gates passed — ready to ship (`sdd ship`)",
    }.get(int(last_gate) if str(last_gate).isdigit() else 0,
          "Check `.feature-meta.json` for current phase")
    lines.append(f"Most recent gate passed: **Gate {last_gate}**\n\n")
    lines.append(f"Suggested next step: {next_phase}\n\n")

    atomic_write_text(output_file, "".join(lines))
    output.success(f"Context cache written: {output_file.relative_to(repo_root)}")
    return 0


def _find_feature_dir(specs_dir: Path, feature_id: str) -> Path | None:
    if not specs_dir.exists():
        return None
    # Exact match first
    exact = specs_dir / feature_id
    if exact.is_dir():
        return exact
    # Prefix match (numeric IDs like "001")
    for d in sorted(specs_dir.iterdir()):
        if d.is_dir() and d.name.startswith(feature_id):
            return d
    return None


def _upsert_section(output_file: Path, section_name: str, repo_root: Path) -> int:
    """Replace content between sdd:section markers in an existing context file."""
    import re

    if not output_file.exists():
        output.error(
            f"Context file not found: {output_file.relative_to(repo_root)}\n"
            f"Run `sdd context compile --feature ...` first to generate it, "
            f"then use --section for targeted updates."
        )
        return 2

    content = output_file.read_text(encoding="utf-8")
    open_marker = f"<!-- sdd:section:{section_name} -->"
    close_marker = f"<!-- /sdd:section:{section_name} -->"

    if open_marker not in content or close_marker not in content:
        output.warning(
            f"Marker '{section_name}' not found in {output_file.relative_to(repo_root)}. "
            f"Falling back to full regeneration is recommended."
        )
        return 1

    # Extract and report the section boundaries
    pattern = re.compile(
        re.escape(open_marker) + r"(.*?)" + re.escape(close_marker),
        re.DOTALL,
    )
    match = pattern.search(content)
    if not match:
        output.error(f"Could not parse section '{section_name}' markers.")
        return 2

    old_section = match.group(1)
    old_lines = len(old_section.strip().splitlines())
    output.info(
        f"Section '{section_name}' found ({old_lines} lines). "
        f"Replace the content between the markers and save the file, "
        f"or use an agent to regenerate this section."
    )
    output.success(f"Section '{section_name}' located in {output_file.relative_to(repo_root)}")
    return 0
