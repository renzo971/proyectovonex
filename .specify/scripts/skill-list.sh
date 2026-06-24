#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SKILLS_DIR="$REPO_ROOT/.specify/skills"
SKILL_INDEX="$SKILLS_DIR/SKILL-INDEX.md"

if [[ ! -f "$SKILL_INDEX" ]]; then
    echo "Error: SKILL-INDEX.md not found at $SKILL_INDEX" >&2
    exit 1
fi

echo "Enterprise SDD — Skill Inventory"
echo "================================="
echo ""
printf "%-25s %-12s %s\n" "NAME" "PHASE" "PURPOSE"
printf "%-25s %-12s %s\n" "----" "-----" "-------"

# Parse Available Skills section (local skills — phase: gate)
in_available=0
in_curated=0
while IFS= read -r line; do
    if [[ "$line" == "## Available Skills" ]]; then
        in_available=1
        in_curated=0
        continue
    fi
    if [[ "$line" == "## Curated Skills" ]]; then
        in_available=0
        in_curated=1
        continue
    fi
    if [[ "$line" =~ ^## ]]; then
        in_available=0
        in_curated=0
        continue
    fi

    if [[ $in_available -eq 1 ]] && [[ "$line" =~ ^-\ (.+):\ (.+)$ ]]; then
        name="${BASH_REMATCH[1]}"
        purpose="${BASH_REMATCH[2]}"
        printf "%-25s %-12s %s\n" "$name" "gate" "$purpose"
    fi

    if [[ $in_curated -eq 1 ]] && [[ "$line" =~ ^-\ (.+):\ (.+)$ ]]; then
        name="${BASH_REMATCH[1]}"
        purpose="${BASH_REMATCH[2]}"
        printf "%-25s %-12s %s\n" "$name" "curated" "$purpose"
    fi
done < "$SKILL_INDEX"

echo ""
echo "Source: $SKILL_INDEX"
