#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

TARGET_PATH="${1:-}"
FORMAT="generic"

if [[ -z "$TARGET_PATH" ]]; then
    echo "Usage: $(basename "$0") <extension-path> [--format generic|tailored]" >&2
    exit 2
fi
shift || true

while [[ $# -gt 0 ]]; do
    case "$1" in
        --format)
            FORMAT="${2:-generic}"
            shift 2
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 2
            ;;
    esac
done

if [[ ! -d "$TARGET_PATH" ]]; then
    echo "Extension path not found: $TARGET_PATH" >&2
    exit 2
fi

MANIFEST="$TARGET_PATH/sdd-extension.json"
if [[ ! -f "$MANIFEST" ]]; then
    echo "Missing manifest: $MANIFEST" >&2
    exit 1
fi

python3 - "$REPO_ROOT" "$TARGET_PATH" "$MANIFEST" "$FORMAT" << 'PY'
import json
import sys
from pathlib import Path

repo_root = Path(sys.argv[1])
ext_path = Path(sys.argv[2])
manifest_path = Path(sys.argv[3])
fmt = sys.argv[4]

errors = []
warnings = []

try:
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
except Exception as exc:
    print(f"ERROR: invalid JSON manifest: {exc}")
    raise SystemExit(1)

schema_map = {
    "generic": repo_root / ".sdd-extensions" / "schema" / "sdd-extension.schema.json",
    "tailored": repo_root / ".sdd-extensions" / "schema" / "sdd-tailored-extension.schema.json",
}
schema_path = schema_map.get(fmt)
if schema_path and schema_path.exists():
    try:
        import jsonschema  # type: ignore

        schema = json.loads(schema_path.read_text(encoding="utf-8"))
        resolver = jsonschema.RefResolver(base_uri=schema_path.parent.as_uri() + "/", referrer=schema)
        jsonschema.validate(instance=manifest, schema=schema, resolver=resolver)
    except ModuleNotFoundError:
        warnings.append("jsonschema package not installed; using built-in structural checks only")
    except Exception as exc:
        errors.append(f"schema validation failed ({schema_path.name}): {exc}")
elif schema_path:
    warnings.append(f"schema file not found: {schema_path}")

for key in ("name", "version"):
    if key not in manifest:
        errors.append(f"missing required field: {key}")

name = str(manifest.get("name", ""))
if name and not name.startswith("sdd-extension-"):
    errors.append("name must start with 'sdd-extension-'")

if fmt not in {"generic", "tailored"}:
    errors.append("--format must be generic or tailored")

if fmt == "tailored":
    if manifest.get("type") != "tailored-frontend":
        errors.append("tailored format requires type='tailored-frontend'")
    if manifest.get("domainCategory") not in {"stratos", "search", "review"}:
        errors.append("tailored format requires domainCategory in {stratos, search, review}")
    ns = manifest.get("namespacePrefix")
    if ns not in {"fe", "aws-fe"}:
        errors.append("tailored format requires namespacePrefix in {fe, aws-fe}")

for section in ("hooks", "commands", "templates"):
    value = manifest.get(section, {})
    if value is None:
        continue
    if not isinstance(value, dict):
        errors.append(f"{section} must be an object")
        continue
    for _, rel in value.items():
        target = ext_path / str(rel)
        if not target.exists():
            errors.append(f"{section} path not found: {rel}")

for section in ("instructions", "prompts"):
    values = manifest.get(section, []) or []
    if not isinstance(values, list):
        errors.append(f"{section} must be an array")
        continue
    for rel in values:
        target = ext_path / str(rel)
        if not target.exists():
            errors.append(f"{section} file not found: {rel}")

setup = manifest.get("setupTemplate")
if setup:
    setup_path = ext_path / str(setup)
    if not setup_path.exists():
        errors.append(f"setupTemplate not found: {setup}")

compat = manifest.get("compatibilityMatrix") or {}
if compat and not isinstance(compat, dict):
    errors.append("compatibilityMatrix must be an object")

module_registry = repo_root / ".sdd-modules" / "registry.json"
installed_modules = set()
if module_registry.exists():
    try:
        payload = json.loads(module_registry.read_text(encoding="utf-8"))
        installed_modules = {str(m.get("name", "")) for m in payload.get("installedModules", []) if m.get("name")}
    except Exception:
        warnings.append("could not parse .sdd-modules/registry.json")

config_file = repo_root / ".specify" / "config.json"
active_presets = set()
if config_file.exists():
    try:
        cfg = json.loads(config_file.read_text(encoding="utf-8"))
        preset = cfg.get("activePreset")
        if preset:
            active_presets.add(str(preset))
    except Exception:
        warnings.append("could not parse .specify/config.json")

required_modules = set(compat.get("requiredModules", []) or [])
blocked_modules = set(compat.get("blockedModules", []) or [])
required_presets = set(compat.get("requiredPresets", []) or [])
blocked_presets = set(compat.get("blockedPresets", []) or [])

missing_modules = sorted(required_modules - installed_modules)
if missing_modules:
    errors.append(f"missing required modules: {', '.join(missing_modules)}")

conflicting_modules = sorted(blocked_modules & installed_modules)
if conflicting_modules:
    errors.append(f"blocked modules installed: {', '.join(conflicting_modules)}")

if required_presets and not (required_presets & active_presets):
    errors.append("no required preset active")

conflicting_presets = sorted(blocked_presets & active_presets)
if conflicting_presets:
    errors.append(f"blocked presets active: {', '.join(conflicting_presets)}")

if warnings:
    for warning in warnings:
        print(f"WARNING: {warning}")

if errors:
    print("VALIDATION FAILED")
    for err in errors:
        print(f" - {err}")
    raise SystemExit(1)

print("VALIDATION PASSED")
print(f" - manifest: {manifest_path}")
print(f" - format: {fmt}")
PY
