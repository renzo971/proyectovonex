"""Feature-id resolver — Wave 20 §20.B.12.

Priority chain when callers (gate, analyze, ship) need the active feature id:

    1. Explicit `--feature <id>` flag (or positional id passed by user).
    2. `SDD_FEATURE` environment variable.
    3. `feature.lock.json` discovered by walking up from CWD into the repo
       root, looking for `.specify/specs/*/feature.lock.json`. The first
       matching lock file (in directory traversal order) wins.
    4. Branch-name heuristic: current git branch name, if it matches a
       feature-id slug under `.specify/specs/`.

The resolver is intentionally read-only and side-effect free.
"""

from __future__ import annotations

import json
import os
import subprocess
from pathlib import Path


def _current_branch(repo_root: Path) -> str | None:
    try:
        out = subprocess.run(
            ["git", "rev-parse", "--abbrev-ref", "HEAD"],
            cwd=repo_root, capture_output=True, text=True, check=False,
        )
    except Exception:
        return None
    if out.returncode != 0:
        return None
    branch = out.stdout.strip()
    return branch or None


def _candidate_lock_files(repo_root: Path) -> list[Path]:
    specs = repo_root / ".specify" / "specs"
    if not specs.is_dir():
        return []
    return sorted(specs.glob("*/feature.lock.json"))


def _read_lock(path: Path) -> dict | None:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return None


def resolve_feature_id(repo_root: Path, explicit: str | None = None) -> str | None:
    """Resolve the active feature id following the documented priority chain.

    Returns None when no source supplies an id.
    """
    if explicit:
        return explicit
    env_value = os.environ.get("SDD_FEATURE")
    if env_value:
        return env_value
    branch = _current_branch(repo_root)
    # Walk lock files; prefer the one whose `branch` matches the current branch
    # to disambiguate when multiple feature workspaces co-exist locally.
    locks = _candidate_lock_files(repo_root)
    if branch is not None:
        for lock in locks:
            data = _read_lock(lock) or {}
            if data.get("branch") == branch and data.get("feature_id"):
                return str(data["feature_id"])
    if locks:
        data = _read_lock(locks[0]) or {}
        if data.get("feature_id"):
            return str(data["feature_id"])
    # Final fallback: branch-name heuristic — match against existing spec dirs
    if branch:
        specs = repo_root / ".specify" / "specs"
        if specs.is_dir():
            slug = branch.split("/", 1)[-1] if "/" in branch else branch
            for entry in specs.iterdir():
                if entry.is_dir() and (entry.name == branch or entry.name == slug):
                    return entry.name
    return None
