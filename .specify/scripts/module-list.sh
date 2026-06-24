#!/usr/bin/env bash
#
# module-list.sh — List installed SDD user modules
#
# Usage: ./module-list.sh
#
# Reads registry.json and displays installed modules with metadata.
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

BLUE='\033[0;34m'
GREEN='\033[0;32m'
NC='\033[0m'

REGISTRY="$REPO_ROOT/.sdd-modules/registry.json"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  📋 Installed SDD Modules"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [[ ! -f "$REGISTRY" ]]; then
    echo -e "${BLUE}ℹ️  No registry found. Run 'sdd init' first.${NC}"
    exit 0
fi

MODULE_COUNT=$(jq '.installedModules | length' "$REGISTRY")

if [[ "$MODULE_COUNT" -eq 0 ]]; then
    echo -e "${BLUE}ℹ️  No modules installed.${NC}"
    echo ""
    echo "  Install a module with: sdd module install <name>"
    echo ""
    exit 0
fi

echo -e "${GREEN}$MODULE_COUNT module(s) installed:${NC}"
echo ""

printf "  %-25s %-10s %-25s %s\n" "NAME" "VERSION" "INSTALLED" "FILES"
printf "  %-25s %-10s %-25s %s\n" "-------------------------" "----------" "-------------------------" "-----"

jq -r '.installedModules[] | "  \(.name)\t\(.version)\t\(.installedAt)\t\(.files | length)"' "$REGISTRY" | \
    while IFS=$'\t' read -r name version date files; do
        printf "  %-25s %-10s %-25s %s\n" "$name" "$version" "$date" "$files"
    done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
