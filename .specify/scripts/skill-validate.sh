#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SKILLS_DIR="$REPO_ROOT/.specify/skills"
GITHUB_SKILLS="$REPO_ROOT/.github/skills"

SKILL_NAME="${1:-}"
CHECK_RATIONALIZATIONS=false
# Parse additional flags
for arg in "$@"; do
    if [[ "$arg" == "--rationalizations" ]]; then
        CHECK_RATIONALIZATIONS=true
    fi
done

if [[ -z "$SKILL_NAME" ]]; then
    echo "Usage: $(basename "$0") <skill-name>" >&2
    exit 2
fi

# Search in both locations
SKILL_FILE=""
for dir in "$SKILLS_DIR" "$GITHUB_SKILLS"; do
    candidate="$dir/$SKILL_NAME.skill.md"
    if [[ -f "$candidate" ]]; then
        SKILL_FILE="$candidate"
        break
    fi
    # Also try subdirectories
    found=$(find "$dir" -name "$SKILL_NAME.skill.md" -type f 2>/dev/null | head -1)
    if [[ -n "${found:-}" ]]; then
        SKILL_FILE="$found"
        break
    fi
done

if [[ -z "$SKILL_FILE" ]]; then
    echo "FAIL: Skill not found: $SKILL_NAME" >&2
    exit 1
fi

errors=0

echo "Validating skill: $SKILL_NAME ($SKILL_FILE)"

# Check title header
if ! grep -qi '^# ' "$SKILL_FILE"; then
    echo "  FAIL: missing title header (# ...)" >&2
    errors=$((errors + 1))
fi

# Check required sections
for section in "Steps" "Output Contract"; do
    if ! grep -qi "## $section\|### $section\|$section:" "$SKILL_FILE"; then
        echo "  FAIL: missing required section '$section'" >&2
        errors=$((errors + 1))
    fi
done

# Check optional but recommended sections
for section in "Purpose" "Trigger"; do
    if ! grep -qi "$section" "$SKILL_FILE"; then
        echo "  WARN: missing recommended section '$section'"
    fi
done

if [[ $errors -gt 0 ]]; then
    echo "RESULT: $SKILL_NAME — FAIL ($errors errors)"
    exit 1
fi

# Optional --rationalizations check
if [[ "$CHECK_RATIONALIZATIONS" == "true" ]]; then
    if ! grep -qi "## Common Rationalizations" "$SKILL_FILE"; then
        echo "  FAIL: missing required section '## Common Rationalizations' (required by skill-authoring.instructions.md)" >&2
        echo "RESULT: $SKILL_NAME — FAIL (rationalizations section absent)"
        exit 1
    fi
    # Verify section is non-empty (at least one table row with a pipe character)
    section_content=$(awk '/## Common Rationalizations/{found=1; next} found && /^## /{exit} found{print}' "$SKILL_FILE")
    if ! echo "$section_content" | grep -q '|'; then
        echo "  FAIL: '## Common Rationalizations' section exists but appears empty (no table rows)" >&2
        echo "RESULT: $SKILL_NAME — FAIL (rationalizations section empty)"
        exit 1
    fi
    echo "  PASS: '## Common Rationalizations' section present and non-empty"
fi

echo "RESULT: $SKILL_NAME — PASS (validation passed)"
