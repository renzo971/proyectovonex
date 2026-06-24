"""CLI deprecation contract (Wave 20 §20.C.8–§20.C.10).

Provides:
  - `@deprecated(replacement, removal_version, migration_link)` decorator that
    emits a structured warning to stderr on every call of a deprecated CLI hook.
  - `emit_deprecation_warning(...)` for one-shot warnings (e.g., from argparse
    `action="store_true"` callbacks).
  - `scan_repo_for_deprecated_usage(repo_root)` for `sdd doctor` (§20.C.10) —
    walks committed scripts and `.specify/config.yaml` looking for any flag
    listed in the **Active** table of `enterprise-sdd/CLI-DEPRECATIONS.md`.

The catalog is parsed at runtime so adding a new deprecation only requires
updating `CLI-DEPRECATIONS.md` and decorating the parser hook.
"""

from __future__ import annotations

import functools
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Callable


CATALOG_PATH = Path("CLI-DEPRECATIONS.md")


@dataclass(frozen=True)
class CatalogEntry:
    flag: str
    deprecated_in: str
    removal_version: str
    replacement: str
    migration_link: str


@dataclass(frozen=True)
class DeprecationHit:
    flag: str
    path: str
    line_no: int
    replacement: str
    migration_link: str


def emit_deprecation_warning(
    flag: str,
    *,
    replacement: str,
    removal_version: str,
    migration_link: str,
    stream=sys.stderr,
) -> None:
    """Emit the canonical structured deprecation warning."""
    print(
        f"[deprecation] {flag}\n"
        f"              replacement: {replacement}\n"
        f"              removal_version: {removal_version}\n"
        f"              migration: {migration_link}",
        file=stream,
    )


def deprecated(
    *,
    flag: str,
    replacement: str,
    removal_version: str,
    migration_link: str,
) -> Callable:
    """Decorator that emits a structured deprecation warning before the wrapped
    callable runs. Apply to CLI parser hooks or run_<command> entrypoints.
    """

    def _decorator(fn: Callable) -> Callable:
        @functools.wraps(fn)
        def _wrapped(*args, **kwargs):
            emit_deprecation_warning(
                flag,
                replacement=replacement,
                removal_version=removal_version,
                migration_link=migration_link,
            )
            return fn(*args, **kwargs)

        _wrapped.__deprecated__ = {  # type: ignore[attr-defined]
            "flag": flag,
            "replacement": replacement,
            "removal_version": removal_version,
            "migration_link": migration_link,
        }
        return _wrapped

    return _decorator


# ─────────────────────────────────────────────────────────────────────────────
# Catalog parsing + repo scan (§20.C.10)
# ─────────────────────────────────────────────────────────────────────────────

# Match a row like:
#   | _(seed)_ `skill-validate--legacy-mode` | `sdd skill validate --legacy-mode` | 0.5.0 | 0.7.0 | `sdd …` | [#anchor](#anchor) |
_ROW_RE = re.compile(r"^\|\s*[^|]*\|\s*`([^`]+)`\s*\|\s*([^|]+?)\s*\|\s*([^|]+?)\s*\|\s*([^|]+?)\s*\|\s*([^|]+?)\s*\|")


def load_active_catalog(repo_root: Path) -> list[CatalogEntry]:
    """Parse the **Active Deprecations** table from CLI-DEPRECATIONS.md."""
    path = repo_root / CATALOG_PATH
    if not path.exists():
        return []
    text = path.read_text(encoding="utf-8")
    # Slice between "## Active Deprecations" and the next "##" heading.
    m = re.search(r"##\s+Active Deprecations(.*?)(?=^##\s+|\Z)", text,
                  flags=re.DOTALL | re.MULTILINE)
    if not m:
        return []
    section = m.group(1)

    entries: list[CatalogEntry] = []
    for line in section.splitlines():
        if not line.startswith("|"):
            continue
        if "Flag" in line or "---" in line:
            continue
        rm = _ROW_RE.match(line)
        if not rm:
            continue
        flag_str, dep_in, removal, replacement, migration = rm.groups()
        if "(none" in flag_str.lower() or "—" == flag_str.strip():
            continue
        entries.append(
            CatalogEntry(
                flag=flag_str.strip(),
                deprecated_in=dep_in.strip(),
                removal_version=removal.strip(),
                replacement=replacement.strip().strip("`"),
                migration_link=migration.strip(),
            )
        )
    return entries


_SCAN_GLOBS = (
    ".specify/config.yaml",
    ".specify/scripts/*.sh",
    ".specify/scripts/*.ps1",
)


def scan_repo_for_deprecated_usage(repo_root: Path) -> list[DeprecationHit]:
    """Scan committed scripts/config for any flag listed in the active catalog.

    Used by `sdd doctor` (Wave 20 §20.C.10).
    """
    entries = load_active_catalog(repo_root)
    if not entries:
        return []

    hits: list[DeprecationHit] = []
    for pattern in _SCAN_GLOBS:
        for path in repo_root.glob(pattern):
            try:
                lines = path.read_text(encoding="utf-8").splitlines()
            except (OSError, UnicodeDecodeError):
                continue
            for idx, line in enumerate(lines, start=1):
                for entry in entries:
                    # Match the bare flag name and any longer form starting with
                    # a leading `--`. Avoid matching markdown comments inside
                    # docstrings by requiring the flag to appear as a token.
                    needle = entry.flag.split()[-1] if " " in entry.flag else entry.flag
                    if needle.startswith("--") and needle in line:
                        hits.append(DeprecationHit(
                            flag=entry.flag,
                            path=str(path.relative_to(repo_root)),
                            line_no=idx,
                            replacement=entry.replacement,
                            migration_link=entry.migration_link,
                        ))
                        break
    return hits
