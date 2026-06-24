"""Shared adopt workflow for unmanaged artifacts (Wave 27 §26 #3 A.14).

Brings a hand-dropped module/skill directory under `.sdd-modules/registry.json`
control after a review pass: per-file sha256 + a lightweight Unicode safety scan,
then registers it. Pure local; no network.
"""

from __future__ import annotations

from pathlib import Path

from sdd.utils import module_integrity


# Registry array keyed by artifact category.
_REGISTRY_KEY = {
    "modules": "installedModules",
    "skills": "installedSkills",
    "extensions": "installedExtensions",
}

# Suspicious code points: bidi controls, zero-width, BOM/zero-width-no-break.
_SUSPICIOUS_CODEPOINTS = {
    0x200B, 0x200C, 0x200D, 0x200E, 0x200F,
    0x202A, 0x202B, 0x202C, 0x202D, 0x202E,
    0x2066, 0x2067, 0x2068, 0x2069, 0xFEFF,
}

_TEXT_SUFFIXES = {".md", ".txt", ".json", ".yaml", ".yml", ".py", ".sh", ".ts", ".js", ".toml"}


def scan_unicode(directory: Path) -> list[str]:
    """Return human-readable warnings for suspicious Unicode in text files."""
    warnings: list[str] = []
    for f in sorted(directory.rglob("*")):
        if not f.is_file() or f.suffix.lower() not in _TEXT_SUFFIXES:
            continue
        try:
            text = f.read_text(encoding="utf-8")
        except (OSError, UnicodeDecodeError):
            continue
        hits = {ch for ch in text if ord(ch) in _SUSPICIOUS_CODEPOINTS}
        if hits:
            codes = ", ".join(f"U+{ord(ch):04X}" for ch in sorted(hits, key=ord))
            warnings.append(f"{f.name}: suspicious code point(s) {codes}")
    return warnings


def compute_dir_hashes(repo_root: Path, directory: Path) -> tuple[list[str], dict[str, str], str]:
    """Return (relative file list, {rel: sha256}, manifest sha256) for a directory."""
    files: list[str] = []
    file_hashes: dict[str, str] = {}
    pairs: list[tuple[str, str]] = []
    for f in sorted(directory.rglob("*")):
        if not f.is_file():
            continue
        rel = f.relative_to(repo_root).as_posix()
        digest = module_integrity.sha256_of_file(f)
        files.append(rel)
        file_hashes[rel] = digest
        pairs.append((rel, digest))
    manifest = module_integrity.compute_manifest_sha256(pairs) if pairs else ""
    return files, file_hashes, manifest


def adopt_artifact(
    repo_root: Path,
    directory: Path,
    *,
    category: str,
    version: str,
) -> dict:
    """Register `directory` in the registry under `category`.

    Returns a result dict: {ok, name, files, manifest, unicode_warnings, already}.
    """
    key = _REGISTRY_KEY[category]
    name = directory.name

    unicode_warnings = scan_unicode(directory)
    files, file_hashes, manifest = compute_dir_hashes(repo_root, directory)

    registry = module_integrity.load_registry(repo_root)
    entries = registry.setdefault(key, [])
    already = any(e.get("name") == name for e in entries)
    if not already:
        entries.append({
            "name": name,
            "version": version,
            "files": files,
            "fileHashes": file_hashes,
            "manifestSha256": manifest,
        })
        module_integrity.save_registry(repo_root, registry)

    return {
        "ok": True,
        "name": name,
        "category": category,
        "files": len(files),
        "manifest": manifest,
        "unicode_warnings": unicode_warnings,
        "already": already,
    }
