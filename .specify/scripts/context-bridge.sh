#!/usr/bin/env bash
#
# context-bridge.sh - Generate compressed context summary for phase transitions
#
# Usage: ./context-bridge.sh <feature-id> [target-phase]
# Example: ./context-bridge.sh 001-user-auth 3
#
# Generates a context bridge document at .specify/specs/<feature-id>/context-bridge.md
# that summarizes all completed phases for the target phase's agents.
#

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SPECS_DIR="$REPO_ROOT/.specify/specs"
MEMORY_DIR="$REPO_ROOT/.specify/memory"
CHECKPOINTS_DIR="$REPO_ROOT/.specify/checkpoints"

# Helper functions
log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}" >&2; }

usage() {
    cat << EOF
Usage: $(basename "$0") <feature-id> [target-phase]

Generate a compressed context summary for phase transitions.

Arguments:
    feature-id      Feature directory name (e.g., 001-user-auth)
    target-phase    Phase number to prepare for (1-5). Default: auto-detect next phase.

Examples:
    $(basename "$0") 001-user-auth
    $(basename "$0") 001-user-auth 3

EOF
    exit 0
}

if [[ "${1:-}" == "-h" ]] || [[ "${1:-}" == "--help" ]]; then
    usage
fi

FEATURE_ID="${1:?Feature ID required. Usage: context-bridge.sh <feature-id> [target-phase]}"
FEATURE_DIR="$SPECS_DIR/$FEATURE_ID"

if [[ ! -d "$FEATURE_DIR" ]]; then
    log_error "Feature directory not found: $FEATURE_DIR"
    exit 1
fi

# Determine target phase
TARGET_PHASE="${2:-}"
if [[ -z "$TARGET_PHASE" ]]; then
    # Auto-detect from checkpoint
    CHECKPOINT_FILE="$CHECKPOINTS_DIR/${FEATURE_ID}.checkpoint"
    if [[ -f "$CHECKPOINT_FILE" ]] && command -v python3 &>/dev/null; then
        last_gate=$(python3 -c "import json; print(json.load(open('$CHECKPOINT_FILE',encoding='utf-8-sig')).get('gate',0))" 2>/dev/null || echo "0")
        TARGET_PHASE=$((last_gate + 1))
    else
        TARGET_PHASE=1
    fi
fi

# Phase name lookup
phase_name() {
    case $1 in
        1) echo "Requirements" ;;
        2) echo "Design" ;;
        3) echo "Preparation" ;;
        4) echo "Implementation" ;;
        5) echo "Quality Assurance" ;;
        *) echo "Unknown" ;;
    esac
}

# Ceremony level detection
get_ceremony_level() {
    local meta_file="$FEATURE_DIR/.feature-meta.json"
    if [[ -f "$meta_file" ]] && command -v python3 &>/dev/null; then
        python3 -c "import json; print(json.load(open('$meta_file',encoding='utf-8-sig')).get('ceremonyLevel','standard'))" 2>/dev/null || echo "standard"
    else
        echo "standard"
    fi
}

CEREMONY_LEVEL=$(get_ceremony_level)
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
PHASE_NAME=$(phase_name "$TARGET_PHASE")

log_info "Generating context bridge for $FEATURE_ID → Phase $TARGET_PHASE ($PHASE_NAME)"

# Extract feature name from business-context.md or directory
FEATURE_NAME="$FEATURE_ID"
if [[ -f "$FEATURE_DIR/business-context.md" ]]; then
    extracted=$(grep -m1 '^# ' "$FEATURE_DIR/business-context.md" 2>/dev/null | sed 's/^# //')
    [[ -n "$extracted" ]] && FEATURE_NAME="$extracted"
fi

# Start building the context bridge
OUTPUT="$FEATURE_DIR/context-bridge.md"
{
    echo "# Context Bridge: $FEATURE_NAME"
    echo ""
    echo "**Feature ID:** $FEATURE_ID"
    echo "**Generated:** $TIMESTAMP"
    echo "**Target Phase:** $TARGET_PHASE — $PHASE_NAME"
    echo "**Ceremony Level:** $CEREMONY_LEVEL"
    echo ""
    echo "---"
    echo ""

    # Feature Goal
    echo "## Feature Goal"
    echo ""
    if [[ -f "$FEATURE_DIR/business-context.md" ]]; then
        goal=$(grep -A 3 '## Purpose' "$FEATURE_DIR/business-context.md" 2>/dev/null | tail -n +2 | head -3 | sed '/^$/d')
        if [[ -n "$goal" ]]; then
            echo "$goal"
        else
            echo "(Not yet defined)"
        fi
    else
        echo "(business-context.md not yet created)"
    fi
    echo ""

    # Completed Phases Summary
    echo "## Completed Phases Summary"
    echo ""

    # Phase 1: Requirements
    if [[ $TARGET_PHASE -gt 1 ]] && [[ -f "$FEATURE_DIR/spec.md" ]]; then
        us_count=$(grep -oE 'US-[0-9]+' "$FEATURE_DIR/spec.md" 2>/dev/null | sort -u | wc -l | tr -d ' ')
        ac_count=$(grep -oE 'AC-[0-9]+' "$FEATURE_DIR/spec.md" 2>/dev/null | sort -u | wc -l | tr -d ' ')
        nc_count=0
        for md_file in "$FEATURE_DIR"/*.md; do
            [[ -f "$md_file" ]] || continue
            c=$(grep -c '\[NEEDS CLARIFICATION:' "$md_file" 2>/dev/null || true)
            nc_count=$((nc_count + ${c:-0}))
        done

        echo "### Phase 1: Requirements (Gate 1 ✅)"
        echo "- **User Stories:** $us_count"
        echo "- **Acceptance Criteria:** $ac_count"
        if [[ -f "$FEATURE_DIR/clarifications.md" ]]; then
            decisions=$(grep -cE '^\*\*Decision:\*\*|^- \*\*Decision' "$FEATURE_DIR/clarifications.md" 2>/dev/null || echo "0")
            echo "- **Key Decisions:** $decisions recorded"
        fi
        echo "- **Open Questions:** $nc_count remaining [NEEDS CLARIFICATION] markers"
        echo ""
    fi

    # Phase 2: Design
    if [[ $TARGET_PHASE -gt 2 ]] && [[ -f "$FEATURE_DIR/plan.md" ]]; then
        arch=$(grep -m1 -E '#{2,3}.*[Aa]rchitect' "$FEATURE_DIR/plan.md" 2>/dev/null | sed 's/^#* //' || echo "Not specified")
        components=$(grep -E '^#{2,4} ' "$FEATURE_DIR/plan.md" 2>/dev/null | head -10 | sed 's/^#* /- /')
        has_openapi="no"
        has_asyncapi="no"
        [[ -f "$FEATURE_DIR/contracts/openapi.yaml" ]] && has_openapi="yes"
        [[ -f "$FEATURE_DIR/contracts/asyncapi.yaml" ]] && has_asyncapi="yes"

        echo "### Phase 2: Design (Gate 2 ✅)"
        echo "- **Architecture Pattern:** $arch"
        echo "- **Contracts:** OpenAPI: $has_openapi, AsyncAPI: $has_asyncapi"
        echo ""
    fi

    # Phase 3: Preparation
    if [[ $TARGET_PHASE -gt 3 ]] && [[ -f "$FEATURE_DIR/test-cases.md" ]]; then
        tc_count=$(grep -oE 'TC-[0-9]+' "$FEATURE_DIR/test-cases.md" 2>/dev/null | sort -u | wc -l | tr -d ' ')
        task_count=0
        [[ -f "$FEATURE_DIR/tasks.md" ]] && task_count=$(grep -oE 'T[0-9]{3}' "$FEATURE_DIR/tasks.md" 2>/dev/null | sort -u | wc -l | tr -d ' ')
        verdict="Not available"
        if [[ -f "$FEATURE_DIR/analysis-report.md" ]]; then
            if grep -qiE 'Verdict:\s*PASS\b' "$FEATURE_DIR/analysis-report.md"; then
                verdict="PASS"
            elif grep -qiE 'Verdict:\s*PASS WITH WARNINGS' "$FEATURE_DIR/analysis-report.md"; then
                verdict="PASS WITH WARNINGS"
            elif grep -qiE 'Verdict:\s*FAIL' "$FEATURE_DIR/analysis-report.md"; then
                verdict="FAIL"
            fi
        fi

        echo "### Phase 3: Preparation (Gate 3 ✅)"
        echo "- **Test Cases:** $tc_count"
        echo "- **Tasks:** $task_count"
        echo "- **Analysis Verdict:** $verdict"
        echo ""
    fi

    # Artifacts Available
    echo "## Artifacts Available"
    echo ""
    for f in "$FEATURE_DIR"/*.md "$FEATURE_DIR"/contracts/*.yaml "$FEATURE_DIR"/contracts/*.yml; do
        [[ -f "$f" ]] || continue
        echo "- $(basename "$f")"
    done
    echo ""

    # Key Constraints
    echo "## Key Constraints"
    echo ""
    if [[ -f "$MEMORY_DIR/constitution.md" ]]; then
        echo "(See .specify/memory/constitution.md for project-wide constraints)"
    else
        echo "(No constitution defined)"
    fi
    echo ""
} > "$OUTPUT"

log_success "Context bridge generated: $OUTPUT"
echo ""
echo "  Target: Phase $TARGET_PHASE — $PHASE_NAME"
echo "  Ceremony: $CEREMONY_LEVEL"
echo ""
