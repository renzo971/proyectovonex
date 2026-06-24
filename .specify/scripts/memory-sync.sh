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

NOW_UTC="$(date -u +"%Y-%m-%d %H:%M:%S UTC")"

echo "Memory Sync for feature: $FEATURE_ID"
echo "======================================"
echo ""

# --- Freshness drift detection ---
SESSION_STATE="$MEMORY_DIR/session-state.md"
FEATURE_META="$FEATURE_DIR/.feature-meta.json"
DRIFT_THRESHOLD_SECONDS=86400  # 24 hours

detect_drift() {
    local file="$1"
    local label="$2"
    if [[ -f "$file" ]]; then
        local file_epoch
        file_epoch=$(stat -f "%m" "$file" 2>/dev/null || stat -c "%Y" "$file" 2>/dev/null || echo "0")
        local now_epoch
        now_epoch=$(date +%s)
        local age=$((now_epoch - file_epoch))
        if [[ $age -gt $DRIFT_THRESHOLD_SECONDS ]]; then
            local hours=$((age / 3600))
            echo "  DRIFT: $label is ${hours}h old (threshold: 24h)"
            return 1
        else
            echo "  OK: $label is fresh"
            return 0
        fi
    else
        echo "  MISSING: $label not found"
        return 1
    fi
}

echo "Freshness Check:"
drift_detected=0
detect_drift "$SESSION_STATE" "session-state.md" || drift_detected=1
detect_drift "$FEATURE_META" ".feature-meta.json" || drift_detected=1
echo ""

# --- Conflict detection ---
echo "Conflict Detection:"
conflicts=0
if [[ -f "$SESSION_STATE" ]] && [[ -f "$FEATURE_META" ]]; then
    # Check if session-state references a different feature
    if grep -q "featureId" "$SESSION_STATE" 2>/dev/null; then
        session_feature=$(grep -o '"featureId"[[:space:]]*:[[:space:]]*"[^"]*"' "$SESSION_STATE" 2>/dev/null | head -1 | sed 's/.*"featureId"[[:space:]]*:[[:space:]]*"\([^"]*\)"/\1/' || true)
        if [[ -n "$session_feature" ]] && [[ "$session_feature" != "$FEATURE_ID" ]]; then
            echo "  CONFLICT: session-state references feature '$session_feature' but syncing '$FEATURE_ID'"
            conflicts=$((conflicts + 1))
        fi
    fi
fi
if [[ $conflicts -eq 0 ]]; then
    echo "  OK: no conflicts detected"
fi
echo ""

# --- Run memory index if available ---
if [[ -f "$SCRIPT_DIR/memory-index.sh" ]]; then
    bash "$SCRIPT_DIR/memory-index.sh" "$FEATURE_ID" >/dev/null 2>&1 || true
fi

# --- Sync timestamps ---
echo "- [$NOW_UTC] [$FEATURE_ID] memory sync cycle completed" >> "$MEMORY_DIR/decisions.md"
echo "- [$NOW_UTC] [$FEATURE_ID] learning snapshot updated after sync" >> "$MEMORY_DIR/lessons.md"
echo "| $NOW_UTC | $FEATURE_ID | memory-sync | n/a | pass | 0 | 0 | n/a | automated sync |" >> "$MEMORY_DIR/metrics-log.md"

# --- Update session-state with sync timestamp ---
python3 - "$SESSION_STATE" "$NOW_UTC" << 'PY'
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
now = sys.argv[2]

if not path.exists():
    raise SystemExit(0)

text = path.read_text(encoding="utf-8")
line = f"- **Last Memory Sync:** {now}"

# Keep the section idempotent: one header and one timestamp line.
text = re.sub(r"(?ms)^## Memory Operations\n\n- \*\*Last Memory Sync:\*\*.*?(?=\n## |\Z)", "", text).rstrip()
if re.search(r"(?m)^- \*\*Last Memory Sync:\*\*.*$", text):
    text = re.sub(r"(?m)^- \*\*Last Memory Sync:\*\*.*$", line, text)
else:
    text += "\n## Memory Operations\n\n" + line + "\n"
path.write_text(text, encoding="utf-8")
PY

echo "Sync Report:"
echo "  Drift detected: $([ $drift_detected -eq 0 ] && echo 'no' || echo 'yes')"
echo "  Conflicts: $conflicts"
echo ""
echo "Memory sync completed for feature: $FEATURE_ID"
