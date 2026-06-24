#!/usr/bin/env bash
# setup-module.sh — Replace placeholders in core-be module files
# Usage: ./setup-module.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# ── Colors ──────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
log_info()    { echo -e "${CYAN}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC}   $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error()   { echo -e "${RED}[ERR]${NC}  $1"; }

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Core-BE — Placeholder Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ── Collect inputs ──────────────────────────────────────────────
read -rp "Project name (e.g., order-api): " PROJECT_NAME
if [[ -z "$PROJECT_NAME" ]]; then
    log_error "Project name is required"
    exit 1
fi

read -rp "GitLab Project ID (numeric): " GITLAB_PROJECT_ID
if [[ -z "$GITLAB_PROJECT_ID" ]]; then
    log_warn "GitLab Project ID not provided — skipping that placeholder"
fi

read -rp "Tenant domain prefix (e.g., cph): " TENANT_DOMAIN
if [[ -z "$TENANT_DOMAIN" ]]; then
    log_warn "Tenant domain not provided — skipping that placeholder"
fi

# ── Replacement targets ────────────────────────────────────────
# Search in .github/instructions, .github/guidances, .github/prompts,
# .specify/templates/setup, copilot-instructions-supplement markers
SEARCH_DIRS=(
    "$REPO_ROOT/.github/instructions"
    "$REPO_ROOT/.github/guidances"
    "$REPO_ROOT/.github/prompts"
    "$REPO_ROOT/.specify/templates/setup"
)

REPLACED=0

for DIR in "${SEARCH_DIRS[@]}"; do
    if [[ ! -d "$DIR" ]]; then continue; fi

    while IFS= read -r -d '' FILE; do
        CHANGED=false

        if grep -q '{project-name}' "$FILE" 2>/dev/null; then
            sed -i "s/{project-name}/$PROJECT_NAME/g" "$FILE"
            CHANGED=true
        fi

        if [[ -n "${GITLAB_PROJECT_ID:-}" ]] && grep -q '{gitlab-project-id}' "$FILE" 2>/dev/null; then
            sed -i "s/{gitlab-project-id}/$GITLAB_PROJECT_ID/g" "$FILE"
            CHANGED=true
        fi

        if [[ -n "${TENANT_DOMAIN:-}" ]] && grep -q '{tenant-domain}' "$FILE" 2>/dev/null; then
            sed -i "s/{tenant-domain}/$TENANT_DOMAIN/g" "$FILE"
            CHANGED=true
        fi

        if $CHANGED; then
            log_success "Updated: ${FILE#$REPO_ROOT/}"
            ((REPLACED++))
        fi
    done < <(find "$DIR" -type f -name "*.md" -print0)
done

# Also replace in copilot-instructions.md supplement block
COPILOT_FILE="$REPO_ROOT/.github/copilot-instructions.md"
if [[ -f "$COPILOT_FILE" ]]; then
    CHANGED=false
    if grep -q '{project-name}' "$COPILOT_FILE"; then
        sed -i "s/{project-name}/$PROJECT_NAME/g" "$COPILOT_FILE"
        CHANGED=true
    fi
    if [[ -n "${GITLAB_PROJECT_ID:-}" ]] && grep -q '{gitlab-project-id}' "$COPILOT_FILE"; then
        sed -i "s/{gitlab-project-id}/$GITLAB_PROJECT_ID/g" "$COPILOT_FILE"
        CHANGED=true
    fi
    if $CHANGED; then
        log_success "Updated: .github/copilot-instructions.md"
        ((REPLACED++))
    fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_success "Placeholder replacement complete — $REPLACED files updated"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
