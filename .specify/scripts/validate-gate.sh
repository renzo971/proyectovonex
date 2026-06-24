#!/usr/bin/env bash
#
# validate-gate.sh - Validate gate criteria for a feature
#
# Usage: ./validate-gate.sh <feature-id> <gate-number>
# Example: ./validate-gate.sh 001-user-auth 1
#
# Gates:
#   1 - Three Amigos Review (spec complete)
#   2 - Technical Alignment (design complete)
#   3 - Implementation Gate (tests & tasks ready)
#   4 - Ship Gate (everything complete)
#

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SPECS_DIR="$REPO_ROOT/.specify/specs"
MEMORY_DIR="$REPO_ROOT/.specify/memory"
CONFIG_FILE="$REPO_ROOT/.specify/config.json"
CHECKPOINTS_DIR="$REPO_ROOT/.specify/checkpoints"

# Helper functions
log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }
log_check() { echo -e "${CYAN}   ↳ $1${NC}"; }

usage() {
    cat << EOF
Usage: $(basename "$0") <feature-id> <gate-number>

Validate gate criteria for a feature before proceeding.

Arguments:
    feature-id     Feature directory name (e.g., 001-user-auth)
    gate-number    Gate to validate (1, 2, 3, or 4)

Gates:
    1 - Three Amigos Review
        Validates: business-context.md, spec.md, clarifications.md
    
    2 - Technical Alignment
        Validates: plan.md, contracts (openapi.yaml, asyncapi.yaml)
        Cross-ref: every US-XXX in spec.md → must appear in plan.md
    
    3 - Implementation Gate
        Validates: test-cases.md, tasks.md, analysis-report.md
        Cross-ref: every TC-XXX in test-cases.md → must appear in a test file
    
    4 - Ship Gate
        Validates: All files, ship-checklist.md, test coverage

Options:
    -h, --help      Show this help message
    -v, --verbose   Show detailed checks

Examples:
    $(basename "$0") 001-user-auth 1
    $(basename "$0") -v 001-user-auth 4

EOF
    exit 0
}

check_file_exists() {
    local file="$1"
    local description="$2"
    
    if [[ -f "$file" ]]; then
        log_success "$description exists"
        return 0
    else
        log_error "$description MISSING"
        return 1
    fi
}

check_file_not_template() {
    local file="$1"
    local description="$2"
    
    if [[ ! -f "$file" ]]; then
        return 1
    fi
    
    # Check for template markers
    if grep -q '\[FEATURE_NAME\]\|\[NNN\]\|\[DATE\]\|<!-- INSTRUCTION -->' "$file" 2>/dev/null; then
        log_warning "$description contains template placeholders"
        return 1
    fi
    
    # Reject files where the Status field still shows multiple choices (template)
    if grep -qE '^\*\*Status:\*\*.*\|.*\|' "$file" 2>/dev/null; then
        log_warning "$description is still a template (Status field not filled)"
        return 1
    fi

    # Reject files with typical template placeholders like [Story Title]
    if grep -qE '\[Story [Tt]itle\]|\[Describe |\[Add ' "$file" 2>/dev/null; then
        log_warning "$description contains unfilled template placeholders"
        return 1
    fi
    
    # Check for minimum content (more than just headers)
    local content_lines
    content_lines=$(grep -v '^#\|^-\|^$\|^\s*$' "$file" | wc -l)
    if [[ $content_lines -lt 5 ]]; then
        log_warning "$description appears to be mostly empty"
        return 1
    fi
    
    return 0
}

check_acceptance_criteria() {
    local spec_file="$1"
    
    if [[ ! -f "$spec_file" ]]; then
        return 1
    fi
    
    # Count acceptance criteria
    local ac_count
    ac_count=$(grep -cE '^\s*-\s*\[.\]\s*\*\*AC-[0-9]+\*\*|AC-[0-9]+:' "$spec_file" 2>/dev/null || true)
    ac_count=${ac_count:-0}
    
    if [[ $ac_count -lt 1 ]]; then
        log_error "No acceptance criteria found in spec.md"
        return 1
    fi
    
    log_check "Found $ac_count acceptance criteria"
    return 0
}

check_user_stories() {
    local spec_file="$1"
    
    if [[ ! -f "$spec_file" ]]; then
        return 1
    fi
    
    # Count user stories
    local us_count
    us_count=$(grep -cE '^#{2,4}\s+US-[0-9]+' "$spec_file" 2>/dev/null || true)
    us_count=${us_count:-0}
    
    if [[ $us_count -lt 1 ]]; then
        log_error "No user stories found in spec.md"
        return 1
    fi
    
    log_check "Found $us_count user stories"
    return 0
}

check_openapi_valid() {
    local openapi_file="$1"
    
    if [[ ! -f "$openapi_file" ]]; then
        log_warning "No OpenAPI contract (optional)"
        return 0
    fi
    
    # Check if redocly-cli is available
    if command -v npx &> /dev/null; then
        if npx @redocly/cli lint "$openapi_file" --format=stylish 2>/dev/null | grep -q "error"; then
            log_error "OpenAPI contract has validation errors"
            return 1
        else
            log_success "OpenAPI contract is valid"
            return 0
        fi
    else
        log_warning "Cannot validate OpenAPI (npx not available)"
        return 0
    fi
}

check_asyncapi_valid() {
    local asyncapi_file="$1"
    
    if [[ ! -f "$asyncapi_file" ]]; then
        log_warning "No AsyncAPI contract (optional)"
        return 0
    fi
    
    # Check if asyncapi-cli is available
    if command -v npx &> /dev/null; then
        if npx @asyncapi/cli validate "$asyncapi_file" 2>/dev/null | grep -qiE "error|invalid"; then
            log_error "AsyncAPI contract has validation errors"
            return 1
        else
            log_success "AsyncAPI contract is valid"
            return 0
        fi
    else
        log_warning "Cannot validate AsyncAPI (npx not available)"
        return 0
    fi
}

check_test_coverage() {
    local test_cases_file="$1"
    local spec_file="$2"
    
    if [[ ! -f "$test_cases_file" ]] || [[ ! -f "$spec_file" ]]; then
        return 1
    fi
    
    # Get user stories from spec
    local us_list
    us_list=$(grep -oE 'US-[0-9]+' "$spec_file" | sort -u)
    
    # Check test cases reference user stories
    local coverage_count=0
    local missing_us=""
    
    while IFS= read -r us; do
        if grep -q "$us" "$test_cases_file" 2>/dev/null; then
            ((coverage_count++))
        else
            missing_us="$missing_us $us"
        fi
    done <<< "$us_list"
    
    local total_us
    total_us=$(echo "$us_list" | wc -l | tr -d ' ')
    
    if [[ -n "$missing_us" ]]; then
        log_warning "Missing test coverage for:$missing_us"
    fi
    
    log_check "Test coverage: $coverage_count/$total_us user stories"
    
    if [[ $coverage_count -lt $total_us ]]; then
        return 1
    fi
    return 0
}

check_tasks_coverage() {
    local tasks_file="$1"
    local plan_file="$2"
    
    if [[ ! -f "$tasks_file" ]]; then
        return 1
    fi
    
    # Count tasks
    local task_count
    task_count=$(grep -cE '^\s*-\s*\[.\]\s*T[0-9]+|^### T[0-9]+' "$tasks_file" 2>/dev/null || true)
    task_count=${task_count:-0}
    
    if [[ $task_count -lt 1 ]]; then
        log_error "No tasks found in tasks.md"
        return 1
    fi
    
    log_check "Found $task_count tasks"
    return 0
}

# ── Cross-reference checks (Wave 1) ──────────────────────────────────

check_us_in_plan() {
    local spec_file="$1"
    local plan_file="$2"

    if [[ ! -f "$spec_file" ]] || [[ ! -f "$plan_file" ]]; then
        return 1
    fi

    local us_ids
    us_ids=$(grep -oE 'US-[0-9]{3}' "$spec_file" | sort -u)

    if [[ -z "$us_ids" ]]; then
        log_warning "No US-XXX IDs found in spec.md — nothing to cross-check"
        return 0
    fi

    local missing=""
    local found=0
    local total=0

    while IFS= read -r us_id; do
        [[ -z "$us_id" ]] && continue
        ((total++))
        if grep -q "$us_id" "$plan_file" 2>/dev/null; then
            ((found++))
        else
            missing="$missing $us_id"
        fi
    done <<< "$us_ids"

    if [[ -n "$missing" ]]; then
        log_error "User stories in spec.md NOT referenced in plan.md:$missing"
    fi

    log_check "Spec → Plan traceability: $found/$total user stories"

    if [[ $found -lt $total ]]; then
        return 1
    fi
    return 0
}

check_tc_has_test_file() {
    local test_cases_file="$1"
    local feature_dir="$2"

    if [[ ! -f "$test_cases_file" ]]; then
        return 1
    fi

    local tc_ids
    tc_ids=$(grep -oE 'TC-[0-9]{3}' "$test_cases_file" | sort -u)

    if [[ -z "$tc_ids" ]]; then
        log_warning "No TC-XXX IDs found in test-cases.md — nothing to cross-check"
        return 0
    fi

    # Look for test files under the repo's test directories
    # Read from .specify/config.json if available, otherwise use defaults
    local test_dirs=()
    if [[ -f "$CONFIG_FILE" ]] && command -v python3 &>/dev/null; then
        while IFS= read -r dir; do
            [[ -n "$dir" ]] && test_dirs+=("$REPO_ROOT/$dir")
        done < <(python3 -c "import json; [print(d) for d in json.load(open('$CONFIG_FILE',encoding='utf-8-sig')).get('testDirectories',[])]" 2>/dev/null)
    fi
    # Fallback to defaults if config not available or empty
    if [[ ${#test_dirs[@]} -eq 0 ]]; then
        test_dirs=("$REPO_ROOT/tests" "$REPO_ROOT/test" "$REPO_ROOT/src/test" "$REPO_ROOT/__tests__")
    fi

    local has_test_dir=false
    for td in "${test_dirs[@]}"; do
        if [[ -d "$td" ]]; then
            has_test_dir=true
            break
        fi
    done

    if ! $has_test_dir; then
        log_warning "No test directories found — skipping TC→file check (tests not yet written)"
        return 0
    fi

    local missing=""
    local found=0
    local total=0

    # Collect only existing test directories
    local existing_dirs=()
    for td in "${test_dirs[@]}"; do
        [[ -d "$td" ]] && existing_dirs+=("$td")
    done

    while IFS= read -r tc_id; do
        [[ -z "$tc_id" ]] && continue
        ((total++))
        # Search for the TC-XXX reference in any test file
        if grep -r -l "$tc_id" "${existing_dirs[@]}" 2>/dev/null | head -1 | grep -q .; then
            ((found++))
        else
            missing="$missing $tc_id"
        fi
    done <<< "$tc_ids"

    if [[ -n "$missing" ]]; then
        log_warning "Test cases NOT referenced in any test file:$missing"
    fi

    log_check "Test case → test file traceability: $found/$total"

    if [[ $found -lt $total ]]; then
        return 1
    fi
    return 0
}

run_extension_hooks() {
    local hook_name="$1"
    shift
    local extensions_dir="$REPO_ROOT/.sdd-extensions"

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
            hook_script=$(python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('hooks',{}).get('$hook_name',''))" < "$manifest" 2>/dev/null)
        fi

        if [[ -n "$hook_script" && -f "$ext_dir/$hook_script" ]]; then
            log_info "Running extension hook: $hook_name from $(basename "$ext_dir")"
            bash "$ext_dir/$hook_script" "$@" || log_warning "Extension hook failed (non-fatal): $ext_dir/$hook_script"
        fi
    done
}

check_analysis_status() {
    local analysis_file="$1"
    
    if [[ ! -f "$analysis_file" ]]; then
        return 1
    fi
    
    # Check verdict
    if grep -qiE 'Verdict:\s*PASS\b' "$analysis_file"; then
        log_success "Analysis verdict: PASS"
        return 0
    elif grep -qiE 'Verdict:\s*PASS WITH WARNINGS' "$analysis_file"; then
        log_warning "Analysis verdict: PASS WITH WARNINGS"
        return 0
    else
        log_error "Analysis verdict: FAIL or not determined"
        return 1
    fi
}

# ── NEEDS CLARIFICATION marker check (Wave 6) ────────────────────────

check_needs_clarification_markers() {
    local feature_dir="$1"
    local max_per_file="${2:-3}"
    local errors=0
    local total_markers=0

    log_info "Checking [NEEDS CLARIFICATION] markers (max $max_per_file per artifact):"

    for md_file in "$feature_dir"/*.md; do
        [[ -f "$md_file" ]] || continue
        local filename
        filename=$(basename "$md_file")
        local count
        count=$(grep -c '\[NEEDS CLARIFICATION:' "$md_file" 2>/dev/null || true)
        count=${count:-0}
        total_markers=$((total_markers + count))

        if [[ $count -gt $max_per_file ]]; then
            log_error "$filename has $count [NEEDS CLARIFICATION] markers (max $max_per_file)"
            ((errors++))
        elif [[ $count -gt 0 ]]; then
            log_warning "$filename has $count [NEEDS CLARIFICATION] marker(s)"
        fi
    done

    if [[ $total_markers -eq 0 ]]; then
        log_success "No unresolved [NEEDS CLARIFICATION] markers"
    else
        log_check "Total markers across all artifacts: $total_markers"
    fi

    return $errors
}

check_ship_checklist() {
    local checklist_file="$1"
    
    if [[ ! -f "$checklist_file" ]]; then
        return 1
    fi
    
    # Count completed vs total checkboxes
    local total
    local completed
    total=$(grep -cE '^\s*-\s*\[.\]' "$checklist_file" 2>/dev/null || true)
    total=${total:-0}
    completed=$(grep -cE '^\s*-\s*\[[xX]\]' "$checklist_file" 2>/dev/null || true)
    completed=${completed:-0}
    
    log_check "Checklist: $completed/$total items complete"
    
    if [[ $completed -lt $total ]]; then
        return 1
    fi
    return 0
}

# ── Goal-Backward Verification (Wave 8) ──────────────────────────────

check_goal_backward() {
    local feature_dir="$1"
    local analysis_file="$feature_dir/analysis-report.md"
    local business_context="$feature_dir/business-context.md"

    if [[ ! -f "$analysis_file" ]] || [[ ! -f "$business_context" ]]; then
        log_warning "Cannot verify goal-backward: missing analysis-report.md or business-context.md"
        return 0  # Non-blocking if files missing
    fi

    # Check that Section 5 (Goal-Backward Verification) exists in the analysis report
    if ! grep -q 'Goal-Backward Verification' "$analysis_file" 2>/dev/null; then
        log_error "Analysis report missing 'Goal-Backward Verification' section"
        log_check "Re-run Analysis agent to generate backward verification"
        return 1
    fi

    # Check backward verification verdict
    if grep -qiE 'Backward Verification Verdict.*GOAL DRIFT' "$analysis_file" 2>/dev/null; then
        log_error "Goal-backward verification detected GOAL DRIFT"
        return 1
    fi

    if grep -qiE 'Backward Verification Verdict.*PARTIAL' "$analysis_file" 2>/dev/null; then
        log_warning "Goal-backward verification: PARTIAL coverage (review gaps)"
        return 0  # Warning but not blocking
    fi

    log_success "Goal-backward verification: ALL GOALS ACHIEVED"
    return 0
}

# ── Stuck detection (Wave 8) ─────────────────────────────────────────

STUCK_DIR="$CHECKPOINTS_DIR/stuck-history"

check_stuck_detection() {
    local feature_dir="$1"
    local gate_num="$2"
    local feature_id
    feature_id=$(basename "$feature_dir")

    mkdir -p "$STUCK_DIR"
    local history_file="$STUCK_DIR/${feature_id}-gate${gate_num}.checksums"

    # Compute current checksums of key artifacts
    local current_checksums=""
    for md_file in "$feature_dir"/*.md; do
        [[ -f "$md_file" ]] || continue
        local filename
        filename=$(basename "$md_file")
        local checksum
        if command -v md5sum &>/dev/null; then
            checksum=$(md5sum "$md_file" | cut -d' ' -f1)
        elif command -v md5 &>/dev/null; then
            checksum=$(md5 -q "$md_file")
        else
            checksum=$(cksum "$md_file" | cut -d' ' -f1)
        fi
        current_checksums="${current_checksums}${filename}:${checksum}\n"
    done

    # Compare to previous run
    if [[ -f "$history_file" ]]; then
        local previous
        previous=$(cat "$history_file")
        local current_expanded
        current_expanded=$(printf '%b' "$current_checksums")
        if [[ "$current_expanded" == "$previous" ]]; then
            log_warning "STUCK DETECTED: Artifact checksums unchanged since last gate validation"
            log_check "Agents may be producing the same output. Review artifacts manually."
            # Don't fail the gate — this is a warning, not a blocker
        fi
    fi

    # Save current checksums for next comparison
    printf '%b' "$current_checksums" > "$history_file"
    return 0
}

# ── Autonomy provenance checks (Wave 11 Phase J) ─────────────────────

get_execution_mode() {
    local feature_dir="$1"
    local meta_file="$feature_dir/.feature-meta.json"
    if [[ -f "$meta_file" ]] && command -v python3 &>/dev/null; then
        python3 -c "import json; print(json.load(open('$meta_file',encoding='utf-8-sig')).get('executionMode','standard'))" 2>/dev/null || echo "standard"
    else
        echo "standard"
    fi
}

get_meta_field() {
    local feature_dir="$1"
    local field="$2"
    local default_val="${3:-}"
    local meta_file="$feature_dir/.feature-meta.json"
    if [[ -f "$meta_file" ]] && command -v python3 &>/dev/null; then
        python3 -c "import json; print(json.load(open('$meta_file',encoding='utf-8-sig')).get('$field','$default_val'))" 2>/dev/null || echo "$default_val"
    else
        echo "$default_val"
    fi
}

check_autonomy_provenance() {
    local feature_dir="$1"
    local gate_num="$2"
    local exec_mode
    exec_mode=$(get_execution_mode "$feature_dir")

    # Only run autonomy checks for non-standard modes
    if [[ "$exec_mode" == "standard" ]]; then
        return 0
    fi

    local errors=0
    local todo_file="$feature_dir/todo.md"

    echo ""
    log_info "🤖 Autonomy Provenance Checks (mode: $exec_mode)"
    echo ""

    # Check 1: todo.md must exist with cycle evidence
    if [[ ! -f "$todo_file" ]]; then
        log_error "AUTONOMY: todo.md MISSING — autonomous cycles must persist evidence in todo.md"
        log_check "Next step: Create todo.md with cycle evidence blocks before running the gate"
        ((errors++))
    else
        # Check for evidence blocks
        local evidence_count
        evidence_count=$(grep -c '## Cycle [0-9]' "$todo_file" 2>/dev/null || true)
        evidence_count=${evidence_count:-0}
        if [[ $evidence_count -lt 1 ]]; then
            log_error "AUTONOMY: No cycle evidence blocks found in todo.md"
            log_check "Next step: Each autonomous cycle must write a '## Cycle N' evidence section"
            ((errors++))
        else
            log_success "Found $evidence_count cycle evidence block(s) in todo.md"
        fi

        # Check for rationale in the latest cycle
        if ! grep -qiE '(rationale|reason)\*?\*?:' "$todo_file" 2>/dev/null; then
            log_error "AUTONOMY: No rationale found in cycle evidence"
            log_check "Next step: Each cycle must include a rationale explaining what was done and why"
            ((errors++))
        else
            log_success "Rationale found in cycle evidence"
        fi

        # Check for confidence score
        if ! grep -qiE 'confidence.*score.*[1-5]|confidence.*[1-5]/5' "$todo_file" 2>/dev/null; then
            log_error "AUTONOMY: No confidence score found in cycle evidence"
            log_check "Next step: Each cycle must record a confidence score (1-5)"
            ((errors++))
        else
            log_success "Confidence score recorded"
        fi

        # Check for risk classification
        if ! grep -qiE 'risk.*classification.*:.*\b(low|medium|high|critical)\b' "$todo_file" 2>/dev/null; then
            log_error "AUTONOMY: No risk classification found in cycle evidence"
            log_check "Next step: Each cycle must record risk as low/medium/high/critical"
            ((errors++))
        else
            log_success "Risk classification recorded"
        fi

        # Check for traceability references
        if ! grep -qiE 'traceability|US-[0-9]+|TC-[0-9]+|T[0-9]+' "$todo_file" 2>/dev/null; then
            log_warning "AUTONOMY: No traceability references found in cycle evidence"
            log_check "Consider adding references to spec.md, tasks.md, or test-cases.md entries"
        else
            log_success "Traceability references found"
        fi

        # Check for touched artifacts list
        if ! grep -qiE 'touched.*artifact|files.*modified|files.*created' "$todo_file" 2>/dev/null; then
            log_error "AUTONOMY: No touched-artifact list in cycle evidence"
            log_check "Next step: Each cycle must list files created/modified"
            ((errors++))
        else
            log_success "Touched-artifact list found"
        fi

        # Check for context-reset markers between cycles (if multiple cycles)
        if [[ $evidence_count -gt 1 ]]; then
            local reset_count
            reset_count=$(grep -ciE 'context.reset|fresh.session|new.cycle' "$todo_file" 2>/dev/null || true)
            reset_count=${reset_count:-0}
            local expected_resets=$((evidence_count - 1))
            if [[ $reset_count -lt $expected_resets ]]; then
                log_error "AUTONOMY: Missing context-reset markers between cycles ($reset_count found, $expected_resets expected)"
                log_check "Next step: Each cycle must start from a fresh context. Mark resets between cycles"
                ((errors++))
            else
                log_success "Context-reset markers present between cycles"
            fi
        fi
    fi

    # Check: lessons.md updated
    if [[ -f "$feature_dir/lessons.md" ]]; then
        local lesson_content
        lesson_content=$(grep -v '^#\|^-\|^$\|^\s*$' "$feature_dir/lessons.md" | wc -l)
        if [[ $lesson_content -lt 1 ]]; then
            log_warning "AUTONOMY: lessons.md appears empty — autonomous cycles should capture learnings"
        else
            log_success "lessons.md has content"
        fi
    fi

    # Check: autonomy budget not exceeded
    local budget
    budget=$(get_meta_field "$feature_dir" "autonomyBudget" "0")
    if [[ -f "$todo_file" ]]; then
        local cycles_consumed
        cycles_consumed=$(grep -c '## Cycle [0-9]' "$todo_file" 2>/dev/null || true)
        cycles_consumed=${cycles_consumed:-0}
        if [[ $cycles_consumed -gt $budget && $budget -gt 0 ]]; then
            log_error "AUTONOMY: Budget exceeded ($cycles_consumed cycles consumed, budget: $budget)"
            log_check "Next step: Switch to standard mode or request budget increase from operator"
            ((errors++))
        elif [[ $budget -gt 0 ]]; then
            log_success "Budget: $cycles_consumed/$budget cycles consumed"
        fi
    fi

    if [[ $errors -gt 0 ]]; then
        echo ""
        log_error "AUTONOMY PROVENANCE FAILED: $errors issue(s) detected"
        log_check "💡 Recommended action: Switch executionMode to 'standard' in .feature-meta.json"
        log_check "   and resolve the issues manually before re-enabling autonomous mode."
        echo ""
    else
        echo ""
        log_success "AUTONOMY PROVENANCE: All checks passed"
        echo ""
    fi

    return $errors
}

validate_gate_1() {
    local feature_dir="$1"
    local errors=0
    local is_delta=false
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  🚪 Gate 1: Three Amigos Review"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Delta-spec detection: if delta-spec.md exists, use delta validation path
    if [ -f "$feature_dir/delta-spec.md" ]; then
        is_delta=true
        echo "Checking: Delta specification completeness"
        echo ""
        log_info "Delta spec detected — using reduced-ceremony validation"
        
        check_file_exists "$feature_dir/delta-spec.md" "delta-spec.md" || ((errors++))
        check_file_not_template "$feature_dir/delta-spec.md" "delta-spec.md" || ((errors++))
        
        # Validate required fields based on change_type
        if grep -qi "MODIFIED\|RENAMED" "$feature_dir/delta-spec.md" 2>/dev/null; then
            log_info "Change type MODIFIED/RENAMED — checking 'before' field:"
            if ! grep -q "## Before State" "$feature_dir/delta-spec.md" || \
               grep -A2 "## Before State" "$feature_dir/delta-spec.md" | grep -q '\[Describe'; then
                log_error "'Before State' section is required and must be filled for MODIFIED/RENAMED changes"
                ((errors++))
            else
                log_success "'Before State' section is present and filled"
            fi
        fi
        
        if grep -qi "REMOVED" "$feature_dir/delta-spec.md" 2>/dev/null; then
            log_info "Change type REMOVED — checking 'justification' field:"
            if ! grep -q "## Justification" "$feature_dir/delta-spec.md" || \
               grep -A2 "## Justification" "$feature_dir/delta-spec.md" | grep -q '\[Rationale'; then
                log_error "'Justification' section is required and must be filled for REMOVED changes"
                ((errors++))
            else
                log_success "'Justification' section is present and filled"
            fi
        fi
        
        # Impact assessment is always required
        log_info "Impact assessment:"
        if ! grep -q "## Impact Assessment" "$feature_dir/delta-spec.md"; then
            log_error "'Impact Assessment' section is missing"
            ((errors++))
        else
            log_success "'Impact Assessment' section is present"
        fi
        
        echo ""
        return $errors
    fi
    
    echo "Checking: Do we all share the same understanding?"
    echo ""
    
    log_info "Required artifacts:"
    
    check_file_exists "$feature_dir/business-context.md" "business-context.md" || ((errors++))
    check_file_not_template "$feature_dir/business-context.md" "business-context.md" || ((errors++))
    
    check_file_exists "$feature_dir/spec.md" "spec.md" || ((errors++))
    check_file_not_template "$feature_dir/spec.md" "spec.md" || ((errors++))
    check_user_stories "$feature_dir/spec.md" || ((errors++))
    check_acceptance_criteria "$feature_dir/spec.md" || ((errors++))
    
    check_file_exists "$feature_dir/clarifications.md" "clarifications.md" || ((errors++))

    # Wave 6: Check for excessive unresolved markers
    log_info "Clarification markers:"
    check_needs_clarification_markers "$feature_dir" || ((errors++))
    
    echo ""
    return $errors
}

validate_gate_2() {
    local feature_dir="$1"
    local errors=0
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  🚪 Gate 2: Technical Alignment Review"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Checking: Does the design fulfill the spec?"
    echo ""
    
    log_info "Required artifacts:"
    
    check_file_exists "$feature_dir/plan.md" "plan.md" || ((errors++))
    check_file_not_template "$feature_dir/plan.md" "plan.md" || ((errors++))

    # Cross-reference: every US in spec must appear in plan
    log_info "Cross-reference checks:"
    check_us_in_plan "$feature_dir/spec.md" "$feature_dir/plan.md" || ((errors++))
    
    # Contracts are optional but should be valid if present
    log_info "Contract validation (optional):"
    check_openapi_valid "$feature_dir/contracts/openapi.yaml"
    check_asyncapi_valid "$feature_dir/contracts/asyncapi.yaml"

    # Wave 23 §C.4: Hidden Requirement Candidates section must be present in clarifications.md
    log_info "Hidden requirement scan:"
    local clar_file="$feature_dir/clarifications.md"
    if [[ -f "$clar_file" ]]; then
        if grep -qi '## Hidden Requirement Candidates' "$clar_file" 2>/dev/null; then
            log_success "Hidden Requirement Candidates section present in clarifications.md"
        else
            log_error 'clarifications.md missing "## Hidden Requirement Candidates" section'
            log_check 'Run the hidden-requirement-scan skill or add the section manually before Gate 2'
            ((errors++))
        fi
    else
        log_warning "clarifications.md not found — cannot verify hidden-requirement scan"
    fi

    # Wave 6: Check for excessive unresolved markers
    log_info "Clarification markers:"
    check_needs_clarification_markers "$feature_dir" || ((errors++))
    
    echo ""
    return $errors
}

validate_gate_3() {
    local feature_dir="$1"
    local errors=0
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  🚪 Gate 3: Implementation Gate"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Checking: Are spec, design, and tests aligned?"
    echo ""
    
    log_info "Required artifacts:"
    
    check_file_exists "$feature_dir/test-cases.md" "test-cases.md" || ((errors++))
    check_file_not_template "$feature_dir/test-cases.md" "test-cases.md" || ((errors++))
    check_test_coverage "$feature_dir/test-cases.md" "$feature_dir/spec.md" || ((errors++))
    
    check_file_exists "$feature_dir/tasks.md" "tasks.md" || ((errors++))
    check_file_not_template "$feature_dir/tasks.md" "tasks.md" || ((errors++))
    check_tasks_coverage "$feature_dir/tasks.md" "$feature_dir/plan.md" || ((errors++))
    
    check_file_exists "$feature_dir/analysis-report.md" "analysis-report.md" || ((errors++))
    check_analysis_status "$feature_dir/analysis-report.md" || ((errors++))

    # Cross-reference: every TC should have a corresponding test file
    log_info "Cross-reference checks:"
    check_tc_has_test_file "$feature_dir/test-cases.md" "$feature_dir" || ((errors++))

    # Wave 6: Check for excessive unresolved markers
    log_info "Clarification markers:"
    check_needs_clarification_markers "$feature_dir" || ((errors++))
    
    echo ""
    return $errors
}

validate_gate_4() {
    local feature_dir="$1"
    local errors=0
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  🚪 Gate 4: Ship Gate"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Checking: Is this ready for production?"
    echo ""
    
    # First validate all previous gates
    log_info "Validating previous gates..."
    
    validate_gate_1 "$feature_dir" || {
        log_error "Gate 1 criteria not met — run 'validate-gate.sh $(basename "$feature_dir") 1' for details"
        ((errors++))
    }
    
    validate_gate_2 "$feature_dir" || {
        log_error "Gate 2 criteria not met — run 'validate-gate.sh $(basename "$feature_dir") 2' for details"
        ((errors++))
    }
    
    validate_gate_3 "$feature_dir" || {
        log_error "Gate 3 criteria not met — run 'validate-gate.sh $(basename "$feature_dir") 3' for details"
        ((errors++))
    }
    
    log_info "Ship checklist:"
    check_file_exists "$feature_dir/ship-checklist.md" "ship-checklist.md" || ((errors++))
    check_ship_checklist "$feature_dir/ship-checklist.md" || ((errors++))

    # Wave 8: Goal-backward verification
    log_info "Goal-backward verification:"
    check_goal_backward "$feature_dir" || ((errors++))
    
    echo ""
    return $errors
}

# Parse arguments
VERBOSE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -*)
            log_error "Unknown option: $1"
            usage
            ;;
        *)
            if [[ -z "${FEATURE_ID:-}" ]]; then
                FEATURE_ID="$1"
            elif [[ -z "${GATE_NUM:-}" ]]; then
                GATE_NUM="$1"
            fi
            shift
            ;;
    esac
done

# Validate arguments
if [[ -z "${FEATURE_ID:-}" ]] || [[ -z "${GATE_NUM:-}" ]]; then
    log_error "Feature ID and gate number are required"
    usage
fi

if ! [[ "$GATE_NUM" =~ ^[1-4]$ ]]; then
    log_error "Gate number must be 1, 2, 3, or 4"
    exit 1
fi

FEATURE_DIR="$SPECS_DIR/$FEATURE_ID"

if [[ ! -d "$FEATURE_DIR" ]]; then
    log_error "Feature directory not found: $FEATURE_DIR"
    exit 1
fi

# ── Ceremony level detection (Wave 7) ────────────────────────────────

get_ceremony_level() {
    local feature_dir="$1"
    local meta_file="$feature_dir/.feature-meta.json"
    if [[ -f "$meta_file" ]] && command -v python3 &>/dev/null; then
        python3 -c "import json; print(json.load(open('$meta_file',encoding='utf-8-sig')).get('ceremonyLevel','standard'))" 2>/dev/null || echo "standard"
    else
        echo "standard"
    fi
}

CEREMONY_LEVEL=$(get_ceremony_level "$FEATURE_DIR")

# Ultra-Light ceremony: only Gate 4 (minimal) is meaningful
if [[ "$CEREMONY_LEVEL" == "ultra-light" && "$GATE_NUM" != "4" ]]; then
    echo ""
    log_warning "Ceremony level is 'ultra-light' — Gates 1-3 are skipped."
    log_warning "Run Gate 4 for minimal validation: validate-gate.sh $FEATURE_ID 4"
    echo ""
    exit 0
fi

log_info "Ceremony level: $CEREMONY_LEVEL"

# Acquire lock (Wave 7: crash recovery)
LOCK_FILE="$CHECKPOINTS_DIR/${FEATURE_ID}.lock"
mkdir -p "$CHECKPOINTS_DIR"
if [[ -f "$LOCK_FILE" ]]; then
    lock_pid=$(python3 -c "import json; print(json.load(open('$LOCK_FILE',encoding='utf-8-sig')).get('pid','unknown'))" 2>/dev/null || echo "unknown")
    if [[ "$lock_pid" != "unknown" ]] && kill -0 "$lock_pid" 2>/dev/null; then
        log_error "Feature $FEATURE_ID is locked by another process (PID: $lock_pid)"
        log_error "Use resume-feature.sh --unlock $FEATURE_ID to force-remove."
        exit 1
    else
        log_warning "Removing stale lock (PID $lock_pid no longer running)"
        rm -f "$LOCK_FILE"
    fi
fi
echo "{\"pid\":$$,\"agent\":\"validate-gate\",\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" > "$LOCK_FILE"

cleanup_lock() { rm -f "$LOCK_FILE"; }
trap cleanup_lock EXIT

# Wave 8: Stuck detection — compare artifact checksums to previous run
check_stuck_detection "$FEATURE_DIR" "$GATE_NUM"

run_extension_hooks "before-gate-validate" "$FEATURE_ID" "$GATE_NUM"

# Wave 11 Phase J: Run autonomy provenance checks for non-standard modes
autonomy_result=0
check_autonomy_provenance "$FEATURE_DIR" "$GATE_NUM" || autonomy_result=$?

# Run validation
case $GATE_NUM in
    1) validate_gate_1 "$FEATURE_DIR"; result=$? ;;
    2) validate_gate_2 "$FEATURE_DIR"; result=$? ;;
    3) validate_gate_3 "$FEATURE_DIR"; result=$? ;;
    4)
        if [[ "$CEREMONY_LEVEL" == "ultra-light" ]]; then
            # Ultra-light Gate 4: minimal checks only
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "  🚪 Gate 4: Ship Gate (ultra-light)"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo ""
            result=0
            check_file_exists "$FEATURE_DIR/spec.md" "spec.md" || ((result++))
            check_file_exists "$FEATURE_DIR/tasks.md" "tasks.md" || ((result++))
            check_file_exists "$FEATURE_DIR/ship-checklist.md" "ship-checklist.md" || ((result++))
            check_needs_clarification_markers "$FEATURE_DIR" || ((result++))
        else
            validate_gate_4 "$FEATURE_DIR"; result=$?
        fi
        ;;
esac

# Full ceremony: treat warnings as errors
if [[ "$CEREMONY_LEVEL" == "full" && $result -gt 0 ]]; then
    log_warning "Full ceremony: ALL issues must be resolved (zero tolerance)"
fi

# Combine gate result with autonomy provenance result
result=$((result + autonomy_result))

# Write checkpoint on success (Wave 7: crash recovery)
if [[ $result -eq 0 ]]; then
    mkdir -p "$CHECKPOINTS_DIR"
    local_checkpoint="$CHECKPOINTS_DIR/${FEATURE_ID}.checkpoint"
    echo "{\"featureId\":\"$FEATURE_ID\",\"gate\":$GATE_NUM,\"ceremony\":\"$CEREMONY_LEVEL\",\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" > "$local_checkpoint"
fi

# Append to metrics log (Wave 8: structured memory)
METRICS_LOG="$MEMORY_DIR/metrics-log.md"
if [[ -f "$METRICS_LOG" ]]; then
    timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    if [[ $result -eq 0 ]]; then result_text="PASS"; else result_text="FAIL"; fi
    echo "| $timestamp | $FEATURE_ID | Gate $GATE_NUM | $CEREMONY_LEVEL | $result_text | $result | - | - | - |" >> "$METRICS_LOG"
fi

# Update session state (Wave 8: structured memory)
SESSION_STATE="$MEMORY_DIR/session-state.md"
if [[ -f "$SESSION_STATE" ]] && [[ $result -eq 0 ]]; then
    next_phase=$((GATE_NUM + 1))
    sed -i "s/^- \*\*Feature ID:\*\* .*/- **Feature ID:** $FEATURE_ID/" "$SESSION_STATE"
    sed -i "s/^- \*\*Current Phase:\*\* .*/- **Current Phase:** Phase $next_phase/" "$SESSION_STATE"
    sed -i "s/^- \*\*Last Gate Passed:\*\* .*/- **Last Gate Passed:** Gate $GATE_NUM/" "$SESSION_STATE"
    sed -i "s/^- \*\*Last Gate Timestamp:\*\* .*/- **Last Gate Timestamp:** $(date -u +%Y-%m-%dT%H:%M:%SZ)/" "$SESSION_STATE"
    sed -i "s/^- \*\*Ceremony Level:\*\* .*/- **Ceremony Level:** $CEREMONY_LEVEL/" "$SESSION_STATE"
    # Mark completed phases
    for i in $(seq 1 $GATE_NUM); do
        case $i in
            1) phase_line="Phase 1: Requirements" ;;
            2) phase_line="Phase 2: Design" ;;
            3) phase_line="Phase 3: Preparation" ;;
            4) phase_line="Phase 5: Quality Assurance" ;;
        esac
        sed -i "s/^- \[ \] $phase_line/- [x] $phase_line/" "$SESSION_STATE"
    done
fi

# Auto-regenerate context bridge for next phase (Wave 8: context isolation)
if [[ $result -eq 0 ]]; then
    next_phase=$((GATE_NUM + 1))
    if [[ $next_phase -le 5 ]]; then
        log_info "Regenerating context bridge for Phase $next_phase..."
        "$SCRIPT_DIR/context-bridge.sh" "$FEATURE_ID" "$next_phase" 2>/dev/null || \
            log_warning "Context bridge generation failed (non-blocking)"
    fi
fi

# Final verdict
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [[ $result -eq 0 ]]; then
    log_success "GATE $GATE_NUM: PASSED ✅"
    echo ""
    echo "  Ready to proceed to the next phase!"
    run_extension_hooks "after-gate-pass" "$FEATURE_ID" "$GATE_NUM"
else
    log_error "GATE $GATE_NUM: FAILED ($result issues)"
    echo ""

    # ── Explain-mode diagnostics (OpenSpec MVP — Evolution §12 item #8) ──
    echo -e "${CYAN}📋 EXPLAIN:${NC}"
    case $GATE_NUM in
        1)
            echo "   What failed:  Gate 1 (Three Amigos Review) requires business-context.md, spec.md"
            echo "                 (with user stories and acceptance criteria), and clarifications.md."
            echo "   Why it matters: Without a shared understanding of requirements, design and"
            echo "                   implementation will diverge from business intent."
            echo "   What to do next:"
            echo "     1. Ensure business-context.md exists with real content (not template)"
            echo "     2. Ensure spec.md contains US-xxx user stories and AC-xxx acceptance criteria"
            echo "     3. Create clarifications.md to resolve ambiguities"
            echo "     4. Resolve any [NEEDS CLARIFICATION] markers (max 3 per artifact)"
            echo "     5. Re-run: $0 $FEATURE_ID 1"
            echo "   Related commands: sdd spell challenge $FEATURE_ID"
            ;;
        2)
            echo "   What failed:  Gate 2 (Technical Alignment) requires plan.md (design) with"
            echo "                 coverage of all user stories from spec.md."
            echo "   Why it matters: Without design coverage, implementation will drift from"
            echo "                   requirements. Every US-xxx in spec.md must appear in plan.md."
            echo "   What to do next:"
            echo "     1. Run: sdd spell plan-implementation $FEATURE_ID"
            echo "     2. Ensure every US-xxx in spec.md is referenced in plan.md"
            echo "     3. Validate contracts (openapi.yaml, asyncapi.yaml) if present"
            echo "     4. Re-run: $0 $FEATURE_ID 2"
            echo "   Related commands: sdd skill run sdd-challenge $FEATURE_ID"
            ;;
        3)
            echo "   What failed:  Gate 3 (Implementation Gate) requires test-cases.md, tasks.md,"
            echo "                 and analysis-report.md with passing verdict."
            echo "   Why it matters: Implementation must be traceable. Each user story needs test"
            echo "                   coverage, each test case should reference a test file, and the"
            echo "                   analysis report must show PASS or PASS WITH WARNINGS."
            echo "   What to do next:"
            echo "     1. Run: sdd spell assert-quality $FEATURE_ID"
            echo "     2. Ensure test-cases.md covers all US-xxx from spec.md"
            echo "     3. Ensure tasks.md has at least one task per design section"
            echo "     4. Run: ./generate-report.sh $FEATURE_ID"
            echo "     5. Re-run: $0 $FEATURE_ID 3"
            echo "   Related commands: sdd spell review-code $FEATURE_ID"
            ;;
        4)
            echo "   What failed:  Gate 4 (Ship Gate) requires all previous gates to pass plus"
            echo "                 ship-checklist.md with all items checked and goal-backward"
            echo "                 verification without GOAL DRIFT."
            echo "   Why it matters: Shipping without full gate compliance risks production issues"
            echo "                   and breaks the traceability chain."
            echo "   What to do next:"
            echo "     1. Fix any failing earlier gates (run validate-gate.sh for gates 1-3)"
            echo "     2. Create/complete ship-checklist.md with all items checked"
            echo "     3. Ensure analysis-report.md contains Goal-Backward Verification section"
            echo "     4. Re-run: $0 $FEATURE_ID 4"
            echo "   Related commands: sdd spell review-functional $FEATURE_ID"
            ;;
    esac
    echo ""

    echo "  Please address the issues above before proceeding."
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

exit $result
