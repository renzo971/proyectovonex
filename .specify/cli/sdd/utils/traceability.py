"""Forward/reverse traceability over `tasks.md` (Wave 27 §26 #2).

Parses every `.specify/specs/<feature>/tasks.md`, building a forward map
(task → files/AC/US) and inverting it into a reverse map (file → originating
chain) for `sdd trace --reverse <path>`. Pure read; no writes, no network.
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from pathlib import Path


SPECS_DIR = Path(".specify") / "specs"

_TASK_HEADING_RE = re.compile(r"^###\s+(T\d+)\b\s*(?:\[[A-Z]\])?\s*-?\s*(.*)$")
_FILES_HEADER_RE = re.compile(r"^\*\*Files to Create/Modify:\*\*", re.IGNORECASE)
_TRACES_RE = re.compile(r"^\*\*Traces To:\*\*\s*(.*)$", re.IGNORECASE)
_BULLET_RE = re.compile(r"^[-*]\s+`?([^`]+?)`?\s*$")
_BOLD_HEADER_RE = re.compile(r"^\*\*[^*]+:\*\*")
_US_RE = re.compile(r"US-\d+")
_AC_RE = re.compile(r"AC-\d+")


@dataclass
class TaskTrace:
    task_id: str
    title: str
    feature: str
    spec_file: str
    files: list[str] = field(default_factory=list)
    traces_to: str = ""
    user_stories: list[str] = field(default_factory=list)
    acceptance_criteria: list[str] = field(default_factory=list)


def _parse_tasks_file(feature: str, path: Path) -> list[TaskTrace]:
    tasks: list[TaskTrace] = []
    current: TaskTrace | None = None
    in_files = False
    text = path.read_text(encoding="utf-8")
    rel_spec = str(path.relative_to(path.parents[2])) if len(path.parents) >= 3 else path.name

    for raw in text.splitlines():
        line = raw.strip()
        m = _TASK_HEADING_RE.match(line)
        if m:
            if current is not None:
                tasks.append(current)
            current = TaskTrace(
                task_id=m.group(1),
                title=m.group(2).strip(" -"),
                feature=feature,
                spec_file=rel_spec,
            )
            in_files = False
            continue
        if current is None:
            continue

        current.user_stories.extend(_US_RE.findall(line))
        current.acceptance_criteria.extend(_AC_RE.findall(line))

        if _FILES_HEADER_RE.match(line):
            in_files = True
            continue
        tm = _TRACES_RE.match(line)
        if tm:
            current.traces_to = tm.group(1).strip()
            in_files = False
            continue
        if in_files:
            bm = _BULLET_RE.match(line)
            if bm:
                current.files.append(bm.group(1).strip())
            elif _BOLD_HEADER_RE.match(line) or line.startswith("#"):
                in_files = False

    if current is not None:
        tasks.append(current)

    for t in tasks:
        t.user_stories = sorted(set(t.user_stories))
        t.acceptance_criteria = sorted(set(t.acceptance_criteria))
    return tasks


def load_forward(repo_root: Path) -> list[TaskTrace]:
    """Parse all feature tasks.md files into a flat list of TaskTrace."""
    base = repo_root / SPECS_DIR
    if not base.is_dir():
        return []
    traces: list[TaskTrace] = []
    for tasks_md in sorted(base.glob("*/tasks.md")):
        feature = tasks_md.parent.name
        traces.extend(_parse_tasks_file(feature, tasks_md))
    return traces


def _normalize(path: str) -> str:
    return path.replace("\\", "/").lstrip("./").strip()


def reverse_lookup(repo_root: Path, target: str) -> list[TaskTrace]:
    """Return the task chain(s) that authorize `target` (empty if untracked)."""
    needle = _normalize(target)
    matches: list[TaskTrace] = []
    for t in load_forward(repo_root):
        for f in t.files:
            if _normalize(f) == needle:
                matches.append(t)
                break
    return matches


def tracked_files(repo_root: Path) -> set[str]:
    """All file paths authorized by at least one task."""
    tracked: set[str] = set()
    for t in load_forward(repo_root):
        for f in t.files:
            tracked.add(_normalize(f))
    return tracked
