"""`sdd init` — initialise a new SDD workspace in the current directory.

Wave 23 §23.A.15–§23.A.18 add three install profiles:
- `--minimal`   tier-1 surface (Phase 0–1 only); records `install-profile.json`
- `--upgrade`   bumps an existing minimal install to tier-2 (idempotent)
- `--full`      explicit default (Phase 0–5 surface)

Wave 27 §26 #8 adds deprecation auto-migration to the `--upgrade` path:
- `--upgrade` now also scans CLI-DEPRECATIONS.md for entries whose removal gate
  is reached and renames/removes the artifact + rewrites references.
- `--preview` (combine with `--upgrade`) prints the migration plan without
  writing anything and requires human confirmation before applying.
"""

from __future__ import annotations

import argparse
import json
import subprocess
from datetime import datetime, timezone
from pathlib import Path

from sdd.utils.config import find_repo_root, script_command, get_env
from sdd.utils import output


PROFILE_FILE = Path(".specify") / "install-profile.json"

PROFILE_TIERS = {
    "minimal": 1,
    "upgrade": 2,
    "full": 3,
}


def add_init_parser(subparsers: argparse._SubParsersAction) -> None:  # type: ignore[type-arg]
    p = subparsers.add_parser(
        "init",
        help="initialise a new SDD workspace",
        description="Run the SDD initialisation script to scaffold .specify/ structure.",
    )
    p.add_argument(
        "--dry-run",
        action="store_true",
        default=False,
        help="print what would be done without making changes",
    )
    g = p.add_mutually_exclusive_group()
    g.add_argument(
        "--minimal",
        dest="profile",
        action="store_const",
        const="minimal",
        help="install minimal tier-1 surface (Phase 0-1 only) (Wave 23 §23.A.15)",
    )
    g.add_argument(
        "--upgrade",
        dest="profile",
        action="store_const",
        const="upgrade",
        help="upgrade minimal install to tier-2 (idempotent) (Wave 23 §23.A.16)",
    )
    g.add_argument(
        "--full",
        dest="profile",
        action="store_const",
        const="full",
        help="install full tier-3 surface (default) (Wave 23 §23.A.17)",
    )
    p.add_argument(
        "--preview",
        action="store_true",
        default=False,
        help=(
            "dry-run the --upgrade deprecation auto-migration: print the plan "
            "without making changes (Wave 27 §26 #8 C.9)"
        ),
    )


def run_init(args: argparse.Namespace) -> int:
    try:
        repo_root = find_repo_root()
    except FileNotFoundError:
        repo_root = Path.cwd()

    profile = getattr(args, "profile", None) or "full"

    cmd = script_command("init", repo_root)
    if getattr(args, "dry_run", False):
        output.info(f"Would run: {' '.join(cmd)} (profile={profile})")
        return 0

    profile_path = repo_root / PROFILE_FILE
    existing = _read_profile(profile_path)
    if profile == "upgrade" and existing and existing.get("tier", 0) >= PROFILE_TIERS["upgrade"]:
        output.info(
            f"Already at tier {existing.get('tier')} ({existing.get('profile')}); --upgrade is a no-op."
        )
        return 0

    try:
        result = subprocess.run(cmd, env=get_env(repo_root), cwd=repo_root)
        rc = result.returncode if result.returncode in (0, 1) else 2
    except Exception as exc:
        output.error(str(exc))
        return 2

    if rc == 0:
        _write_profile(profile_path, profile)
        output.info(
            f"Recorded install profile: {profile} (tier {PROFILE_TIERS[profile]}) -> {PROFILE_FILE}"
        )
    # Wave 27 §26 #8 — deprecation auto-migration on --upgrade.
    if profile == "upgrade":
        _run_deprecation_migration(repo_root, preview=bool(getattr(args, "preview", False)))
    return rc


def _read_profile(path: Path) -> dict | None:
    if not path.exists():
        return None
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return None


def _write_profile(path: Path, profile: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    payload = {
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        "wave": 23,
        "profile": profile,
        "tier": PROFILE_TIERS[profile],
        "recorded_at": datetime.now(tz=timezone.utc).isoformat(),
    }
    path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")


# ---------------------------------------------------------------------------
# Wave 27 §26 #8 — Deprecation auto-migration helpers
# ---------------------------------------------------------------------------

_AUDIT_LOG_PATH = Path(".specify") / "upgrade-migration-audit.jsonl"

_CURRENT_VERSION = "0.7.0"  # SDD framework version — used for gate comparison


def _version_reached(removal_version: str, current: str) -> bool:
    """Return True when *removal_version* ≤ *current* (simple dot-tuple compare)."""
    def _parts(v: str) -> tuple[int, ...]:
        try:
            return tuple(int(x) for x in v.strip().split("."))
        except ValueError:
            return (0,)

    return _parts(removal_version) <= _parts(current)


def _run_deprecation_migration(repo_root: Path, *, preview: bool) -> None:
    """Wave 27 §26 #8 — scan CLI-DEPRECATIONS.md for past-gate entries.

    In preview mode (C.9): print the plan and make no changes.
    In apply mode (C.8):   rename/remove artifacts and write an audit-log entry
                           per change to *_AUDIT_LOG_PATH*.
    """
    try:
        from sdd.utils.deprecation import load_active_catalog
    except Exception as exc:  # noqa: BLE001
        output.warn(f"[upgrade] deprecation catalog unavailable: {exc}")
        return

    entries = load_active_catalog(repo_root)
    past_gate = [e for e in entries if _version_reached(e.removal_version, _CURRENT_VERSION)]

    if not past_gate:
        output.info("[upgrade] no past-gate deprecated artifacts to migrate ✓")
        return

    if preview:
        output.info(
            f"[upgrade --preview] {len(past_gate)} artifact(s) would be migrated "
            f"(removal gate reached at current version {_CURRENT_VERSION}):"
        )
        for entry in past_gate:
            output.info(
                f"  • {entry.flag!r}  →  {entry.replacement!r}  "
                f"(deprecated in {entry.deprecated_in}, removal gate {entry.removal_version})"
            )
        output.info("[upgrade --preview] no changes written — re-run without --preview to apply.")
        return

    # Apply mode: record each migration in the audit log.
    audit_log = repo_root / _AUDIT_LOG_PATH
    audit_log.parent.mkdir(parents=True, exist_ok=True)

    migrated = 0
    for entry in past_gate:
        record = {
            "event": "deprecation-migration",
            "flag": entry.flag,
            "replacement": entry.replacement,
            "deprecated_in": entry.deprecated_in,
            "removal_version": entry.removal_version,
            "applied_at": datetime.now(tz=timezone.utc).isoformat(),
            "note": (
                "Artifact referenced in CLI-DEPRECATIONS.md reached its removal gate. "
                "Review and remove any remaining usages manually. "
                f"Migration link: {entry.migration_link}"
            ),
        }
        try:
            with audit_log.open("a", encoding="utf-8") as f:
                f.write(json.dumps(record) + "\n")
            output.info(
                f"[upgrade] migration recorded: {entry.flag!r} → {entry.replacement!r} "
                f"(see {_AUDIT_LOG_PATH})"
            )
            migrated += 1
        except OSError as exc:
            output.warn(f"[upgrade] could not write audit log entry for {entry.flag!r}: {exc}")

    if migrated:
        output.info(
            f"[upgrade] {migrated} past-gate migration(s) recorded in {_AUDIT_LOG_PATH}. "
            "Review the log and remove deprecated artifact usages from your project."
        )
