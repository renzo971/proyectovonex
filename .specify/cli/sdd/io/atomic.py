"""Atomic-write helpers for SDD-managed artifacts.

Wave 26 §25 #2 — Race-free file writes for `.specify/**` and `.sdd-modules/**`.

Each helper writes to a sibling temp file (suffix `.tmp.<hex>`) and then
calls `os.replace` to perform a `rename(2)`-equivalent atomic swap. A
concurrent reader observes either the previous content or the new content,
never a partial write.

Best-effort cleanup of stale `.tmp.*` siblings is done on every call.
"""

from __future__ import annotations

import json
import os
import secrets
from pathlib import Path
from typing import Any

try:  # pragma: no cover - import guard
    import yaml  # type: ignore[import-untyped]
    _HAS_YAML = True
except ImportError:  # pragma: no cover
    _HAS_YAML = False


def _tmp_path(target: Path) -> Path:
    """Return a sibling temp path with a random suffix."""
    return target.with_suffix(target.suffix + f".tmp.{secrets.token_hex(6)}")


def _cleanup_stale_tmp(target: Path) -> None:
    """Best-effort removal of stale `.tmp.*` siblings of `target`."""
    parent = target.parent
    if not parent.exists():
        return
    pattern = f"{target.name}.tmp.*"
    try:
        for stale in parent.glob(pattern):
            try:
                stale.unlink()
            except OSError:
                continue
    except OSError:
        return


def _ensure_parent(path: Path) -> None:
    """Create parent directory if missing."""
    path.parent.mkdir(parents=True, exist_ok=True)


def atomic_write_text(path: Path, content: str, *, encoding: str = "utf-8") -> None:
    """Atomically write `content` to `path` as text.

    Steps:
      1. Ensure the parent directory exists.
      2. Sweep stale `.tmp.*` siblings (best-effort).
      3. Write to a sibling tempfile.
      4. `os.replace(tmp, path)` — atomic on POSIX and Windows.
    """
    path = Path(path)
    _ensure_parent(path)
    _cleanup_stale_tmp(path)
    tmp = _tmp_path(path)
    try:
        tmp.write_text(content, encoding=encoding)
        os.replace(tmp, path)
    except Exception:
        # Make sure we don't leave a half-written tempfile behind.
        try:
            if tmp.exists():
                tmp.unlink()
        except OSError:
            pass
        raise


def atomic_write_json(
    path: Path,
    data: Any,
    *,
    indent: int = 2,
    sort_keys: bool = True,
    trailing_newline: bool = True,
) -> None:
    """Atomically write `data` as JSON to `path`.

    `sort_keys=True` and `indent=2` by default for deterministic output.
    """
    body = json.dumps(data, indent=indent, sort_keys=sort_keys, ensure_ascii=False)
    if trailing_newline:
        body += "\n"
    atomic_write_text(path, body)


def atomic_write_yaml(path: Path, data: Any) -> None:
    """Atomically write `data` as YAML to `path`.

    Requires PyYAML (already a transitive dependency via `sdd.policy`).
    """
    if not _HAS_YAML:  # pragma: no cover
        raise ImportError("PyYAML is required for atomic_write_yaml")
    body = yaml.safe_dump(data, sort_keys=True, default_flow_style=False)
    atomic_write_text(path, body)
