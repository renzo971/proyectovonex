"""Skill scope mapping loader (Wave 20 §20.C.2).

Reads `.specify/skill-mapping.yaml` and exposes filtering helpers used by
`sdd skill list --scope <agent>` and by future agent runtimes that want to
load only the skills relevant to their role.

Backward compatibility: skills without a `scopes` field are globally available.
Skills declared in the yaml take precedence over filesystem-only skills only
when an explicit scope filter is applied; otherwise both populations are merged.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path
from typing import Iterable

import yaml


MAPPING_PATH = Path(".specify") / "skill-mapping.yaml"


@dataclass(frozen=True)
class SkillEntry:
    """A single skill declaration from skill-mapping.yaml."""

    id: str
    category: str  # "local" or "curated"
    purpose: str
    scopes: tuple[str, ...] = field(default_factory=tuple)

    @property
    def is_globally_available(self) -> bool:
        """True when no scopes are declared (skill is available to all agents)."""
        return len(self.scopes) == 0

    def is_visible_to(self, agent: str) -> bool:
        """Return True if this skill should be loaded for `agent`.

        Three cases (see Wave 20 §20.C.2 acceptance criteria):
          1. Unscoped skill → always returned.
          2. Scoped skill matching agent → returned.
          3. Scoped skill non-matching agent → filtered out.
        """
        if self.is_globally_available:
            return True
        return agent in self.scopes


def load_mapping(repo_root: Path) -> list[SkillEntry]:
    """Load and parse `.specify/skill-mapping.yaml`.

    Returns an empty list when the mapping file is absent (backward compatible).
    """
    path = repo_root / MAPPING_PATH
    if not path.exists():
        return []
    raw = yaml.safe_load(path.read_text(encoding="utf-8")) or {}
    skills_raw = raw.get("skills", []) or []
    entries: list[SkillEntry] = []
    for item in skills_raw:
        if not isinstance(item, dict):
            continue
        sid = item.get("id")
        if not sid:
            continue
        scopes = item.get("scopes") or []
        if not isinstance(scopes, list):
            scopes = []
        entries.append(
            SkillEntry(
                id=str(sid),
                category=str(item.get("category", "")),
                purpose=str(item.get("purpose", "")),
                scopes=tuple(str(s) for s in scopes),
            )
        )
    return entries


def filter_for_agent(entries: Iterable[SkillEntry], agent: str) -> list[SkillEntry]:
    """Return only the skills visible to `agent`."""
    return [e for e in entries if e.is_visible_to(agent)]


def load_cold_start_surface(repo_root: Path) -> list[str]:
    """Wave 23 §23.A.7 — load the namespace meta-skill ids that form the
    default cold-start surface. Returns the ordered list declared under
    `coldStartSurface:` in skill-mapping.yaml; empty list when absent.
    """
    path = repo_root / MAPPING_PATH
    if not path.exists():
        return []
    raw = yaml.safe_load(path.read_text(encoding="utf-8")) or {}
    surface = raw.get("coldStartSurface") or []
    if not isinstance(surface, list):
        return []
    return [str(s) for s in surface]
