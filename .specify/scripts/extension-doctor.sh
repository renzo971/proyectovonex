#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

TARGET_PATH="${1:-}"
if [[ -z "$TARGET_PATH" ]]; then
    echo "Usage: $(basename "$0") <extension-path>" >&2
    exit 2
fi

MANIFEST="$TARGET_PATH/sdd-extension.json"
if [[ ! -f "$MANIFEST" ]]; then
    echo "Missing manifest: $MANIFEST" >&2
    exit 1
fi

python3 - "$TARGET_PATH" "$MANIFEST" << 'PY'
import json
import re
import sys
from pathlib import Path

ext_path = Path(sys.argv[1])
manifest_path = Path(sys.argv[2])

issues = []
warnings = []

manifest = json.loads(manifest_path.read_text(encoding="utf-8"))

prompts = [Path(str(item)).name for item in (manifest.get("prompts", []) or [])]
seen = set()
dups = set()
for name in prompts:
    if name in seen:
        dups.add(name)
    seen.add(name)
if dups:
    issues.append(f"duplicate prompt filenames in manifest: {', '.join(sorted(dups))}")

instructions = manifest.get("instructions", []) or []
apply_to_map = {}
for rel in instructions:
    path = ext_path / str(rel)
    if not path.exists():
        continue
    text = path.read_text(encoding="utf-8")
    m = re.search(r"(?m)^applyTo:\s*\"?([^\"\n]+)\"?", text)
    if not m:
        warnings.append(f"instruction has no applyTo: {rel}")
        continue
    glob = m.group(1).strip()
    apply_to_map.setdefault(glob, []).append(str(rel))

for glob, files in apply_to_map.items():
    if len(files) > 1:
        issues.append(f"applyTo overlap '{glob}' across: {', '.join(files)}")

agent_patches = manifest.get("agentPatches", {}) or {}
if isinstance(agent_patches, dict):
    keys = list(agent_patches.keys())
    if len(keys) != len(set(keys)):
        issues.append("agent patch collisions detected")

print("Doctor report:")
print(f" - manifest: {manifest_path}")
print(f" - extension: {manifest.get('name', 'unknown')}")

for warning in warnings:
    print(f"WARNING: {warning}")

if issues:
    print("Issues:")
    for issue in issues:
        print(f" - {issue}")
    raise SystemExit(1)

print("No doctor issues detected")
PY

bash "$SCRIPT_DIR/extension-resolve-conflicts.sh" "$TARGET_PATH" --dry-run
