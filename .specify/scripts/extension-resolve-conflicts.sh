#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

TARGET_PATH="${1:-}"
DRY_RUN=false

if [[ -z "$TARGET_PATH" ]]; then
    echo "Usage: $(basename "$0") <extension-path> [--dry-run]" >&2
    exit 2
fi
shift || true

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 2
            ;;
    esac
done

MANIFEST="$TARGET_PATH/sdd-extension.json"
if [[ ! -f "$MANIFEST" ]]; then
    echo "Missing manifest: $MANIFEST" >&2
    exit 1
fi

python3 - "$TARGET_PATH" "$MANIFEST" "$DRY_RUN" << 'PY'
import json
import sys
from pathlib import Path

ext_path = Path(sys.argv[1])
manifest_path = Path(sys.argv[2])
dry_run = sys.argv[3].lower() == "true"

core_agents = {
    "architect",
    "analysis",
    "requirement-analyst",
    "software-engineer",
    "test-engineer",
    "review",
    "constitution",
}

forbidden_targets = {
    ".specify/memory/constitution.md",
    ".specify/scripts/validate-gate.sh",
    ".specify/scripts/validate-gate.ps1",
    ".github/agents",
}

conflicts = []
install_plan = []

manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
namespace = manifest.get("namespacePrefix")

print("Layering order: module -> extension -> preset (immutable order)")

for section in ("hooks", "commands", "templates"):
    values = manifest.get(section, {}) or {}
    if isinstance(values, dict):
        for rel in values.values():
            install_plan.append(str(ext_path / str(rel)))

for section in ("instructions", "prompts"):
    values = manifest.get(section, []) or []
    if isinstance(values, list):
        for rel in values:
            install_plan.append(str(ext_path / str(rel)))

setup = manifest.get("setupTemplate")
if setup:
    install_plan.append(str(ext_path / str(setup)))

agent_patches = manifest.get("agentPatches", {}) or {}
if isinstance(agent_patches, dict):
    for key in agent_patches.keys():
        if key in core_agents:
            conflicts.append(f"core immutability violation: agentPatches attempts to override core agent '{key}'")

templates = manifest.get("templates", {}) or {}
if isinstance(templates, dict):
    for _, value in templates.items():
        target = str(value)
        if any(target.startswith(prefix) for prefix in forbidden_targets):
            conflicts.append(f"core immutability violation: template target '{target}'")

instructions = manifest.get("instructions", []) or []
prompts = manifest.get("prompts", []) or []

if namespace in {"fe", "aws-fe"}:
    expected_instruction_prefix = f"{namespace}-"
    forbidden_instruction_prefix = "aws-fe-" if namespace == "fe" else "fe-"

    for rel in instructions:
        name = Path(str(rel)).name
        if not name.startswith(expected_instruction_prefix):
            conflicts.append(
                f"namespace isolation violation: instruction '{rel}' must start with '{expected_instruction_prefix}'"
            )
        if name.startswith(forbidden_instruction_prefix):
            conflicts.append(
                f"namespace isolation violation: instruction '{rel}' crosses namespace boundary"
            )

    for rel in prompts:
        rel_s = str(rel).replace("\\\\", "/")
        if f"/{namespace}/" not in f"/{rel_s}":
            conflicts.append(
                f"namespace isolation violation: prompt '{rel}' must be stored under '/{namespace}/'"
            )
        other = "aws-fe" if namespace == "fe" else "fe"
        if f"/{other}/" in f"/{rel_s}":
            conflicts.append(
                f"namespace isolation violation: prompt '{rel}' crosses namespace boundary"
            )

print("Install plan:")
for item in sorted(set(install_plan)):
    print(f" - {item}")

if conflicts:
    print("Conflicts:")
    for item in conflicts:
        print(f" - {item}")
    raise SystemExit(1)

if dry_run:
    print("Dry-run: no files changed")
else:
    print("No conflicts detected")
PY
