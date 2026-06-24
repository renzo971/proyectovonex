#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
MEMORY_DIR="$REPO_ROOT/.specify/memory"
SPECS_DIR="$REPO_ROOT/.specify/specs"

FEATURE_ID="${1:-}"
if [[ -z "$FEATURE_ID" ]]; then
    echo "Usage: $(basename "$0") <feature-id>" >&2
    exit 2
fi

FEATURE_DIR="$SPECS_DIR/$FEATURE_ID"
if [[ ! -d "$FEATURE_DIR" ]]; then
    echo "Feature not found: $FEATURE_ID" >&2
    exit 1
fi

INDEX_FILE="$MEMORY_DIR/memory-index.md"
if [[ ! -f "$INDEX_FILE" ]]; then
    bash "$SCRIPT_DIR/memory-index.sh" "$FEATURE_ID" >/dev/null
fi

python3 - "$MEMORY_DIR" "$FEATURE_DIR" "$FEATURE_ID" << 'PY'
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

memory_dir = Path(sys.argv[1])
feature_dir = Path(sys.argv[2])
feature_id = sys.argv[3]

tracked = [
    memory_dir / "memory-index.md",
    memory_dir / "session-state.md",
    memory_dir / "decisions.md",
    memory_dir / "lessons.md",
    memory_dir / "research-cache.md",
    memory_dir / "metrics-log.md",
    feature_dir / "spec.md",
    feature_dir / "plan.md",
    feature_dir / "tasks.md",
]

now = datetime.now(timezone.utc)
existing = [p for p in tracked if p.exists()]
if not existing:
    freshness = 0
    stale = 0
    last_sync = "N/A"
else:
    ages = []
    stale = 0
    latest = None
    for p in existing:
        mtime = datetime.fromtimestamp(p.stat().st_mtime, tz=timezone.utc)
        ages.append((now - mtime).days)
        if (now - mtime).days > 30:
            stale += 1
        if latest is None or mtime > latest:
            latest = mtime

    avg_age = sum(ages) / len(ages)
    freshness = max(0, int(round(100 - min(100, avg_age * 3.0))))
    last_sync = latest.strftime("%Y-%m-%d %H:%M:%S UTC") if latest else "N/A"

unresolved = 0
for fname in ("decisions.md", "lessons.md", "session-state.md"):
    p = memory_dir / fname
    if p.exists():
        text = p.read_text(encoding="utf-8", errors="ignore")
        unresolved += len(re.findall(r"UNRESOLVED|TODO-CONFLICT|CONFLICT", text))

print(f"Memory Status for feature {feature_id}")
print(f"Freshness Score: {freshness}%")
print(f"Stale Files: {stale}")
print(f"Unresolved Conflicts: {unresolved}")
print(f"Last Sync: {last_sync}")
PY
