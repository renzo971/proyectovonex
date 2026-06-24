"""`sdd spike <slug>` / `sdd spike wrap <slug>` — time-boxed feasibility experiments."""

from __future__ import annotations

import argparse
import shutil
from datetime import datetime
from pathlib import Path

from sdd.utils.config import find_repo_root
from sdd.utils import output
from sdd.io import atomic_write_text


def add_spike_parser(subparsers: argparse._SubParsersAction) -> None:  # type: ignore[type-arg]
    p = subparsers.add_parser(
        "spike",
        help="manage time-boxed spike experiments",
        description="Create or wrap-up spike experiments in .specify/spikes/.",
    )
    ss = p.add_subparsers(dest="spike_action", metavar="<action>")
    ss.required = True

    start_p = ss.add_parser("start", help="create a new spike from the spike prompt template")
    start_p.add_argument("slug", metavar="<slug>", help="short kebab-case name for the spike")

    wrap_p = ss.add_parser("wrap", help="finalize a spike and extract findings")
    wrap_p.add_argument("slug", metavar="<slug>", help="slug of the spike to wrap up")


def run_spike(args: argparse.Namespace) -> int:
    action: str = args.spike_action
    if action == "start":
        return _start(args)
    if action == "wrap":
        return _wrap(args)
    output.error(f"Unknown spike action: {action}")
    return 2


def _start(args: argparse.Namespace) -> int:
    try:
        repo_root = find_repo_root()
    except FileNotFoundError as exc:
        output.error(str(exc))
        return 2

    slug: str = args.slug
    spikes_dir = repo_root / ".specify" / "spikes" / slug
    if spikes_dir.exists():
        output.error(f"Spike '{slug}' already exists at {spikes_dir}")
        return 1

    spikes_dir.mkdir(parents=True, exist_ok=True)

    # Copy spike prompt template
    template = repo_root / ".github" / "prompts" / "spike.prompt.md"
    target = spikes_dir / f"spike-{slug}.md"

    if template.exists():
        content = template.read_text(encoding="utf-8")
        content = content.replace("{{SPIKE_NAME}}", slug)
        content = content.replace("[date]", datetime.now().strftime("%Y-%m-%d"))
        atomic_write_text(target, content)
    else:
        # Fallback: create a minimal spike file
        atomic_write_text(
            target,
            f"# Spike: {slug}\n\n"
            f"**Created:** {datetime.now().strftime('%Y-%m-%d')}\n\n"
            f"## Hypothesis\n\n## Approach\n\n## Success Criteria\n\n"
            f"## Time-box\n\n## Findings\n",
        )

    output.success(f"Spike '{slug}' created at {spikes_dir}")
    output.info(f"Edit {target} to fill in your hypothesis and approach.")
    return 0


def _wrap(args: argparse.Namespace) -> int:
    try:
        repo_root = find_repo_root()
    except FileNotFoundError as exc:
        output.error(str(exc))
        return 2

    slug: str = args.slug
    spikes_dir = repo_root / ".specify" / "spikes" / slug
    spike_file = spikes_dir / f"spike-{slug}.md"

    if not spikes_dir.exists() or not spike_file.exists():
        output.error(f"Spike '{slug}' not found at {spikes_dir}")
        return 1

    content = spike_file.read_text(encoding="utf-8")

    # Check if findings section has content
    findings_idx = content.find("## Findings")
    if findings_idx == -1:
        output.warning("No '## Findings' section found in spike file.")
    else:
        findings_text = content[findings_idx:]
        # Check for at least one filled-in finding
        if "Key finding" not in findings_text and len(findings_text.strip().splitlines()) <= 2:
            output.warning(
                "Findings section appears empty. "
                "Fill in your findings before wrapping the spike."
            )

    # Add wrap timestamp
    wrap_line = f"\n\n---\n**Wrapped:** {datetime.now().strftime('%Y-%m-%d')}\n"
    if "**Wrapped:**" not in content:
        content += wrap_line
        atomic_write_text(spike_file, content)

    output.success(f"Spike '{slug}' wrapped. Review findings at {spike_file}")
    output.info("If proceeding, create a feature spec with `sdd new` incorporating the spike findings.")
    return 0
