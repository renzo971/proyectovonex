#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

python3 - "$REPO_ROOT" << 'PY'
import json
import pathlib
import sys

repo_root = pathlib.Path(sys.argv[1])
taxonomy_path = repo_root / ".specify" / "command-taxonomy.json"

if not taxonomy_path.exists():
    print(f"Missing taxonomy file: {taxonomy_path}", file=sys.stderr)
    sys.exit(1)

payload = json.loads(taxonomy_path.read_text(encoding="utf-8"))
errors = []

command_phase_map = payload.get("commandPhaseMap", [])
if not isinstance(command_phase_map, list) or not command_phase_map:
    errors.append("commandPhaseMap must be a non-empty list")

seen = {}
for row in command_phase_map:
    if not isinstance(row, dict):
        errors.append("Each commandPhaseMap item must be an object")
        continue
    command_id = str(row.get("id", "")).strip()
    phase = str(row.get("phase", "")).strip()
    prompt = str(row.get("prompt", "")).strip()

    if not command_id:
        errors.append("commandPhaseMap item missing id")
        continue
    if command_id in seen:
        errors.append(f"Command appears multiple times in commandPhaseMap: {command_id}")
    seen[command_id] = phase

    if not phase:
        errors.append(f"Missing phase for command: {command_id}")
    if not prompt:
        errors.append(f"Missing prompt for command: {command_id}")
    if prompt:
        prompt_path = repo_root / ".github" / "prompts" / prompt
        if not prompt_path.exists():
            errors.append(f"Missing curated prompt file: {prompt}")

curated = payload.get("curatedPrompts", [])
if not isinstance(curated, list) or len(curated) != 8:
    errors.append("curatedPrompts must contain exactly 8 prompt files")

for prompt in curated:
    prompt_path = repo_root / ".github" / "prompts" / str(prompt)
    if not prompt_path.exists():
        errors.append(f"Prompt listed in curatedPrompts does not exist: {prompt}")

skill_phase_map = payload.get("skillPhaseMap", [])
for skill_row in skill_phase_map:
    skill_id = str(skill_row.get("id", "")).strip()
    if not skill_id:
        errors.append("skillPhaseMap item missing id")
        continue
    skill_path = repo_root / ".github" / "skills" / skill_id / "SKILL.md"
    if not skill_path.exists():
        errors.append(f"Missing curated skill: {skill_id}")

if errors:
    print("Command taxonomy mapping validation failed:", file=sys.stderr)
    for err in errors:
        print(f"- {err}", file=sys.stderr)
    sys.exit(1)

print("Command taxonomy mapping validation passed")
PY
