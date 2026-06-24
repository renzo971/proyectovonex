#!/usr/bin/env bash

set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "Usage: $(basename "$0") <extension-path>" >&2
    exit 2
fi

EXT_PATH="$1"
MANIFEST="$EXT_PATH/sdd-extension.json"

if [[ ! -f "$MANIFEST" ]]; then
    echo "Missing manifest: $MANIFEST" >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SANDBOX="$SCRIPT_DIR/.sandbox"
INSTALL_ROOT="$SANDBOX/install-root"
HOOK_LOG="$SANDBOX/hook-order.log"
PRE_INVENTORY="$SANDBOX/pre-inventory.txt"
POST_INVENTORY="$SANDBOX/post-inventory.txt"
AFTER_UNINSTALL="$SANDBOX/after-uninstall.txt"
INSTALLED_TRACKER="$SANDBOX/installed-files.txt"

rm -rf "$SANDBOX"
mkdir -p "$INSTALL_ROOT"

find "$INSTALL_ROOT" -type f | sort > "$PRE_INVENTORY"

python3 - "$EXT_PATH" "$MANIFEST" "$INSTALL_ROOT" "$HOOK_LOG" "$INSTALLED_TRACKER" << 'PY'
import json
import shutil
import subprocess
import sys
from pathlib import Path

ext = Path(sys.argv[1])
manifest = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
install_root = Path(sys.argv[3])
hook_log = Path(sys.argv[4])
tracker = Path(sys.argv[5])

installed = []

def _copy(rel: str) -> None:
    src = ext / rel
    if not src.exists():
        return
    dst = install_root / rel
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, dst)
    installed.append(str(dst))

for section in ("instructions", "prompts"):
    for rel in manifest.get(section, []) or []:
        _copy(str(rel))

for section in ("hooks", "commands", "templates"):
    values = manifest.get(section, {}) or {}
    if isinstance(values, dict):
        for rel in values.values():
            _copy(str(rel))

setup = manifest.get("setupTemplate")
if setup:
    _copy(str(setup))

hooks = manifest.get("hooks", {}) or {}
for hook_name in sorted(hooks.keys()):
    script_rel = str(hooks[hook_name])
    script_path = ext / script_rel
    if script_path.exists():
        result = subprocess.run(["bash", str(script_path), hook_name], capture_output=True, text=True)
        hook_log.parent.mkdir(parents=True, exist_ok=True)
        with hook_log.open("a", encoding="utf-8") as f:
            f.write(f"{hook_name}:{result.returncode}\n")

tracker.write_text("\n".join(installed) + ("\n" if installed else ""), encoding="utf-8")
PY

find "$INSTALL_ROOT" -type f | sort > "$POST_INVENTORY"

if [[ ! -s "$POST_INVENTORY" ]]; then
    echo "Snapshot test failed: install produced no files" >&2
    exit 1
fi

while IFS= read -r file; do
    [[ -z "$file" ]] && continue
    rm -f "$file"
done < "$INSTALLED_TRACKER"

find "$INSTALL_ROOT" -type f | sort > "$AFTER_UNINSTALL"

if [[ -s "$AFTER_UNINSTALL" ]]; then
    echo "Snapshot test failed: orphan files remain after uninstall" >&2
    cat "$AFTER_UNINSTALL" >&2
    exit 1
fi

if [[ ! -f "$HOOK_LOG" ]]; then
    echo "Snapshot test failed: hook order log not generated" >&2
    exit 1
fi

echo "SNAPSHOT TEST PASSED"
echo " - extension: $EXT_PATH"
echo " - hook-log: $HOOK_LOG"
