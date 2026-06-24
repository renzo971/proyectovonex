"""Derived memory index builder (Wave 27 §26 #1 — strangler-fig PR 1).

Reads the canonical `.specify/memory/decisions.md` and `lessons.md`, extracts
one normalized entry per `## ` heading appended below the "Append … below this
line" marker, and produces a **derived, disposable** index at
`.specify/memory/.index.json`.

The markdown files remain the single source of truth (Constraint #9). This
index is regenerable (`sdd memory index`, rebuilt by `sdd doctor`) and is NOT
committed. It powers:
- dedup-aware selection in `sdd bridge` (PR 4),
- collision surfacing in `sdd memory list --duplicates` (PR 3).

Reuses §23 #3 sha256 hashing and §23 #4 `last_referenced_at` / `reference_count`
frontmatter (via `memory_ranking`).
"""

from __future__ import annotations

import hashlib
import json
import re
from dataclasses import dataclass, asdict
from datetime import datetime, timezone
from pathlib import Path

from sdd.utils import memory_ranking


INDEX_FILE = Path(".specify") / "memory" / ".index.json"
SCHEMA_VERSION = 1

# Source file -> entry kind. Only these files carry append-style entries.
_KIND_BY_FILE: dict[str, str] = {
    "decisions.md": "decision",
    "lessons.md": "lesson",
}

_APPEND_MARKER_RE = re.compile(r"<!--\s*append.*?-->", re.IGNORECASE)
_HEADING_RE = re.compile(r"^##\s+(.*\S)\s*$")
_FENCE_RE = re.compile(r"^\s*```")
_SLUG_STRIP_RE = re.compile(r"[^a-z0-9]+")


@dataclass
class IndexEntry:
    id: str
    source_file: str
    source_anchor: str
    kind: str
    title: str
    fingerprint: str
    last_referenced_at: str
    reference_count: int
    duplicate_of: str | None


def _slugify(text: str) -> str:
    return _SLUG_STRIP_RE.sub("-", text.lower()).strip("-") or "entry"


def _normalize_body(lines: list[str]) -> str:
    """Collapse whitespace so trivially-different-whitespace entries collide."""
    joined = "\n".join(line.rstrip() for line in lines).strip()
    return re.sub(r"\n{2,}", "\n", joined)


def _fingerprint(title: str, body: str) -> str:
    # Fingerprint over the normalized body only: genuine duplicates share the same
    # substantive content even when the date-stamped heading differs.
    payload = body.encode("utf-8")
    return hashlib.sha256(payload).hexdigest()


def _extract_entries(text: str) -> list[tuple[str, list[str]]]:
    """Return (heading, body_lines) for each `## ` entry after the append marker.

    Headings inside fenced code blocks (``` … ```) are ignored so the How-to-Use
    template examples are never mistaken for real entries.
    """
    lines = text.splitlines()
    start = 0
    for i, line in enumerate(lines):
        if _APPEND_MARKER_RE.search(line):
            start = i + 1
            break

    entries: list[tuple[str, list[str]]] = []
    current_heading: str | None = None
    current_body: list[str] = []
    in_fence = False

    for line in lines[start:]:
        if _FENCE_RE.match(line):
            in_fence = not in_fence
            if current_heading is not None:
                current_body.append(line)
            continue
        m = _HEADING_RE.match(line)
        if m and not in_fence:
            if current_heading is not None:
                entries.append((current_heading, current_body))
            current_heading = m.group(1)
            current_body = []
        elif current_heading is not None:
            current_body.append(line)

    if current_heading is not None:
        entries.append((current_heading, current_body))
    return entries


def build_index(repo_root: Path) -> dict:
    """Build the derived index dict from canonical markdown (no file write)."""
    base = repo_root / memory_ranking.MEMORY_DIR
    records_by_name = {r.path.name: r for r in memory_ranking.load_all(repo_root)}

    entries: list[IndexEntry] = []
    for file_name, kind in _KIND_BY_FILE.items():
        path = base / file_name
        if not path.exists():
            continue
        record = records_by_name.get(file_name)
        last_ref = (
            record.last_referenced_at.isoformat()
            if record is not None
            else datetime.fromtimestamp(path.stat().st_mtime, tz=timezone.utc).isoformat()
        )
        ref_count = record.reference_count if record is not None else 0

        for heading, body_lines in _extract_entries(path.read_text(encoding="utf-8")):
            anchor = _slugify(heading)
            body = _normalize_body(body_lines)
            entries.append(
                IndexEntry(
                    id=f"{file_name}#{anchor}",
                    source_file=file_name,
                    source_anchor=anchor,
                    kind=kind,
                    title=heading,
                    fingerprint=_fingerprint(heading, body),
                    last_referenced_at=last_ref,
                    reference_count=ref_count,
                    duplicate_of=None,
                )
            )

    _mark_duplicates(entries)
    return {
        "schema_version": SCHEMA_VERSION,
        "generated_at": datetime.now(tz=timezone.utc).isoformat(),
        "source": "derived",
        "entries": [asdict(e) for e in entries],
    }


def _mark_duplicates(entries: list[IndexEntry]) -> None:
    """Set `duplicate_of` on non-authoritative entries sharing a fingerprint.

    Authoritative = highest reference_count, then earliest discovery order.
    """
    by_fp: dict[str, list[IndexEntry]] = {}
    for e in entries:
        by_fp.setdefault(e.fingerprint, []).append(e)
    for group in by_fp.values():
        if len(group) < 2:
            continue
        authoritative = max(
            range(len(group)),
            key=lambda i: (group[i].reference_count, -i),
        )
        auth_id = group[authoritative].id
        for i, e in enumerate(group):
            if i != authoritative:
                e.duplicate_of = auth_id


def write_index(repo_root: Path) -> dict:
    """Build the index and atomically write it to `.specify/memory/.index.json`."""
    index = build_index(repo_root)
    from sdd.io import atomic_write_json

    atomic_write_json(repo_root / INDEX_FILE, index)
    return index


def load_index(repo_root: Path) -> dict | None:
    path = repo_root / INDEX_FILE
    if not path.exists():
        return None
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return None
    return data if isinstance(data, dict) else None


def duplicate_groups(index: dict) -> list[list[dict]]:
    """Return groups (size >= 2) of entries sharing a fingerprint."""
    by_fp: dict[str, list[dict]] = {}
    for e in index.get("entries", []):
        by_fp.setdefault(e.get("fingerprint", ""), []).append(e)
    return [g for g in by_fp.values() if len(g) >= 2]
