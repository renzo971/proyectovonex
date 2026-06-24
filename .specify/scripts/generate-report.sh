#!/usr/bin/env bash
#
# generate-report.sh - Generate analysis-report.md for a feature
#
# Usage: ./generate-report.sh <feature-id>
# Example: ./generate-report.sh 001-user-auth
#
# Generates a complete analysis-report.md by analyzing all artifacts
#

set -u

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

log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}" >&2; }

usage() {
    cat << EOF
Usage: $(basename "$0") <feature-id>

Generate analysis-report.md for a feature.

Arguments:
    feature-id     Feature directory name (e.g., 001-user-auth)

Options:
    -h, --help      Show this help message
    --dry-run       Print to stdout instead of file

Examples:
    $(basename "$0") 001-user-auth

EOF
    exit 0
}

extract_user_stories() {
    local spec_file="$1"
    grep -oE 'US-[0-9]+' "$spec_file" 2>/dev/null | sort -u
}

check_coverage() {
    local item="$1"
    local file="$2"
    grep -q "$item" "$file" 2>/dev/null && echo "✓" || echo "✗"
}

find_coverage_location() {
    local item="$1"
    local file="$2"
    
    if grep -q "$item" "$file" 2>/dev/null; then
        # Try to find section header
        local result
        result=$(grep -B 10 "$item" "$file" 2>/dev/null | grep -oE '^#{1,3}\s+.*' | tail -1 | sed 's/^#\+\s*//' || true)
        echo "${result:-Found}"
    else
        echo "-"
    fi
}

# Parse arguments
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help) usage ;;
        --dry-run) DRY_RUN=true; shift ;;
        -*) log_error "Unknown option: $1"; usage ;;
        *) FEATURE_ID="$1"; shift ;;
    esac
done

if [[ -z "${FEATURE_ID:-}" ]]; then
    log_error "Feature ID is required"
    usage
fi

FEATURE_DIR="$SPECS_DIR/$FEATURE_ID"

if [[ ! -d "$FEATURE_DIR" ]]; then
    log_error "Feature directory not found: $FEATURE_DIR"
    exit 1
fi

# Artifact paths
SPEC_FILE="$FEATURE_DIR/spec.md"
PLAN_FILE="$FEATURE_DIR/plan.md"
TEST_FILE="$FEATURE_DIR/test-cases.md"
TASKS_FILE="$FEATURE_DIR/tasks.md"
OUTPUT_FILE="$FEATURE_DIR/analysis-report.md"

# Warn if analysis-report.md already contains non-template content
if [[ -f "$OUTPUT_FILE" ]]; then
    if ! grep -q '\[FEATURE_NAME\]\|\[NNN\]\|\[DATE\]\|<!-- INSTRUCTION -->' "$OUTPUT_FILE" 2>/dev/null; then
        log_warning "analysis-report.md already exists with non-template content"
        log_warning "This script will overwrite it. If @analysis agent produced this file, use one OR the other — not both."
        echo ""
        read -r -p "Continue and overwrite? [y/N] " response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            log_info "Aborted. Existing analysis-report.md preserved."
            exit 0
        fi
    fi
fi

# Extract feature name from business context or spec
FEATURE_NAME="$FEATURE_ID"
if [[ -f "$FEATURE_DIR/business-context.md" ]]; then
    FEATURE_NAME=$(grep -m1 '^# Business Context:' "$FEATURE_DIR/business-context.md" 2>/dev/null | sed 's/^# Business Context:\s*//' || echo "$FEATURE_ID")
elif [[ -f "$SPEC_FILE" ]]; then
    FEATURE_NAME=$(grep -m1 '^# Feature Specification:' "$SPEC_FILE" 2>/dev/null | sed 's/^# Feature Specification:\s*//' || echo "$FEATURE_ID")
fi

log_info "Generating analysis report for: $FEATURE_NAME"

# Start building report
TODAY=$(date +%Y-%m-%d)
REPORT=""

# Initialize counters
CRITICAL_COUNT=0
WARNING_COUNT=0
CRITICAL_ISSUES=""
WARNING_ISSUES=""
ORPHAN_TASKS=""
ORPHAN_TESTS=""
USER_STORIES=""

# Build traceability matrix
MATRIX=""
if [[ -f "$SPEC_FILE" ]]; then
    USER_STORIES=$(extract_user_stories "$SPEC_FILE")
    
    while IFS= read -r us; do
        [[ -z "$us" ]] && continue
        
        # Plan coverage
        plan_cov=$(check_coverage "$us" "$PLAN_FILE" 2>/dev/null || echo "✗")
        plan_loc=$(find_coverage_location "$us" "$PLAN_FILE" 2>/dev/null || echo "-")
        [[ "$plan_cov" == "✗" ]] && plan_loc="MISSING"
        
        # Task coverage
        task_cov=$(check_coverage "$us" "$TASKS_FILE" 2>/dev/null || echo "✗")
        task_ids=""
        if [[ "$task_cov" == "✓" ]] && [[ -f "$TASKS_FILE" ]]; then
            task_ids=$(grep -oE 'T[0-9]+.*'"$us" "$TASKS_FILE" 2>/dev/null | grep -oE 'T[0-9]+' | tr '\n' ', ' | sed 's/,$//')
            [[ -z "$task_ids" ]] && task_ids=$(grep "$us" "$TASKS_FILE" 2>/dev/null | grep -oE 'T[0-9]+' | head -3 | tr '\n' ', ' | sed 's/,$//')
        fi
        [[ "$task_cov" == "✗" ]] && task_ids="MISSING"
        
        # Test coverage
        test_cov=$(check_coverage "$us" "$TEST_FILE" 2>/dev/null || echo "✗")
        test_ids=""
        if [[ "$test_cov" == "✓" ]] && [[ -f "$TEST_FILE" ]]; then
            test_ids=$(grep -B5 -A5 "$us" "$TEST_FILE" 2>/dev/null | grep -oE 'TC-[0-9]+' | sort -u | tr '\n' ', ' | sed 's/,$//')
        fi
        [[ "$test_cov" == "✗" ]] && test_ids="MISSING"
        
        # Determine status
        if [[ "$plan_cov" == "✗" ]] || [[ "$task_cov" == "✗" ]] || [[ "$test_cov" == "✗" ]]; then
            status="WARN"
            ((WARNING_COUNT++))
            
            if [[ "$task_cov" == "✗" ]]; then
                WARNING_ISSUES+="- $us missing task coverage - Recommendation: Add tasks for $us implementation\n"
            fi
            if [[ "$test_cov" == "✗" ]]; then
                WARNING_ISSUES+="- $us missing test coverage - Recommendation: Add test cases for $us\n"
            fi
        else
            status="OK"
        fi
        
        MATRIX+="| $us     | $plan_cov $plan_loc | $task_cov $task_ids  | $test_cov $test_ids      | $status     |\n"
        
    done <<< "$USER_STORIES"
fi

# Determine final verdict
if [[ $CRITICAL_COUNT -gt 0 ]]; then
    VERDICT="FAIL"
elif [[ $WARNING_COUNT -gt 0 ]]; then
    VERDICT="PASS WITH WARNINGS"
else
    VERDICT="PASS"
fi

# Generate report content
generate_recommendations() {
    if [[ "$VERDICT" == "PASS" ]]; then
        echo "✅ All artifacts are consistent. Ready for Gate 3 review."
    elif [[ "$VERDICT" == "PASS WITH WARNINGS" ]]; then
        echo "⚠️ Address the following before proceeding:"
        echo ""
        echo "1. Review warnings above and determine if they are blocking"
        echo "2. Add missing test coverage for critical user stories"
        echo "3. Ensure tasks reference their source requirements"
        echo "4. Re-run analysis after fixes"
    else
        echo "❌ Critical issues must be resolved:"
        echo ""
        echo "1. Address all critical issues listed above"
        echo "2. Ensure every user story has clear acceptance criteria"
        echo "3. Add design coverage in plan.md"
        echo "4. Add test cases and implementation tasks"
        echo "5. Re-run analysis after fixes"
    fi
}

generate_verdict_text() {
    if [[ "$VERDICT" == "PASS" ]]; then
        echo "✅ Artifacts are consistent and complete. Proceed to Gate 3."
    elif [[ "$VERDICT" == "PASS WITH WARNINGS" ]]; then
        echo "⚠️ Artifacts pass minimum requirements but have noted concerns."
    else
        echo "❌ Artifacts have critical gaps that must be addressed."
    fi
}

US_COUNT=$(echo "$USER_STORIES" | grep -c 'US-' 2>/dev/null || true)
US_COUNT=${US_COUNT:-0}
RECOMMENDATIONS=$(generate_recommendations)
VERDICT_TEXT=$(generate_verdict_text)
CRITICAL_SECTION=$(if [[ $CRITICAL_COUNT -eq 0 ]]; then echo "- None"; else echo -e "$CRITICAL_ISSUES"; fi)
WARNING_SECTION=$(if [[ $WARNING_COUNT -eq 0 ]]; then echo "- None"; else echo -e "$WARNING_ISSUES"; fi)
ORPHAN_TASKS_SECTION=$(if [[ -z "$ORPHAN_TASKS" ]]; then echo "- None detected"; else echo -e "$ORPHAN_TASKS"; fi)
ORPHAN_TESTS_SECTION=$(if [[ -z "$ORPHAN_TESTS" ]]; then echo "- None detected"; else echo -e "$ORPHAN_TESTS"; fi)
MEMORY_STATUS_SCRIPT="$SCRIPT_DIR/memory-status.sh"
if [[ -x "$MEMORY_STATUS_SCRIPT" ]]; then
    MEMORY_STATUS=$(bash "$MEMORY_STATUS_SCRIPT" "$FEATURE_ID" 2>/dev/null || true)
else
    MEMORY_STATUS="Memory status script not available"
fi
MEMORY_STATUS_SECTION=$(printf '%s\n' "$MEMORY_STATUS" | sed 's/^/- /')

# ── Artifact Dependency Graph (OpenSpec MVP — Evolution §12 item #1) ──

generate_artifact_graph() {
    local fdir="$1"
    local graph=""
    artifact_mark() {
        if [[ ! -f "$1" ]]; then echo "✗ Missing"
        elif grep -qE '\[FEATURE_NAME\]|\[NNN\]|<!-- INSTRUCTION -->' "$1" 2>/dev/null; then echo "⚠ Template"
        else echo "✓ Present"
        fi
    }
    graph+="constitution.md [$(artifact_mark "$MEMORY_DIR/constitution.md")]"$'\n'
    graph+="  └─► business-context.md [$(artifact_mark "$fdir/business-context.md")]"$'\n'
    graph+="       └─► spec.md [$(artifact_mark "$fdir/spec.md")]"$'\n'
    graph+="            ├─► clarifications.md [$(artifact_mark "$fdir/clarifications.md")]"$'\n'
    graph+="            └─► plan.md (design) [$(artifact_mark "$fdir/plan.md")]"$'\n'
    graph+="                 ├─► test-cases.md [$(artifact_mark "$fdir/test-cases.md")]"$'\n'
    graph+="                 └─► tasks.md [$(artifact_mark "$fdir/tasks.md")]"$'\n'
    graph+="                      └─► analysis-report.md [$(artifact_mark "$fdir/analysis-report.md")]"$'\n'
    graph+="                           └─► memory/"$'\n'
    graph+="                                ├─► decisions.md [$(artifact_mark "$MEMORY_DIR/decisions.md")]"$'\n'
    graph+="                                ├─► lessons.md [$(artifact_mark "$MEMORY_DIR/lessons.md")]"$'\n'
    graph+="                                └─► metrics-log.md [$(artifact_mark "$MEMORY_DIR/metrics-log.md")]"$'\n'
    graph+=$'\n'"Legend: ✓ Present  ✗ Missing  ⚠ Template"
    echo "$graph"
}

ARTIFACT_GRAPH=$(generate_artifact_graph "$FEATURE_DIR")

REPORT="# Consistency Analysis: $FEATURE_NAME

**Feature ID:** $FEATURE_ID
**Generated:** $TODAY
**Verdict:** $VERDICT

---

## Executive Summary

| Metric | Count |
|--------|-------|
| Critical Issues | $CRITICAL_COUNT |
| Warnings | $WARNING_COUNT |
| User Stories Analyzed | $US_COUNT |

---

## Traceability Matrix

| User Story | Plan Coverage | Task Coverage | Test Coverage | Status |
|------------|---------------|---------------|---------------|--------|
$(echo -e "$MATRIX")

---

## Issues Found

### Critical

$CRITICAL_SECTION

### Warnings

$WARNING_SECTION

---

## Orphan Detection

### Orphan Tasks (tasks without requirements)

$ORPHAN_TASKS_SECTION

### Orphan Tests (tests without acceptance criteria)

$ORPHAN_TESTS_SECTION

---

## Quality Metrics

| Metric | Value | Prompt Field |
|--------|-------|--------------|
| Generate-to-Review Ratio (G2R) | [fill] | generated units / review interventions |
| Intervention Rate | [fill] | human interventions / execution cycles |

Interpretation:
- G2R < 2:1 -> stabilization needed
- G2R 2:1 to < 4:1 -> acceptable baseline
- G2R >= 4:1 -> strong flow (verify with gate quality)

---

## Memory Lifecycle Status

$MEMORY_STATUS_SECTION

---

## Artifact Dependency Graph

\`\`\`
$ARTIFACT_GRAPH
\`\`\`

---

## Recommendations

$RECOMMENDATIONS

---

## Verdict: $VERDICT

$VERDICT_TEXT

---

*This report was auto-generated by generate-report.sh*"

# Output report
if $DRY_RUN; then
    echo "$REPORT"
else
    echo "$REPORT" > "$OUTPUT_FILE"
    log_success "Report generated: $OUTPUT_FILE"
fi

exit 0
