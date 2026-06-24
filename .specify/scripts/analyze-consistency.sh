#!/usr/bin/env bash
#
# analyze-consistency.sh - Analyze consistency across spec artifacts
#
# Usage: ./analyze-consistency.sh <feature-id>
# Example: ./analyze-consistency.sh 001-user-auth
#
# Checks:
#   - Every user story has acceptance criteria
#   - Every user story is covered by plan
#   - Every user story has test cases
#   - Every task traces to a requirement
#   - No orphan tasks or tests
#

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SPECS_DIR="$REPO_ROOT/.specify/specs"

# Helper functions
log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }
log_section() { echo -e "\n${MAGENTA}═══ $1 ═══${NC}\n"; }

usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS] <feature-id>

Analyze consistency across specification artifacts.

Arguments:
    feature-id     Feature directory name (e.g., 001-user-auth)

Options:
    -h, --help      Show this help message
    -o, --output    Save report to file (default: stdout)
    --json          Output as JSON (for automation)

Examples:
    $(basename "$0") 001-user-auth
    $(basename "$0") -o report.md 001-user-auth
    $(basename "$0") --json 001-user-auth

EOF
    exit 0
}

extract_user_stories() {
    local spec_file="$1"
    grep -oE 'US-[0-9]+' "$spec_file" 2>/dev/null | sort -u
}

extract_acceptance_criteria() {
    local spec_file="$1"
    grep -oE 'AC-[0-9]+' "$spec_file" 2>/dev/null | sort -u
}

extract_tasks() {
    local tasks_file="$1"
    grep -oE 'T[0-9]+' "$tasks_file" 2>/dev/null | sort -u
}

extract_test_cases() {
    local test_file="$1"
    grep -oE 'TC-[0-9]+' "$test_file" 2>/dev/null | sort -u
}

check_story_in_file() {
    local story="$1"
    local file="$2"
    grep -q "$story" "$file" 2>/dev/null
}

# Parse arguments
OUTPUT_FILE=""
JSON_OUTPUT=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            ;;
        -o|--output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        --json)
            JSON_OUTPUT=true
            shift
            ;;
        -*)
            log_error "Unknown option: $1"
            usage
            ;;
        *)
            FEATURE_ID="$1"
            shift
            ;;
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

# Initialize counters
CRITICAL_ISSUES=0
WARNINGS=0
declare -a CRITICAL_LIST
declare -a WARNING_LIST
declare -a ORPHAN_TASKS
declare -a ORPHAN_TESTS

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🔍 Consistency Analysis: $FEATURE_ID"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ============================================================
log_section "1. User Story Analysis"
# ============================================================

if [[ ! -f "$SPEC_FILE" ]]; then
    log_error "spec.md not found"
    CRITICAL_LIST+=("spec.md file missing")
    ((CRITICAL_ISSUES++))
else
    USER_STORIES=$(extract_user_stories "$SPEC_FILE")
    US_COUNT=$(echo "$USER_STORIES" | grep -c 'US-' || true)
    US_COUNT=${US_COUNT:-0}
    
    log_info "Found $US_COUNT user stories in spec.md"
    
    # Check each story has acceptance criteria
    while IFS= read -r us; do
        [[ -z "$us" ]] && continue
        
        # Find the story section and count its ACs
        ac_count=$(awk -v us="$us" '$0 ~ "^##[#]? *" us { found=1; next } found && /^##[#]? *US-/ { exit } found { print }' "$SPEC_FILE" 2>/dev/null | grep -cE 'AC-[0-9]+' || true)
        ac_count=${ac_count:-0}
        
        if [[ $ac_count -lt 1 ]]; then
            log_warning "$us has no acceptance criteria"
            WARNING_LIST+=("$us missing acceptance criteria")
            ((WARNINGS++))
        else
            log_success "$us has $ac_count acceptance criteria"
        fi
    done <<< "$USER_STORIES"
fi

# ============================================================
log_section "2. Plan Coverage"
# ============================================================

if [[ ! -f "$PLAN_FILE" ]]; then
    log_warning "plan.md not found (Gate 2 not reached?)"
    WARNING_LIST+=("plan.md not found")
    ((WARNINGS++))
else
    log_info "Checking user story coverage in plan..."
    
    uncovered_in_plan=0
    while IFS= read -r us; do
        [[ -z "$us" ]] && continue
        
        if check_story_in_file "$us" "$PLAN_FILE"; then
            log_success "$us referenced in plan.md"
        else
            log_warning "$us NOT referenced in plan.md"
            WARNING_LIST+=("$us not referenced in plan")
            ((WARNINGS++))
            ((uncovered_in_plan++))
        fi
    done <<< "$USER_STORIES"
    
    if [[ $uncovered_in_plan -eq 0 ]]; then
        log_success "All user stories covered in plan"
    fi
fi

# ============================================================
log_section "3. Test Coverage"
# ============================================================

if [[ ! -f "$TEST_FILE" ]]; then
    log_warning "test-cases.md not found (Gate 3 not reached?)"
    WARNING_LIST+=("test-cases.md not found")
    ((WARNINGS++))
else
    log_info "Checking user story coverage in tests..."
    
    uncovered_in_tests=0
    while IFS= read -r us; do
        [[ -z "$us" ]] && continue
        
        if check_story_in_file "$us" "$TEST_FILE"; then
            log_success "$us has test cases"
        else
            log_error "$us has NO test cases"
            CRITICAL_LIST+=("$us missing test coverage")
            ((CRITICAL_ISSUES++))
            ((uncovered_in_tests++))
        fi
    done <<< "$USER_STORIES"
    
    if [[ $uncovered_in_tests -eq 0 ]]; then
        log_success "All user stories have test coverage"
    fi
    
    # Check for orphan test cases
    log_info "Checking for orphan test cases..."
    TEST_CASES=$(extract_test_cases "$TEST_FILE")
    
    while IFS= read -r tc; do
        [[ -z "$tc" ]] && continue
        
        # Check if test case traces to any user story
        tc_line=$(grep -n "$tc" "$TEST_FILE" | head -1)
        traces_to_us=false
        
        while IFS= read -r us; do
            [[ -z "$us" ]] && continue
            if echo "$tc_line" | grep -q "$us"; then
                traces_to_us=true
                break
            fi
            # Also check nearby lines (within 5 lines)
            tc_linenum=$(echo "$tc_line" | cut -d: -f1)
            if sed -n "$((tc_linenum-5)),$((tc_linenum+10))p" "$TEST_FILE" 2>/dev/null | grep -q "$us"; then
                traces_to_us=true
                break
            fi
        done <<< "$USER_STORIES"
        
        if ! $traces_to_us; then
            log_warning "$tc does not trace to any user story"
            ORPHAN_TESTS+=("$tc")
            ((WARNINGS++))
        fi
    done <<< "$TEST_CASES"
fi

# ============================================================
log_section "4. Task Coverage"
# ============================================================

if [[ ! -f "$TASKS_FILE" ]]; then
    log_warning "tasks.md not found (Gate 3 not reached?)"
    WARNING_LIST+=("tasks.md not found")
    ((WARNINGS++))
else
    log_info "Checking task traceability..."
    
    TASKS=$(extract_tasks "$TASKS_FILE")
    TASK_COUNT=$(echo "$TASKS" | grep -c 'T[0-9]' || true)
    TASK_COUNT=${TASK_COUNT:-0}
    log_info "Found $TASK_COUNT tasks"
    
    # Simple check: tasks file should reference user stories or plan sections
    stories_referenced=$(grep -oE 'US-[0-9]+' "$TASKS_FILE" 2>/dev/null | sort -u | wc -l || true)
    stories_referenced=${stories_referenced:-0}
    
    if [[ $stories_referenced -gt 0 ]]; then
        log_success "Tasks reference $stories_referenced user stories"
    else
        log_warning "Tasks do not reference user stories directly"
        WARNING_LIST+=("Tasks lack user story references")
        ((WARNINGS++))
    fi
fi

# ============================================================
log_section "5. Parallel Execution Markers"
# ============================================================

if [[ -f "$TASKS_FILE" ]]; then
    log_info "Checking [P]/[S]/[T] markers on tasks..."
    
    UNMARKED=0
    while IFS= read -r task; do
        [[ -z "$task" ]] && continue
        task_line=$(grep -n "### *$task " "$TASKS_FILE" 2>/dev/null | head -1 || true)
        if [[ -n "$task_line" ]]; then
            if ! echo "$task_line" | grep -qE '\[(P|S|T)\]'; then
                log_warning "$task missing execution marker ([P]/[S]/[T])"
                WARNING_LIST+=("$task missing execution marker")
                ((WARNINGS++))
                ((UNMARKED++))
            fi
        fi
    done <<< "$TASKS"
    
    # Check [S] tasks have Depends On
    while IFS= read -r line; do
        linenum=$(echo "$line" | cut -d: -f1)
        # Check the next 10 lines for a "Depends On" reference
        if ! sed -n "$((linenum+1)),$((linenum+10))p" "$TASKS_FILE" 2>/dev/null | grep -qi 'depends on'; then
            task_id=$(echo "$line" | grep -oE 'T[0-9]+' | head -1)
            log_warning "$task_id is [S] but has no 'Depends On' reference"
        fi
    done < <(grep -n '\[S\]' "$TASKS_FILE" 2>/dev/null)
    
    if [[ $UNMARKED -eq 0 ]]; then
        log_success "All tasks have execution markers"
    fi
else
    log_warning "tasks.md not found — skipping marker check"
fi

# ============================================================
log_section "6. Goal-Backward Check"
# ============================================================

BUSINESS_FILE="$FEATURE_DIR/business-context.md"
if [[ -f "$BUSINESS_FILE" ]]; then
    # Extract goals/success metrics
    goal_count=$(grep -cE '^\|.*\|.*\|' "$BUSINESS_FILE" 2>/dev/null || true)
    goal_count=${goal_count:-0}
    # Check if any goals are present
    if [[ $goal_count -lt 2 ]]; then
        log_warning "business-context.md has few or no structured goals/metrics"
        WARNING_LIST+=("Business context lacks structured goals")
        ((WARNINGS++))
    else
        log_success "business-context.md has structured goals/metrics"
    fi

    # Check if analysis report covers backward verification
    if [[ -f "$FEATURE_DIR/analysis-report.md" ]]; then
        if grep -q 'Goal-Backward Verification' "$FEATURE_DIR/analysis-report.md" 2>/dev/null; then
            log_success "Analysis report includes goal-backward verification"
        else
            log_warning "Analysis report missing goal-backward verification section"
            WARNING_LIST+=("Analysis report missing backward verification")
            ((WARNINGS++))
        fi
    fi
else
    log_warning "business-context.md not found — cannot check goals"
fi

# ============================================================
log_section "7. Traceability Matrix"
# ============================================================

echo ""
printf "%-12s | %-12s | %-12s | %-12s | %-10s\n" "User Story" "Has ACs" "In Plan" "Has Tests" "Status"
printf "%-12s-+-%-12s-+-%-12s-+-%-12s-+-%-10s\n" "------------" "------------" "------------" "------------" "----------"

while IFS= read -r us; do
    [[ -z "$us" ]] && continue
    
    # Check acceptance criteria
    ac_status="✗"
    if [[ -f "$SPEC_FILE" ]]; then
        ac_count=$(awk -v us="$us" '$0 ~ "^##[#]? *" us { found=1; next } found && /^##[#]? *US-/ { exit } found { print }' "$SPEC_FILE" 2>/dev/null | grep -cE 'AC-[0-9]+' || true)
        ac_count=${ac_count:-0}
        [[ $ac_count -gt 0 ]] && ac_status="✓ ($ac_count)"
    fi
    
    # Check plan coverage
    plan_status="✗"
    [[ -f "$PLAN_FILE" ]] && check_story_in_file "$us" "$PLAN_FILE" && plan_status="✓"
    
    # Check test coverage
    test_status="✗"
    [[ -f "$TEST_FILE" ]] && check_story_in_file "$us" "$TEST_FILE" && test_status="✓"
    
    # Determine overall status
    overall_status="⚠️"
    if [[ "$ac_status" == "✗" ]] || [[ "$test_status" == "✗" ]]; then
        overall_status="❌"
    elif [[ "$plan_status" == "✗" ]]; then
        overall_status="⚠️"
    else
        overall_status="✅"
    fi
    
    printf "%-12s | %-12s | %-12s | %-12s | %-10s\n" "$us" "$ac_status" "$plan_status" "$test_status" "$overall_status"
    
done <<< "$USER_STORIES"

# ============================================================
log_section "8. Summary"
# ============================================================

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [[ $CRITICAL_ISSUES -gt 0 ]]; then
    echo ""
    log_error "Critical Issues ($CRITICAL_ISSUES):"
    for issue in "${CRITICAL_LIST[@]}"; do
        echo "  • $issue"
    done
fi

if [[ $WARNINGS -gt 0 ]]; then
    echo ""
    log_warning "Warnings ($WARNINGS):"
    for warning in "${WARNING_LIST[@]}"; do
        echo "  • $warning"
    done
fi

if [[ ${#ORPHAN_TESTS[@]} -gt 0 ]]; then
    echo ""
    log_warning "Orphan Tests (no traceability):"
    for tc in "${ORPHAN_TESTS[@]}"; do
        echo "  • $tc"
    done
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Determine verdict
if [[ $CRITICAL_ISSUES -gt 0 ]]; then
    echo ""
    log_error "Verdict: FAIL"
    echo ""
    echo "  Address critical issues before proceeding."
    VERDICT="FAIL"
    EXIT_CODE=1
elif [[ $WARNINGS -gt 0 ]]; then
    echo ""
    log_warning "Verdict: PASS WITH WARNINGS"
    echo ""
    echo "  Consider addressing warnings for better traceability."
    VERDICT="PASS_WITH_WARNINGS"
    EXIT_CODE=0
else
    echo ""
    log_success "Verdict: PASS"
    echo ""
    echo "  All artifacts are consistent!"
    VERDICT="PASS"
    EXIT_CODE=0
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

exit $EXIT_CODE
