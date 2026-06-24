"""Module manifest integrity helpers (Wave 20 §20.C.5–§20.C.7).

Reads `.sdd-modules/registry.json`, recomputes per-file sha256 hashes for each
installed module, and reports drift.

Hashing convention matches `module-install.sh` / `module-install.ps1`:
  - per-file sha256 is the lowercase hex digest of the file contents
  - manifestSha256 is the sha256 of `\n`-joined `<rel-path>:<sha256>` lines,
    in the same order as the registry's `files` array, with a trailing newline
    after each line.
"""

from __future__ import annotations

import hashlib
import json
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable


REGISTRY_PATH = Path(".sdd-modules") / "registry.json"


@dataclass
class FileDrift:
    path: str
    expected: str
    actual: str | None  # None when the file is missing on disk


@dataclass
class ModuleVerifyResult:
    module: str
    version: str
    file_drifts: list[FileDrift]
    expected_manifest_sha256: str | None
    actual_manifest_sha256: str | None
    has_baseline: bool

    @property
    def is_clean(self) -> bool:
        if not self.has_baseline:
            return True
        return (
            not self.file_drifts
            and self.expected_manifest_sha256 == self.actual_manifest_sha256
        )


def sha256_of_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def compute_manifest_sha256(file_hashes: Iterable[tuple[str, str]]) -> str:
    """Aggregate hash matching the bash/PowerShell installer convention."""
    h = hashlib.sha256()
    for rel, digest in file_hashes:
        h.update(f"{rel}:{digest}\n".encode("utf-8"))
    return h.hexdigest()


def load_registry(repo_root: Path) -> dict:
    path = repo_root / REGISTRY_PATH
    if not path.exists():
        return {"installedModules": []}
    return json.loads(path.read_text(encoding="utf-8"))


def save_registry(repo_root: Path, data: dict) -> None:
    from sdd.io import atomic_write_json
    path = repo_root / REGISTRY_PATH
    atomic_write_json(path, data, sort_keys=False)


def find_module(registry: dict, module_id: str) -> dict | None:
    for entry in registry.get("installedModules", []) or []:
        if entry.get("name") == module_id:
            return entry
    return None


def verify_module(repo_root: Path, entry: dict) -> ModuleVerifyResult:
    name = entry.get("name", "")
    version = entry.get("version", "")
    files = entry.get("files") or []
    expected_hashes: dict[str, str] = entry.get("fileHashes") or {}
    expected_manifest = entry.get("manifestSha256")
    has_baseline = bool(expected_hashes) or expected_manifest is not None

    drifts: list[FileDrift] = []
    actual_pairs: list[tuple[str, str]] = []
    for rel in files:
        abs_path = repo_root / rel
        if not abs_path.exists():
            drifts.append(FileDrift(path=rel, expected=expected_hashes.get(rel, ""), actual=None))
            continue
        actual = sha256_of_file(abs_path)
        actual_pairs.append((rel, actual))
        if expected_hashes:
            expected = expected_hashes.get(rel)
            if expected is not None and expected != actual:
                drifts.append(FileDrift(path=rel, expected=expected, actual=actual))

    actual_manifest = compute_manifest_sha256(actual_pairs) if actual_pairs else None

    return ModuleVerifyResult(
        module=name,
        version=version,
        file_drifts=drifts,
        expected_manifest_sha256=expected_manifest,
        actual_manifest_sha256=actual_manifest,
        has_baseline=has_baseline,
    )


def verify_all(repo_root: Path) -> list[ModuleVerifyResult]:
    registry = load_registry(repo_root)
    return [verify_module(repo_root, e) for e in registry.get("installedModules", []) or []]


def update_baseline(repo_root: Path, module_id: str) -> ModuleVerifyResult:
    """Recompute file hashes + manifestSha256 and persist them (`--accept`)."""
    registry = load_registry(repo_root)
    entry = find_module(registry, module_id)
    if entry is None:
        raise ValueError(f"Module not found in registry: {module_id}")
    files = entry.get("files") or []
    new_hashes: dict[str, str] = {}
    pairs: list[tuple[str, str]] = []
    for rel in files:
        abs_path = repo_root / rel
        if abs_path.exists():
            digest = sha256_of_file(abs_path)
            new_hashes[rel] = digest
            pairs.append((rel, digest))
    entry["fileHashes"] = new_hashes
    entry["manifestSha256"] = compute_manifest_sha256(pairs)
    save_registry(repo_root, registry)
    return verify_module(repo_root, entry)
