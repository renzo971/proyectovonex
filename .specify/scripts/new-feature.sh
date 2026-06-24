#!/usr/bin/env bash
#
# new-feature.sh - Initialize a new feature directory with templates
#
# Usage: ./new-feature.sh "feature-name"
# Example: ./new-feature.sh "user-authentication"
#
# Creates:
#   .specify/specs/NNN-feature-name/
#   ├── business-context.md
#   ├── spec.md
#   └── contracts/
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SPECS_DIR="$REPO_ROOT/.specify/specs"
TEMPLATES_DIR="$REPO_ROOT/.specify/templates"
MEMORY_DIR="$REPO_ROOT/.specify/memory"
TARGET_REPO_ROOT="$REPO_ROOT"
TARGET_SPECS_DIR="$SPECS_DIR"
TARGET_TEMPLATES_DIR="$TEMPLATES_DIR"
TARGET_MEMORY_DIR="$MEMORY_DIR"

# Helper functions
log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}" >&2; }

usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS] <feature-name>

Initialize a new feature directory with templates.

Arguments:
    feature-name    Name of the feature (will be slugified)

Options:
    -h, --help      Show this help message
    -l, --level     Ceremony level: ultra-light, standard, full (default: standard)
    -p, --po        Product Owner name (default: from git config)
    -t, --team      Team name (optional)
    --worktree      Create isolated git worktree for this feature
    --execution-mode  Execution mode: standard, autonomous-guided, autonomous-governed (default: standard)
    --autonomy-budget Maximum autonomous cycles (default: 0 for standard, 10 for autonomous modes)
    --dry-run       Show what would be created without creating

Ceremony Levels:
    ultra-light     Bug fix / typo — skip Phases 1-2, minimal gate checks
    standard        Typical feature — full pipeline (default)
    full            Architecture change — all gates + extra review + mandatory clarification

Examples:
    $(basename "$0") "user authentication"
    $(basename "$0") -l ultra-light "fix login typo"
    $(basename "$0") -l full -p "John Doe" "microservice migration"
    $(basename "$0") --worktree "payments reconciliation"
    $(basename "$0") --dry-run "api gateway"

EOF
    exit 0
}

slugify() {
    echo "$1" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd '[:alnum:]-' | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//'
}

get_next_feature_number() {
    local max_num=0
    
    if [[ -d "$SPECS_DIR" ]]; then
        while IFS= read -r dir; do
            if [[ "$dir" =~ ^([0-9]+)- ]]; then
                local num="${BASH_REMATCH[1]}"
                num=$((10#$num)) # Remove leading zeros for comparison
                if [[ $num -gt $max_num ]]; then
                    max_num=$num
                fi
            fi
        done < <(ls "$SPECS_DIR" 2>/dev/null)
    fi
    
    printf '%03d' $((max_num + 1))
}

validate_constitution() {
    if [[ ! -f "$MEMORY_DIR/constitution.md" ]]; then
        log_warning "No constitution found at $MEMORY_DIR/constitution.md"
        log_warning "Consider running the Constitution Agent first to establish project principles."
        echo ""
        read -p "Continue anyway? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

read_budget_ceiling() {
    local default_budget="50.00"
    local constitution="$MEMORY_DIR/constitution.md"
    [[ ! -f "$constitution" ]] && { echo "$default_budget"; return; }

    local extracted
    extracted=$(grep -Eio 'budget ceiling[^0-9]*[0-9]+(\.[0-9]+)?' "$constitution" 2>/dev/null | grep -Eo '[0-9]+(\.[0-9]+)?' | head -n1 || true)
    if [[ -n "$extracted" ]]; then
        printf '%.2f\n' "$extracted"
    else
        echo "$default_budget"
    fi
}

create_feature_from_template() {
    local template_file="$1"
    local output_file="$2"
    local feature_name="$3"
    local feature_id="$4"
    local feature_slug="$5"
    local owner="$6"
    local date="$7"
    
    if [[ -f "$template_file" ]]; then
        sed -e "s/\[FEATURE_NAME\]/$feature_name/g" \
            -e "s/\[NNN\]/$feature_id/g" \
            -e "s/\[feature-slug\]/$feature_slug/g" \
            -e "s/\[DATE\]/$date/g" \
            -e "s/\[Product Owner Name\]/$owner/g" \
            -e "s/\[Product Owner name\]/$owner/g" \
            -e "s/\[Name\]/$owner/g" \
            "$template_file" > "$output_file"
        log_success "Created $(basename "$output_file")"
    else
        log_warning "Template not found: $template_file"
    fi
}

run_extension_hooks() {
    local hook_name="$1"
    shift
    local extensions_dir="$TARGET_REPO_ROOT/.sdd-extensions"
    if [[ ! -d "$extensions_dir" ]]; then
        return 0
    fi
    for ext_dir in "$extensions_dir"/*/; do
        local manifest="$ext_dir/sdd-extension.json"
        if [[ ! -f "$manifest" ]]; then
            continue
        fi
        local hook_script
        if command -v jq &>/dev/null; then
            hook_script=$(jq -r --arg hook "$hook_name" '.hooks[$hook] // empty' "$manifest" 2>/dev/null)
        else
            hook_script=$(python3 -c "import json,sys; d=json.load(open('$manifest', encoding='utf-8')); print(d.get('hooks',{}).get('$hook_name',''))" 2>/dev/null)
        fi
        if [[ -n "$hook_script" && -f "$ext_dir/$hook_script" ]]; then
            log_info "Running extension hook: $hook_name from $(basename "$ext_dir")"
            bash "$ext_dir/$hook_script" "$@" || log_warning "Extension hook failed (non-fatal): $ext_dir/$hook_script"
        fi
    done
}

# Parse arguments
DRY_RUN=false
PO_NAME=""
TEAM_NAME=""
CEREMONY_LEVEL="standard"
TEMPLATE_NAME=""
WORKTREE=false
EXECUTION_MODE="standard"
AUTONOMY_BUDGET=""
ON_BRANCH=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            ;;
        -l|--level)
            CEREMONY_LEVEL="$2"
            if [[ ! "$CEREMONY_LEVEL" =~ ^(ultra-light|standard|full)$ ]]; then
                log_error "Invalid ceremony level: $CEREMONY_LEVEL"
                log_error "Must be: ultra-light, standard, or full"
                exit 1
            fi
            shift 2
            ;;
        -p|--po)
            PO_NAME="$2"
            shift 2
            ;;
        -t|--team)
            TEAM_NAME="$2"
            shift 2
            ;;
        --template)
            TEMPLATE_NAME="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --worktree)
            WORKTREE=true
            shift
            ;;
        --execution-mode)
            EXECUTION_MODE="$2"
            if [[ ! "$EXECUTION_MODE" =~ ^(standard|autonomous-guided|autonomous-governed)$ ]]; then
                log_error "Invalid execution mode: $EXECUTION_MODE"
                log_error "Must be: standard, autonomous-guided, or autonomous-governed"
                exit 1
            fi
            shift 2
            ;;
        --autonomy-budget)
            AUTONOMY_BUDGET="$2"
            shift 2
            ;;
        --on-branch)
            ON_BRANCH=true
            shift
            ;;
        -*)
            log_error "Unknown option: $1"
            usage
            ;;
        *)
            FEATURE_NAME="$1"
            shift
            ;;
    esac
done

# Validate arguments
if [[ -z "${FEATURE_NAME:-}" ]]; then
    log_error "Feature name is required"
    usage
fi

# Set defaults
if [[ -z "$PO_NAME" ]]; then
    PO_NAME=$(git config user.name 2>/dev/null || echo "Unknown")
fi

if [[ -n "$TEMPLATE_NAME" ]]; then
    case "$TEMPLATE_NAME" in
        minimal) CEREMONY_LEVEL="ultra-light" ;;
        standard) CEREMONY_LEVEL="standard" ;;
        full|enterprise) CEREMONY_LEVEL="full" ;;
        *)
            log_warning "Unknown template '$TEMPLATE_NAME' - using ceremony level '$CEREMONY_LEVEL'"
            ;;
    esac
fi

# Calculate feature details
FEATURE_SLUG=$(slugify "$FEATURE_NAME")
FEATURE_NUM=$(get_next_feature_number)
FEATURE_ID="${FEATURE_NUM}-${FEATURE_SLUG}"
TODAY=$(date +%Y-%m-%d)

if $WORKTREE; then
    WORKTREE_SCRIPT="$SCRIPT_DIR/worktree-create.sh"
    if [[ ! -f "$WORKTREE_SCRIPT" ]]; then
        log_error "Worktree script not found: $WORKTREE_SCRIPT"
        exit 1
    fi
    bash "$WORKTREE_SCRIPT" "$FEATURE_ID"
    TARGET_REPO_ROOT="$REPO_ROOT/.sdd/worktrees/$FEATURE_ID"
    TARGET_SPECS_DIR="$TARGET_REPO_ROOT/.specify/specs"
    TARGET_TEMPLATES_DIR="$TARGET_REPO_ROOT/.specify/templates"
    TARGET_MEMORY_DIR="$TARGET_REPO_ROOT/.specify/memory"
fi

FEATURE_DIR="$TARGET_SPECS_DIR/$FEATURE_ID"

if ! $DRY_RUN; then
    run_extension_hooks "before-new-feature" "$FEATURE_ID"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🚀 New Feature Initialization"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
log_info "Feature Name:  $FEATURE_NAME"
log_info "Feature ID:    $FEATURE_ID"
log_info "Directory:     $FEATURE_DIR"
log_info "Owner:         $PO_NAME"
log_info "Date:          $TODAY"
log_info "Ceremony:      $CEREMONY_LEVEL"
log_info "Execution Mode: $EXECUTION_MODE"
log_info "Worktree:      $WORKTREE"
[[ -n "$TEMPLATE_NAME" ]] && log_info "Template:      $TEMPLATE_NAME"
echo ""

if $DRY_RUN; then
    log_warning "DRY RUN - No files will be created"
    echo ""
    echo "Would create:"
    echo "  $FEATURE_DIR/"
    echo "  ├── .feature-meta.json       (ceremony: $CEREMONY_LEVEL)"
    echo "  ├── cost-log.json            (budget + token/cost entries)"
    if [[ "$CEREMONY_LEVEL" == "ultra-light" ]]; then
        echo "  ├── spec.md                  (minimal)"
        echo "  ├── tasks.md"
        echo "  └── ship-checklist.md"
    else
        echo "  ├── business-context.md"
        echo "  ├── spec.md"
        echo "  ├── clarifications.md"
        echo "  ├── plan.md"
        echo "  ├── test-cases.md"
        echo "  ├── tasks.md"
        echo "  ├── analysis-report.md"
        echo "  ├── ship-checklist.md"
        echo "  └── contracts/"
    fi
    if $WORKTREE; then
        echo "  + git worktree under .sdd/worktrees/$FEATURE_ID"
    fi
    echo ""
    exit 0
fi

# Validate prerequisites
validate_constitution

# Create directory structure
log_info "Creating directory structure..."
if [[ "$CEREMONY_LEVEL" != "ultra-light" ]]; then
    mkdir -p "$FEATURE_DIR/contracts"
else
    mkdir -p "$FEATURE_DIR"
fi

# Write feature metadata (ceremony level, creation date, etc.)
# Escape double quotes in variable values for valid JSON
SAFE_FEATURE_NAME=$(echo "$FEATURE_NAME" | sed 's/"/\\"/g')
SAFE_PO_NAME=$(echo "$PO_NAME" | sed 's/"/\\"/g')
# Resolve autonomy budget default
if [[ -z "$AUTONOMY_BUDGET" ]]; then
    if [[ "$EXECUTION_MODE" == "standard" ]]; then
        AUTONOMY_BUDGET=0
    else
        AUTONOMY_BUDGET=10
    fi
fi

cat > "$FEATURE_DIR/.feature-meta.json" << METAEOF
{
  "featureId": "$FEATURE_ID",
  "featureName": "$SAFE_FEATURE_NAME",
  "ceremonyLevel": "$CEREMONY_LEVEL",
  "template": "${TEMPLATE_NAME:-default}",
  "owner": "$SAFE_PO_NAME",
  "createdAt": "$TODAY",
  "status": "active",
  "executionMode": "$EXECUTION_MODE",
  "autonomyBudget": $AUTONOMY_BUDGET,
  "autonomyMaxIterations": 3,
  "escalationThreshold": 3,
  "autonomyItemLimit": 1,
  "autonomyContextReset": "required-per-item",
  "autonomyPersistenceRequired": true,
  "fallbackExecutionMode": "standard",
  "lastAutonomyStatus": "idle"
}
METAEOF
log_success "Created .feature-meta.json (ceremony: $CEREMONY_LEVEL, mode: $EXECUTION_MODE)"

# Wave 20 — Persist feature.lock.json so downstream commands (gate, analyze,
# ship) can resolve the active feature without relying on branch-name heuristics
# alone. Schema is intentionally additive: existing workspaces without this
# file remain compatible.
CURRENT_BRANCH="$(git -C "$TARGET_REPO_ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'unknown')"
SAFE_BRANCH="$(echo "$CURRENT_BRANCH" | sed 's/"/\\"/g')"
LOCK_CREATED_AT="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
cat > "$FEATURE_DIR/feature.lock.json" << LOCKEOF
{
  "schemaVersion": 1,
  "feature_id": "$FEATURE_ID",
  "feature_directory": ".specify/specs/$FEATURE_ID",
  "branch": "$SAFE_BRANCH",
  "branch_pin_mode": "$( $ON_BRANCH && echo 'on-branch' || echo 'feature-branch' )",
  "created_at": "$LOCK_CREATED_AT"
}
LOCKEOF
log_success "Created feature.lock.json (branch: $CURRENT_BRANCH, pin: $( $ON_BRANCH && echo on-branch || echo feature-branch ))"

BUDGET_CEILING=$(read_budget_ceiling)
cat > "$FEATURE_DIR/cost-log.json" << COSTEOF
{
    "featureId": "$FEATURE_ID",
    "entries": [],
    "totalCost": 0.0,
    "budgetCeiling": $BUDGET_CEILING
}
COSTEOF
log_success "Created cost-log.json (budget ceiling: $BUDGET_CEILING)"

# Create files from templates — scope depends on ceremony level
log_info "Creating files from templates (ceremony: $CEREMONY_LEVEL)..."

if [[ "$CEREMONY_LEVEL" == "ultra-light" ]]; then
    # Ultra-Light: minimal artifacts — skip Phases 1-2 templates
    create_feature_from_template \
        "$TARGET_TEMPLATES_DIR/spec-template.md" \
        "$FEATURE_DIR/spec.md" \
        "$FEATURE_NAME" "$FEATURE_NUM" "$FEATURE_SLUG" "$PO_NAME" "$TODAY"

    create_feature_from_template \
        "$TARGET_TEMPLATES_DIR/tasks-template.md" \
        "$FEATURE_DIR/tasks.md" \
        "$FEATURE_NAME" "$FEATURE_NUM" "$FEATURE_SLUG" "$PO_NAME" "$TODAY"

    create_feature_from_template \
        "$TARGET_TEMPLATES_DIR/ship-checklist-template.md" \
        "$FEATURE_DIR/ship-checklist.md" \
        "$FEATURE_NAME" "$FEATURE_NUM" "$FEATURE_SLUG" "$PO_NAME" "$TODAY"

else
    # Standard & Full: all artifacts
    create_feature_from_template \
        "$TARGET_TEMPLATES_DIR/business-context-template.md" \
        "$FEATURE_DIR/business-context.md" \
        "$FEATURE_NAME" "$FEATURE_NUM" "$FEATURE_SLUG" "$PO_NAME" "$TODAY"

    create_feature_from_template \
        "$TARGET_TEMPLATES_DIR/spec-template.md" \
        "$FEATURE_DIR/spec.md" \
        "$FEATURE_NAME" "$FEATURE_NUM" "$FEATURE_SLUG" "$PO_NAME" "$TODAY"

    create_feature_from_template \
        "$TARGET_TEMPLATES_DIR/clarifications-template.md" \
        "$FEATURE_DIR/clarifications.md" \
        "$FEATURE_NAME" "$FEATURE_NUM" "$FEATURE_SLUG" "$PO_NAME" "$TODAY"

    create_feature_from_template \
        "$TARGET_TEMPLATES_DIR/plan-template.md" \
        "$FEATURE_DIR/plan.md" \
        "$FEATURE_NAME" "$FEATURE_NUM" "$FEATURE_SLUG" "$PO_NAME" "$TODAY"

    create_feature_from_template \
        "$TARGET_TEMPLATES_DIR/test-cases-template.md" \
        "$FEATURE_DIR/test-cases.md" \
        "$FEATURE_NAME" "$FEATURE_NUM" "$FEATURE_SLUG" "$PO_NAME" "$TODAY"

    create_feature_from_template \
        "$TARGET_TEMPLATES_DIR/tasks-template.md" \
        "$FEATURE_DIR/tasks.md" \
        "$FEATURE_NAME" "$FEATURE_NUM" "$FEATURE_SLUG" "$PO_NAME" "$TODAY"

    create_feature_from_template \
        "$TARGET_TEMPLATES_DIR/analysis-report-template.md" \
        "$FEATURE_DIR/analysis-report.md" \
        "$FEATURE_NAME" "$FEATURE_NUM" "$FEATURE_SLUG" "$PO_NAME" "$TODAY"

    create_feature_from_template \
        "$TARGET_TEMPLATES_DIR/ship-checklist-template.md" \
        "$FEATURE_DIR/ship-checklist.md" \
        "$FEATURE_NAME" "$FEATURE_NUM" "$FEATURE_SLUG" "$PO_NAME" "$TODAY"
fi

# Create empty contract placeholders (not needed for ultra-light)
if [[ "$CEREMONY_LEVEL" != "ultra-light" ]]; then
    touch "$FEATURE_DIR/contracts/.gitkeep"
fi

# Compatibility scaffold for Wave 9 CLI contract
# Keep legacy artifacts (plan.md, analysis-report.md) and add aliases expected by the contract.
if [[ ! -f "$FEATURE_DIR/design.md" ]]; then
    if [[ -f "$FEATURE_DIR/plan.md" ]]; then
        cp "$FEATURE_DIR/plan.md" "$FEATURE_DIR/design.md"
    else
        cat > "$FEATURE_DIR/design.md" << EOF
# Design: $FEATURE_NAME

## Architecture Decisions

- [Add key design decisions]

## Technical Approach

- [Describe implementation approach]
EOF
    fi
    log_success "Created design.md"
fi

if [[ ! -f "$FEATURE_DIR/implementation.md" ]]; then
    cat > "$FEATURE_DIR/implementation.md" << EOF
# Implementation: $FEATURE_NAME

## Plan

- [Implementation steps]

## Progress

- [ ] Step 1

## Notes

- [Add implementation notes]
EOF
    log_success "Created implementation.md"
fi

# Reset session state for new feature (Wave 8: structured memory)
SESSION_STATE="$TARGET_MEMORY_DIR/session-state.md"
if [[ -f "$SESSION_STATE" ]]; then
    sed -i "s/^- \*\*Feature ID:\*\* .*/- **Feature ID:** $FEATURE_ID/" "$SESSION_STATE"
    sed -i "s/^- \*\*Feature Name:\*\* .*/- **Feature Name:** $FEATURE_NAME/" "$SESSION_STATE"
    sed -i "s/^- \*\*Ceremony Level:\*\* .*/- **Ceremony Level:** $CEREMONY_LEVEL/" "$SESSION_STATE"
    sed -i "s/^- \*\*Current Phase:\*\* .*/- **Current Phase:** Phase 1/" "$SESSION_STATE"
    sed -i "s/^- \*\*Last Gate Passed:\*\* .*/- **Last Gate Passed:** —/" "$SESSION_STATE"
    sed -i "s/^- \*\*Last Gate Timestamp:\*\* .*/- **Last Gate Timestamp:** —/" "$SESSION_STATE"
    # Reset phase checkboxes
    sed -i "s/^- \[x\]/- [ ]/" "$SESSION_STATE"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_success "Feature $FEATURE_ID initialized successfully! (ceremony: $CEREMONY_LEVEL)"

run_extension_hooks "after-new-feature" "$FEATURE_ID"

echo ""
echo "  📂 $FEATURE_DIR"
echo ""
if [[ "$CEREMONY_LEVEL" == "ultra-light" ]]; then
    echo "  Next steps (ultra-light — skip Phases 1-2):"
    echo "  1. Fill in spec.md with the quick scope"
    echo "  2. Generate tasks: @software-engineer (Planning mode)"
    echo "  3. Implement: @test-engineer → @software-engineer"
    echo "  4. Review: @review → validate-gate.sh $FEATURE_ID 4"
elif [[ "$CEREMONY_LEVEL" == "full" ]]; then
    echo "  Next steps (full ceremony — all phases + extra review):"
    echo "  1. Work with PO to complete business-context.md"
    echo "  2. Run: @requirement-analyst with vision mode"
    echo "  3. Mandatory clarification: @clarification"
    echo "  4. Full pipeline through all gates with extra review"
else
    echo "  Next steps:"
    echo "  1. Work with PO to complete business-context.md"
    echo "  2. Run: @requirement-analyst with vision mode"
    echo "  3. After PO approval, elaborate spec.md with FA"
fi
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
