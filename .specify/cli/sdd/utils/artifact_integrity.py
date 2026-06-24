"""Artifact integrity ledger (Wave 23 §23.B.4–§23.B.9).

Tracks SHA-256 hashes of managed artifacts under `.specify/specs/<feature-id>/`
so the SDD CLI can detect out-of-band hand-edits ("drift") between writes.

The runtime ledger lives at `.specify/.artifact-hashes.json`. Schema is
documented in `.specify/templates/.artifact-hashes.example.json`.

Schema (per entry):
    {
      "<artifact-relative-path>": {
        "sha256":     "<lowercase hex, 64 chars>",
        "phase":      "0"|"1"|"2"|"3"|"4"|"5",
        "written-at": "<ISO 8601 UTC>",
        "written-by": "<agent-id-or-cli-command>"
      }
    }

Audit log lives at `.specify/.audit-log.jsonl` (append-only, one JSON per line):
    {"ts": "<iso>", "event": "accept-drift", "artifact": "...",
     "old-sha256": "...", "new-sha256": "...", "accepted-by": "<who>"}
"""

from __future__ import annotations

import hashlib
import json
import os
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


HASHES_FILE = Path(".specify") / ".artifact-hashes.json"
AUDIT_LOG_FILE = Path(".specify") / ".audit-log.jsonl"

VALID_PHASES = {"0", "1", "2", "3", "4", "5"}


@dataclass
class ArtifactDrift:
    artifact: str
    expected_sha256: str
    actual_sha256: str | None  # None when the file is missing on disk
    phase: str
    written_at: str
    written_by: str

    @property
    def status(self) -> str:
        if self.actual_sha256 is None:
            return "missing"
        return "drift"


def sha256_of_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def _now_iso() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def _hashes_path(repo_root: Path) -> Path:
    return repo_root / HASHES_FILE


def _audit_path(repo_root: Path) -> Path:
    return repo_root / AUDIT_LOG_FILE


def load_ledger(repo_root: Path) -> dict[str, dict[str, Any]]:
    """Return the ledger dict (or empty if absent / malformed)."""
    p = _hashes_path(repo_root)
    if not p.exists():
        return {}
    try:
        data = json.loads(p.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return {}
    if not isinstance(data, dict):
        return {}
    # Drop schema/comment keys (start with `_` or `$`) when iterating.
    return {k: v for k, v in data.items() if isinstance(v, dict) and "sha256" in v}


def _write_ledger_atomic(repo_root: Path, ledger: dict[str, dict[str, Any]]) -> None:
    p = _hashes_path(repo_root)
    p.parent.mkdir(parents=True, exist_ok=True)
    tmp = p.with_suffix(p.suffix + ".tmp")
    payload = {
        "_schema": (
            "Wave 23 §23.B.4 — see "
            ".specify/templates/.artifact-hashes.example.json for the documented schema."
        ),
    }
    payload.update(ledger)
    tmp.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    os.replace(tmp, p)


def record_write(
    repo_root: Path,
    artifact: Path,
    *,
    phase: str,
    written_by: str,
) -> str:
    """Hash the on-disk artifact and update the ledger atomically.

    Returns the recorded SHA-256. Silent no-op (returns empty string) when the
    artifact path does not exist — callers should hash *after* the file is
    written, not before.
    """
    if str(phase) not in VALID_PHASES:
        # Defensive: don't crash callers; record under "?" but warn via empty phase.
        phase = "?"
    if not artifact.exists():
        return ""
    rel = _relative(repo_root, artifact)
    sha = sha256_of_file(artifact)
    ledger = load_ledger(repo_root)
    ledger[rel] = {
        "sha256": sha,
        "phase": str(phase),
        "written-at": _now_iso(),
        "written-by": written_by,
    }
    _write_ledger_atomic(repo_root, ledger)
    return sha


def _relative(repo_root: Path, artifact: Path) -> str:
    try:
        return str(artifact.resolve().relative_to(repo_root.resolve()))
    except ValueError:
        return str(artifact)


def verify_all(repo_root: Path) -> list[ArtifactDrift]:
    """Recompute hashes for every recorded artifact and return drift entries."""
    ledger = load_ledger(repo_root)
    drifts: list[ArtifactDrift] = []
    for rel, entry in ledger.items():
        path = repo_root / rel
        expected = entry.get("sha256", "")
        if not path.exists():
            drifts.append(ArtifactDrift(
                artifact=rel,
                expected_sha256=expected,
                actual_sha256=None,
                phase=str(entry.get("phase", "?")),
                written_at=str(entry.get("written-at", "")),
                written_by=str(entry.get("written-by", "")),
            ))
            continue
        actual = sha256_of_file(path)
        if actual != expected:
            drifts.append(ArtifactDrift(
                artifact=rel,
                expected_sha256=expected,
                actual_sha256=actual,
                phase=str(entry.get("phase", "?")),
                written_at=str(entry.get("written-at", "")),
                written_by=str(entry.get("written-by", "")),
            ))
    return drifts


def verify_one(repo_root: Path, artifact_rel: str) -> ArtifactDrift | None:
    """Return the drift entry for a single artifact, or None if clean / unknown."""
    ledger = load_ledger(repo_root)
    if artifact_rel not in ledger:
        return None
    entry = ledger[artifact_rel]
    path = repo_root / artifact_rel
    expected = entry.get("sha256", "")
    if not path.exists():
        return ArtifactDrift(
            artifact=artifact_rel,
            expected_sha256=expected,
            actual_sha256=None,
            phase=str(entry.get("phase", "?")),
            written_at=str(entry.get("written-at", "")),
            written_by=str(entry.get("written-by", "")),
        )
    actual = sha256_of_file(path)
    if actual == expected:
        return None
    return ArtifactDrift(
        artifact=artifact_rel,
        expected_sha256=expected,
        actual_sha256=actual,
        phase=str(entry.get("phase", "?")),
        written_at=str(entry.get("written-at", "")),
        written_by=str(entry.get("written-by", "")),
    )


def status_for_artifact(repo_root: Path, artifact_rel: str) -> str:
    """Return one of: 'unchanged', 'drift', 'missing', 'untracked'."""
    ledger = load_ledger(repo_root)
    if artifact_rel not in ledger:
        return "untracked"
    drift = verify_one(repo_root, artifact_rel)
    if drift is None:
        return "unchanged"
    return drift.status


def accept_drift(
    repo_root: Path,
    artifact_rel: str,
    *,
    accepted_by: str,
) -> tuple[str, str] | None:
    """Rebaseline the hash for a deliberately-edited artifact.

    Returns (old_sha, new_sha) on success; None if the artifact is not in the
    ledger or is missing on disk.
    """
    ledger = load_ledger(repo_root)
    if artifact_rel not in ledger:
        return None
    path = repo_root / artifact_rel
    if not path.exists():
        return None
    old_sha = ledger[artifact_rel].get("sha256", "")
    new_sha = sha256_of_file(path)
    ledger[artifact_rel]["sha256"] = new_sha
    ledger[artifact_rel]["written-at"] = _now_iso()
    # Preserve original phase + writer; accept-drift is a rebaseline, not a re-write.
    _write_ledger_atomic(repo_root, ledger)
    _append_audit(repo_root, {
        "ts": _now_iso(),
        "event": "accept-drift",
        "artifact": artifact_rel,
        "old-sha256": old_sha,
        "new-sha256": new_sha,
        "accepted-by": accepted_by,
    })
    return (old_sha, new_sha)


def _append_audit(repo_root: Path, entry: dict[str, Any]) -> None:
    p = _audit_path(repo_root)
    p.parent.mkdir(parents=True, exist_ok=True)
    with p.open("a", encoding="utf-8") as fh:
        fh.write(json.dumps(entry, sort_keys=True) + "\n")


# Phase → set of artifact filenames the SDD CLI is known to produce inside
# `.specify/specs/<feature-id>/`. Wave 23 §23.B.5: after each `sdd new`/`sdd
# gate <N>` succeeds, hashes for any of these files that exist are recorded.
_PHASE_ARTIFACTS: dict[str, tuple[str, ...]] = {
    "1": ("spec.md", "business-context.md"),
    "2": ("clarifications.md",),
    "3": ("plan.md", "data-model.md", "test-cases.md", "tasks.md"),
    "4": ("ship-checklist.md",),
    "5": ("gate4-release-packet.md", "phase-ledger.md"),
}


def record_phase_artifacts(
    repo_root: Path,
    feature_id: str,
    *,
    phase: str,
    written_by: str,
) -> list[tuple[str, str]]:
    """Wave 23 §23.B.5 — record SHAs for every artifact known to be produced by
    the named phase that exists under `.specify/specs/<feature-id>/`.

    Returns the list of (relative-path, sha256) tuples actually recorded. Silent
    no-op when the spec directory does not exist (defensive: never crash a
    successful `sdd new`/`sdd gate` run).
    """
    if str(phase) not in VALID_PHASES:
        return []
    spec_dir = repo_root / ".specify" / "specs" / feature_id
    if not spec_dir.exists() or not spec_dir.is_dir():
        return []
    recorded: list[tuple[str, str]] = []
    filenames = _PHASE_ARTIFACTS.get(str(phase), ())
    for fname in filenames:
        artifact = spec_dir / fname
        if not artifact.exists():
            continue
        sha = record_write(repo_root, artifact, phase=str(phase), written_by=written_by)
        if sha:
            rel = _relative(repo_root, artifact)
            recorded.append((rel, sha))
    return recorded


def diff_drift(repo_root: Path, artifact_rel: str) -> str:
    """Produce a human-readable drift report.

    No snapshot subsystem exists yet; we report the SHA mismatch and a header
    line indicating "hash-only" comparison — fall-back when no snapshot exists,
    as specified in §23.B.9.
    """
    ledger = load_ledger(repo_root)
    if artifact_rel not in ledger:
        return f"untracked: {artifact_rel} is not in the artifact-integrity ledger"
    path = repo_root / artifact_rel
    if not path.exists():
        return (
            f"missing: {artifact_rel} was recorded "
            f"(sha256={ledger[artifact_rel].get('sha256', '')[:12]}…) "
            "but is not present on disk"
        )
    actual = sha256_of_file(path)
    expected = ledger[artifact_rel].get("sha256", "")
    if actual == expected:
        return f"unchanged: {artifact_rel} matches the recorded hash"
    return (
        f"hash mismatch (no snapshot): {artifact_rel}\n"
        f"  recorded: {expected}\n"
        f"  actual:   {actual}\n"
        f"  phase:    {ledger[artifact_rel].get('phase', '?')}\n"
        f"  written-at: {ledger[artifact_rel].get('written-at', '')}\n"
        f"  written-by: {ledger[artifact_rel].get('written-by', '')}"
    )
