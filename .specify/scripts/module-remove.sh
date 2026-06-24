#!/usr/bin/env bash
#
# module-remove.sh — Remove an installed SDD user module
#
# Usage: ./module-remove.sh <module-name>
#
# Reads the module's file list from registry.json, removes all installed files,
# cleans the copilot-instructions supplement block, and updates the registry.
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_error()   { echo -e "${RED}❌ $1${NC}"; }
log_warn()    { echo -e "${YELLOW}⚠️  $1${NC}"; }

usage() {
    cat << 'EOF'
Usage: module-remove.sh <module-name>

Remove an installed SDD user module.

Arguments:
    module-name    Name of the module to remove

Example:
    ./module-remove.sh core-be
EOF
    exit 1
}

# Validate arguments
if [[ $# -lt 1 || -z "$1" ]]; then
    log_error "Module name is required"
    usage
fi

MODULE_NAME="$1"
REGISTRY="$REPO_ROOT/.sdd-modules/registry.json"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🗑️  Removing SDD Module: $MODULE_NAME"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Verify registry exists
if [[ ! -f "$REGISTRY" ]]; then
    log_error "Registry not found at $REGISTRY"
    exit 1
fi

# Verify module is installed
MODULE_ENTRY=$(jq -r --arg name "$MODULE_NAME" '.installedModules[] | select(.name == $name)' "$REGISTRY" 2>/dev/null || true)
if [[ -z "$MODULE_ENTRY" ]]; then
    log_error "Module '$MODULE_NAME' is not installed"
    exit 1
fi

MODULE_VERSION=$(echo "$MODULE_ENTRY" | jq -r '.version // "unknown"')
log_info "Removing module v$MODULE_VERSION..."

# Remove installed files
REMOVED_COUNT=0
while IFS= read -r file; do
    FILE_PATH="$REPO_ROOT/$file"
    if [[ -f "$FILE_PATH" ]]; then
        rm "$FILE_PATH"
        log_info "Removed $file"
        ((REMOVED_COUNT++))
    else
        log_warn "File not found (already removed?): $file"
    fi
done < <(echo "$MODULE_ENTRY" | jq -r '.files[]')

log_success "Removed $REMOVED_COUNT file(s)"

# Remove copilot-instructions supplement block
COPILOT_INSTRUCTIONS="$REPO_ROOT/.github/copilot-instructions.md"
if [[ -f "$COPILOT_INSTRUCTIONS" ]]; then
    if grep -q "<!-- BEGIN MODULE: $MODULE_NAME -->" "$COPILOT_INSTRUCTIONS"; then
        # Remove the block between BEGIN and END markers (inclusive)
        sed -i "/<!-- BEGIN MODULE: $MODULE_NAME -->/,/<!-- END MODULE: $MODULE_NAME -->/d" "$COPILOT_INSTRUCTIONS"
        # Remove any trailing blank lines left behind
        sed -i -e :a -e '/^\n*$/{$d;N;ba' -e '}' "$COPILOT_INSTRUCTIONS"
        log_success "Removed copilot-instructions supplement block"
    fi
fi

# Update registry — remove module entry
jq --arg name "$MODULE_NAME" '.installedModules |= map(select(.name != $name))' "$REGISTRY" > "$REGISTRY.tmp"
mv "$REGISTRY.tmp" "$REGISTRY"
log_success "Registry updated"

# Recompose the effective agent set (core + remaining installed module contributions)
COMPOSE_SCRIPT="$SCRIPT_DIR/compose-agents.py"
if [[ -f "$COMPOSE_SCRIPT" ]]; then
    if python3 "$COMPOSE_SCRIPT" --repo-root "$REPO_ROOT" 2>&1; then
        log_success "Agent set recomposed (agents-composed.json updated)"
    else
        log_warn "compose-agents.py failed — agents-composed.json may be stale"
    fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_success "Module '$MODULE_NAME' removed successfully ($REMOVED_COUNT files)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
