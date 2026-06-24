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

python3 - "$MEMORY_DIR" "$FEATURE_DIR" "$FEATURE_ID" << 'PY'
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

memory_dir = Path(sys.argv[1])
feature_dir = Path(sys.argv[2])
feature_id = sys.argv[3]

# Check all 6 required memory files
required_files = [
    "constitution.md",
    "session-state.md",
    "decisions.md",
    "lessons.md",
    "research-cache.md",
    "metrics-log.md",
]

now = datetime.now(timezone.utc)
stale_threshold_days = 7
missing = []
stale = []
issues = []

print(f"Memory Doctor — Feature: {feature_id}")
print("=" * 50)
print()

# --- File existence check ---
print("File Existence Check:")
for fname in required_files:
    p = memory_dir / fname
    if p.exists():
        age_days = (now - datetime.fromtimestamp(p.stat().st_mtime, tz=timezone.utc)).days
        status = "OK"
        if age_days > stale_threshold_days:
            stale.append((fname, age_days))
            status = f"STALE ({age_days}d old)"
        print(f"  ✓ {fname:<25s} [{status}]")
    else:
        missing.append(fname)
        print(f"  ✗ {fname:<25s} [MISSING]")
print()

# --- Constitution integrity ---
print("Constitution Integrity:")
constitution_path = memory_dir / "constitution.md"
if constitution_path.exists():
    content = constitution_path.read_text(encoding="utf-8")
    expected_articles = ["I", "II", "III", "IV", "V", "VI"]
    for article in expected_articles:
        pattern = rf"## Article {re.escape(article)}[:\s]"
        if re.search(pattern, content):
            print(f"  ✓ Article {article}: found")
        else:
            issues.append(f"constitution missing Article {article}")
            print(f"  ✗ Article {article}: MISSING")
else:
    issues.append("constitution.md not found — cannot verify articles")
    print("  ✗ constitution.md not found")
print()

# --- Staleness report ---
print("Staleness Report (threshold: 7 days):")
if stale:
    for name, age in stale:
        print(f"  ⚠ {name} — {age} days since last update")
else:
    print("  ✓ All files are fresh")
print()

# --- Consistency checks ---
print("Consistency Checks:")
decisions_text = ""
lessons_text = ""
if (memory_dir / "decisions.md").exists():
    decisions_text = (memory_dir / "decisions.md").read_text(encoding="utf-8", errors="ignore")
if (memory_dir / "lessons.md").exists():
    lessons_text = (memory_dir / "lessons.md").read_text(encoding="utf-8", errors="ignore")

if decisions_text and not lessons_text:
    issues.append("orphan decisions: decisions exist but lessons are empty")
    print("  ✗ Orphan decisions detected")

if re.search(r"(?i)use\s+rest", decisions_text) and re.search(r"(?i)avoid\s+rest", decisions_text):
    issues.append("contradictory decisions detected around REST usage")
    print("  ✗ Contradictory REST decisions")

if not issues:
    print("  ✓ No consistency issues")
print()

# --- Summary ---
print("=" * 50)
print(f"Missing files: {len(missing)}")
print(f"Stale files:   {len(stale)}")
print(f"Issues:        {len(issues)}")

if missing:
    print(f"\nMissing: {', '.join(missing)}")
if issues:
    print(f"\nIssues:")
    for i in issues:
        print(f"  - {i}")
    raise SystemExit(1)
else:
    print("\nDiagnostic: PASS")
PY
