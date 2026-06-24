"""`sdd preset apply <name>` — apply a named preset configuration."""

from __future__ import annotations

import argparse
import json
import shutil
from pathlib import Path

from sdd.utils.config import find_repo_root
from sdd.utils import output
from sdd.io import atomic_write_json

_BUILTIN_PRESETS: dict[str, str] = {
    "minimal": "Ceremony level 1 — quick-fix / hotfix workflow",
    "standard": "Ceremony level 2 — typical feature workflow",
    "full": "Ceremony level 3 — full SDD enterprise workflow",
    "enterprise": "Ceremony level 4 — maximum governance and traceability",
    "sdd-preset-api": "REST API-focused — API Champion prominent, Messaging Champion optional",
    "sdd-preset-event-driven": "Async event-driven — Messaging Champion prominent, API Champion optional",
    "sdd-preset-monorepo": "Monorepo — multi-package support with per-package gates",
}


def add_preset_parser(subparsers: argparse._SubParsersAction) -> None:  # type: ignore[type-arg]
    p = subparsers.add_parser(
        "preset",
        help="apply a configuration preset",
        description="Apply a named preset to configure ceremony level and defaults.",
    )
    ps = p.add_subparsers(dest="preset_action", metavar="<action>")
    ps.required = True

    apply_p = ps.add_parser("apply", help="apply a preset")
    apply_p.add_argument(
        "preset_name",
        metavar="<name>",
        choices=list(_BUILTIN_PRESETS.keys()),
        help=f"preset to apply ({', '.join(_BUILTIN_PRESETS)})",
    )
    apply_p.add_argument(
        "--dry-run",
        action="store_true",
        default=False,
        help="show what would change without writing",
    )
    apply_p.add_argument(
        "--wrap",
        metavar="<overlay>",
        action="append",
        default=None,
        help="overlay preset to stack on top of base (repeatable for multiple layers)",
    )

    ps.add_parser("list", help="list available presets")

    show_p = ps.add_parser("show", help="show current preset configuration")
    show_p.add_argument(
        "--resolved",
        action="store_true",
        default=False,
        help="display effective merged configuration after all layers are applied",
    )


def run_preset(args: argparse.Namespace) -> int:
    action: str = args.preset_action

    if action == "list":
        return _list_presets()
    if action == "apply":
        return _apply_preset(args)
    if action == "show":
        return _show_preset(args)

    output.error(f"Unknown preset action: {action}")
    return 2


def _list_presets() -> int:
    print("Available presets:")
    for name, desc in _BUILTIN_PRESETS.items():
        print(f"  {name:<12} {desc}")
    return 0


def _apply_preset(args: argparse.Namespace) -> int:
    preset_name: str = args.preset_name
    dry_run: bool = getattr(args, "dry_run", False)

    try:
        repo_root = find_repo_root()
    except FileNotFoundError as exc:
        output.error(str(exc))
        return 2

    preset_file = repo_root / ".specify" / "presets" / f"{preset_name}.json"
    config_path = repo_root / ".specify" / "config.json"

    if not preset_file.exists():
        output.warn(
            f"No preset file at {preset_file}. "
            "Only ceremony-level flag will be set."
        )
        ceremony_map = {"minimal": 1, "standard": 2, "full": 3, "enterprise": 4}
        level = ceremony_map.get(preset_name, 2)
        config: dict = {}
        if config_path.exists():
            try:
                config = json.loads(config_path.read_text())
            except json.JSONDecodeError:
                config = {}
        config["ceremonyLevel"] = level
        if dry_run:
            output.info(f"Would write {config_path}: {json.dumps(config, indent=2)}")
            return 0
        atomic_write_json(config_path, config, sort_keys=False)
        output.success(f"Preset '{preset_name}' applied (ceremony level {level})")
        return 0

    try:
        preset_data = json.loads(preset_file.read_text())
    except json.JSONDecodeError as exc:
        output.error(f"Invalid preset file: {exc}")
        return 2

    if dry_run:
        output.info(f"Would apply preset '{preset_name}':")
        print(json.dumps(preset_data, indent=2))
        return 0

    if config_path.exists():
        try:
            config = json.loads(config_path.read_text())
        except json.JSONDecodeError:
            config = {}
    else:
        config = {}

    config.update(preset_data)
    atomic_write_json(config_path, config, sort_keys=False)
    output.success(f"Preset '{preset_name}' applied")

    # Apply wrap overlays if specified
    wraps: list[str] | None = getattr(args, "wrap", None)
    if wraps:
        for overlay_name in wraps:
            overlay_file = repo_root / ".specify" / "presets" / f"{overlay_name}.json"
            if overlay_file.exists():
                try:
                    overlay_data = json.loads(overlay_file.read_text())
                    config.update(overlay_data)
                    output.info(f"  + overlay '{overlay_name}' applied")
                except json.JSONDecodeError as exc:
                    output.warn(f"Invalid overlay preset '{overlay_name}': {exc}")
            else:
                output.warn(f"Overlay preset '{overlay_name}' not found at {overlay_file}")
        atomic_write_json(config_path, config, sort_keys=False)
        output.success(f"Preset '{preset_name}' applied with {len(wraps)} overlay(s)")

    return 0


def _show_preset(args: argparse.Namespace) -> int:
    """Show current preset configuration, optionally with resolved merged view."""
    try:
        repo_root = find_repo_root()
    except FileNotFoundError as exc:
        output.error(str(exc))
        return 2

    config_path = repo_root / ".specify" / "config.json"
    if not config_path.exists():
        output.info("No configuration file found. Using defaults.")
        return 0

    try:
        config = json.loads(config_path.read_text())
    except json.JSONDecodeError as exc:
        output.error(f"Invalid config.json: {exc}")
        return 2

    resolved: bool = getattr(args, "resolved", False)
    if resolved:
        print("Effective merged configuration:")
    else:
        print("Current configuration:")
    print(json.dumps(config, indent=2))
    return 0
