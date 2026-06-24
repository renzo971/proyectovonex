#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

SKILL_NAME="${1:-}"
FEATURE_ID="${2:-}"
DRY_RUN="${3:-}"

if [[ -z "$SKILL_NAME" || -z "$FEATURE_ID" ]]; then
    echo "Usage: $(basename "$0") <skill-name> <feature-id> [--dry-run]" >&2
    exit 2
fi

FEATURE_DIR="$REPO_ROOT/.specify/specs/$FEATURE_ID"
if [[ ! -d "$FEATURE_DIR" ]]; then
    echo "Feature not found: $FEATURE_ID" >&2
    exit 1
fi

SKILL_FILE=""
if [[ -f "$REPO_ROOT/.github/skills/$SKILL_NAME/SKILL.md" ]]; then
    SKILL_FILE="$REPO_ROOT/.github/skills/$SKILL_NAME/SKILL.md"
elif [[ -f "$REPO_ROOT/.specify/skills/$SKILL_NAME.skill.md" ]]; then
    SKILL_FILE="$REPO_ROOT/.specify/skills/$SKILL_NAME.skill.md"
else
    echo "Skill not found: $SKILL_NAME" >&2
    exit 1
fi

echo "== Skill Execution =="
echo "Skill: $SKILL_NAME"
echo "Feature: $FEATURE_ID"
echo "Skill file: ${SKILL_FILE#$REPO_ROOT/}"
echo ""

echo "[Checks]"
for required in spec.md plan.md tasks.md; do
    if [[ -f "$FEATURE_DIR/$required" ]]; then
        echo "- $required: present"
    else
        echo "- $required: missing"
    fi
done
echo ""

echo "[Plan]"
awk 'BEGIN{capture=0}
     /^## (Execution Plan|Flow|Checklist|Steps)/{capture=1}
     /^## / && capture==1 && !/^## (Execution Plan|Flow|Checklist|Steps)/{exit}
     {if (capture==1) print}
' "$SKILL_FILE" | sed '/^$/d' || true

echo ""
if [[ "$DRY_RUN" == "--dry-run" ]]; then
    echo "DRY-RUN: no command was executed."
    exit 0
fi

echo "[Execution]"
echo "Execution is policy-driven: apply actions manually or via dedicated automation for this skill."
echo "Completed: deterministic skill run context emitted."
