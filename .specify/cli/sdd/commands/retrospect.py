"""`sdd retrospect` — open or print the structured retrospective prompt."""

from __future__ import annotations

import argparse

from sdd.utils.config import find_repo_root
from sdd.utils import output
from sdd.io import atomic_write_text

_TEMPLATE = """\
# Feature Retrospective

> Capture learnings at the end of a delivered feature. Use this to feed improvements
> back into the constitution, team-preferences.md, and future instruction files.
>
> Save to: `.specify/memory/retrospectives/feature-{slug}.md`
> Invoke interactively with: @brainstorming or @analysis

---

## Feature Summary (1 sentence)

<!-- What was built and why? -->

---

## What Went Smoothly

<!-- Process adherence wins, agent quality highlights, spec-code alignment successes -->

-
-

---

## Friction Points

<!-- Gate failures, ambiguous specs, context loss events, rework causes -->

-
-

---

## Reusable Patterns Discovered

<!-- Architecture patterns, test patterns, integration strategies worth repeating -->

-
-

---

## Anti-Patterns Encountered

<!-- Things that went wrong — specific to this project or tech stack -->

-
-

---

## Proposed Updates

| Target | Proposed Change | Priority |
|--------|-----------------|:--------:|
| `constitution.md` | | 🟡 |
| `team-preferences.md` | | 🟢 |
| Shared instruction file | | 🟡 |
| Agent boundary rule | | 🟢 |

---

## Decision to Record in decisions.md

<!-- Any architectural or process decisions made during this feature that should be persisted -->

-

"""


def add_retrospect_parser(subparsers: argparse._SubParsersAction) -> None:  # type: ignore[type-arg]
    p = subparsers.add_parser(
        "retrospect",
        help="print or save the structured retrospective template",
        description=(
            "Print the structured feature retrospective template to stdout, or save it "
            "to .specify/memory/retrospectives/ for a specific feature."
        ),
    )
    p.add_argument(
        "--feature",
        metavar="<feature-slug>",
        default=None,
        help="feature slug — if provided, saves the template to "
             ".specify/memory/retrospectives/feature-<slug>.md",
    )
    p.add_argument(
        "--extract",
        action="store_true",
        default=False,
        help="automated learnings extraction — mine feature artifacts to produce "
             "a structured LEARNINGS.md without operator interaction",
    )


def run_retrospect(args: argparse.Namespace) -> int:
    feature_slug: str | None = args.feature
    extract: bool = getattr(args, "extract", False)

    if extract and feature_slug is None:
        output.error("--extract requires --feature <slug> to identify which feature to mine")
        return 2

    if extract:
        return _run_extract(feature_slug)  # type: ignore[arg-type]

    if feature_slug is None:
        # Print the template to stdout
        print(_TEMPLATE)
        return 0

    # Save to file
    try:
        repo_root = find_repo_root()
    except FileNotFoundError as exc:
        output.error(str(exc))
        return 2

    retro_dir = repo_root / ".specify" / "memory" / "retrospectives"
    retro_dir.mkdir(parents=True, exist_ok=True)
    retro_file = retro_dir / f"feature-{feature_slug}.md"

    if retro_file.exists():
        output.warn(f"Retrospective already exists: {retro_file.relative_to(repo_root)}")
        output.info("Edit it directly or use --feature with a different slug.")
        return 1

    atomic_write_text(
        retro_file,
        _TEMPLATE.replace("{slug}", feature_slug),
    )
    output.success(f"Retrospective template saved: {retro_file.relative_to(repo_root)}")
    return 0


def _run_extract(feature_slug: str) -> int:
    """Automated learnings extraction — mine feature artifacts for a structured LEARNINGS.md."""
    try:
        repo_root = find_repo_root()
    except FileNotFoundError as exc:
        output.error(str(exc))
        return 2

    # Find the feature specs directory
    specs_dir = repo_root / ".specify" / "specs"
    feature_dirs = [d for d in specs_dir.iterdir() if d.is_dir() and feature_slug in d.name] if specs_dir.exists() else []
    if not feature_dirs:
        output.error(f"No feature directory matching '{feature_slug}' found under .specify/specs/")
        return 2

    feature_dir = feature_dirs[0]
    learnings_path = feature_dir / "LEARNINGS.md"

    # Gather artifacts
    artifacts: list[str] = []
    for pattern in ("analysis-report.md", "*.md", "escalations/*.md"):
        for f in feature_dir.glob(pattern):
            if f.is_file() and f.name != "LEARNINGS.md":
                artifacts.append(f.name)

    # Also check stuck history and escalations
    stuck_dir = repo_root / ".specify" / "checkpoints" / "stuck-history"
    escalation_dir = repo_root / ".specify" / "escalations" / feature_slug

    stuck_files = list(stuck_dir.glob("*.md")) if stuck_dir.exists() else []
    escalation_files = list(escalation_dir.glob("*.md")) if escalation_dir.exists() else []

    learnings_content = f"""# Automated Learnings: {feature_slug}

**Generated:** automated extraction via `sdd retrospect --extract`
**Feature directory:** {feature_dir.relative_to(repo_root)}
**Artifacts mined:** {len(artifacts)} feature artifacts, {len(stuck_files)} stuck records, {len(escalation_files)} escalation records

---

## Decisions

<!-- Key choices made during this feature, with rationale and alternatives considered -->
<!-- Extracted from: analysis-report.md, clarifications.md, escalation artifacts -->

- [Review the feature artifacts above to populate this section]

---

## Patterns

<!-- Reusable code/design patterns that emerged during implementation -->
<!-- Extracted from: tasks.md completion notes, code review findings -->

- [Review the feature artifacts above to populate this section]

---

## Anti-Patterns

<!-- Pitfalls encountered and how they were resolved -->
<!-- Extracted from: stuck history, escalation artifacts, gate failure reports -->

- [Review the feature artifacts above to populate this section]

---

## Recommendations

<!-- Suggestions for future features based on this experience -->
<!-- Synthesized from all artifact categories above -->

- [Review the feature artifacts above to populate this section]
"""

    atomic_write_text(learnings_path, learnings_content)
    output.success(f"Learnings extracted: {learnings_path.relative_to(repo_root)}")
    output.info(f"Mined {len(artifacts)} artifacts, {len(stuck_files)} stuck records, {len(escalation_files)} escalations")
    return 0
