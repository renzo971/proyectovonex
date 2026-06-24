"""Memory ranking + frontmatter hit-recording (Wave 23 §23.A.9–§23.A.14).

Provides:
- Read/parse YAML frontmatter on `.specify/memory/*.md`.
- Time-decay scoring: final_score = relevance × exp(-days_since_last_hit / 30).
- `decay_floor: true` overrides the multiplication (always-included).
- Hit recording: bumps `last_referenced_at` (UTC ISO 8601) and `reference_count`.
- Stale enumeration for `sdd memory list --stale`.

Backward compatible: files without frontmatter are treated as
`last_referenced_at = file mtime`, `reference_count = 0`, `decay_floor = false`.
"""

from __future__ import annotations

import math
import re
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterable

try:
    import yaml  # type: ignore
except ImportError:  # pragma: no cover
    yaml = None  # type: ignore


MEMORY_DIR = Path(".specify") / "memory"
DECAY_HALFLIFE_DAYS = 30.0
STALE_THRESHOLD_DAYS = 90.0


@dataclass
class MemoryRecord:
    path: Path
    last_referenced_at: datetime
    reference_count: int = 0
    decay_floor: bool = False
    raw_frontmatter: dict = field(default_factory=dict)
    body: str = ""

    @property
    def days_since_hit(self) -> float:
        delta = datetime.now(tz=timezone.utc) - self.last_referenced_at
        return max(delta.total_seconds() / 86400.0, 0.0)

    def decay_factor(self) -> float:
        if self.decay_floor:
            return 1.0
        return math.exp(-self.days_since_hit / DECAY_HALFLIFE_DAYS)

    def score(self, relevance: float = 1.0) -> float:
        return relevance * self.decay_factor()


_FRONTMATTER_RE = re.compile(r"^---\n(.*?)\n---\n?(.*)$", re.DOTALL)


def _parse_one(path: Path) -> MemoryRecord:
    text = path.read_text(encoding="utf-8")
    fm: dict = {}
    body = text
    m = _FRONTMATTER_RE.match(text)
    if m and yaml is not None:
        try:
            fm = yaml.safe_load(m.group(1)) or {}
            if not isinstance(fm, dict):
                fm = {}
            body = m.group(2)
        except Exception:
            fm = {}
    raw_ts = fm.get("last_referenced_at")
    if isinstance(raw_ts, str):
        try:
            ts = datetime.fromisoformat(raw_ts.replace("Z", "+00:00"))
            if ts.tzinfo is None:
                ts = ts.replace(tzinfo=timezone.utc)
        except ValueError:
            ts = datetime.fromtimestamp(path.stat().st_mtime, tz=timezone.utc)
    elif isinstance(raw_ts, datetime):
        ts = raw_ts if raw_ts.tzinfo else raw_ts.replace(tzinfo=timezone.utc)
    else:
        ts = datetime.fromtimestamp(path.stat().st_mtime, tz=timezone.utc)
    return MemoryRecord(
        path=path,
        last_referenced_at=ts,
        reference_count=int(fm.get("reference_count", 0) or 0),
        decay_floor=bool(fm.get("decay_floor", False)),
        raw_frontmatter=fm,
        body=body,
    )


def load_all(repo_root: Path) -> list[MemoryRecord]:
    base = repo_root / MEMORY_DIR
    if not base.exists():
        return []
    return [_parse_one(p) for p in sorted(base.glob("*.md"))]


def record_hit(record: MemoryRecord) -> None:
    """Atomically bump last_referenced_at + reference_count in the file."""
    fm = dict(record.raw_frontmatter)
    fm["last_referenced_at"] = datetime.now(tz=timezone.utc).isoformat()
    fm["reference_count"] = int(fm.get("reference_count", 0) or 0) + 1
    if "decay_floor" not in fm and record.decay_floor:
        fm["decay_floor"] = True
    if yaml is None:
        return
    new_fm_text = yaml.safe_dump(fm, sort_keys=False, default_flow_style=False).strip()
    new_text = f"---\n{new_fm_text}\n---\n{record.body}"
    record.path.write_text(new_text, encoding="utf-8")


def record_hits(records: Iterable[MemoryRecord]) -> int:
    n = 0
    for r in records:
        record_hit(r)
        n += 1
    return n


def stale_records(repo_root: Path, threshold_days: float = STALE_THRESHOLD_DAYS) -> list[MemoryRecord]:
    return [r for r in load_all(repo_root) if r.days_since_hit > threshold_days and not r.decay_floor]


def explain_table(records: Iterable[MemoryRecord], relevance: dict[str, float] | None = None) -> str:
    relevance = relevance or {}
    lines = [
        "Wave 23 §23.A.13 — Memory scoring (relevance × decay)",
        "=" * 78,
        f"{'NAME':<28} {'AGE(d)':>8} {'DECAY':>8} {'REL':>6} {'SCORE':>8} INCLUDED  REASON",
        "-" * 78,
    ]
    for r in records:
        rel = relevance.get(r.path.name, 1.0)
        score = r.score(rel)
        included = r.decay_floor or score >= 0.1
        reason = "decay_floor" if r.decay_floor else (
            "score>=0.1" if included else "stale (score<0.1)"
        )
        lines.append(
            f"{r.path.name:<28} {r.days_since_hit:>8.1f} {r.decay_factor():>8.3f} "
            f"{rel:>6.2f} {score:>8.3f} {'Y' if included else 'N':<8}  {reason}"
        )
    return "\n".join(lines)
