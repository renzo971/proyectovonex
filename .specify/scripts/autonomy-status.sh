#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────
# autonomy-status.sh — Show autonomy execution status for a feature
# Wave 11 · Phase J · Enterprise SDD
# ─────────────────────────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${SDD_REPO_ROOT:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

# ── Colours ──────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

info()  { printf "${CYAN}ℹ ${NC}%s\n" "$*"; }
ok()    { printf "${GREEN}✔ ${NC}%s\n" "$*"; }
warn()  { printf "${YELLOW}⚠ ${NC}%s\n" "$*"; }
err()   { printf "${RED}✘ ${NC}%s\n" "$*"; }
header(){ printf "\n${BOLD}%s${NC}\n" "$*"; }

# ── Resolve feature directory ────────────────────────────────────
FEATURE_ID="${1:-}"

if [[ -n "$FEATURE_ID" ]]; then
    FEATURE_DIR="$REPO_ROOT/.specify/specs/$FEATURE_ID"
else
    # Try to detect from current directory
    if [[ -f ".feature-meta.json" ]]; then
        FEATURE_DIR="$(pwd)"
        FEATURE_ID="$(basename "$FEATURE_DIR")"
    elif [[ -f "$REPO_ROOT/.specify/active-feature" ]]; then
        FEATURE_ID="$(cat "$REPO_ROOT/.specify/active-feature")"
        FEATURE_DIR="$REPO_ROOT/.specify/specs/$FEATURE_ID"
    else
        err "No feature-id provided and no active feature detected."
        echo "Usage: sdd autonomy status [feature-id]"
        exit 2
    fi
fi

META_FILE="$FEATURE_DIR/.feature-meta.json"

if [[ ! -d "$FEATURE_DIR" ]]; then
    err "Feature directory not found: $FEATURE_DIR"
    exit 2
fi

if [[ ! -f "$META_FILE" ]]; then
    err "No .feature-meta.json in $FEATURE_DIR"
    exit 2
fi

EVIDENCE_SCRIPT="$SCRIPT_DIR/autonomy-evidence.py"
if [[ -f "$EVIDENCE_SCRIPT" ]]; then
    # Idempotent sync: writes per-cycle artifacts and refreshes autonomy-progress.md
    python3 "$EVIDENCE_SCRIPT" sync --repo-root "$REPO_ROOT" --feature-id "$FEATURE_ID" --format json >/dev/null 2>&1 || true
fi

# ── Read metadata ────────────────────────────────────────────────
get_field() {
    local field="$1"
    local default="${2:-}"
    local val
    val=$(python3 -c "
import json, sys
with open('$META_FILE') as f:
    d = json.load(f)
print(d.get('$field', '$default'))
" 2>/dev/null || echo "$default")
    echo "$val"
}

EXEC_MODE=$(get_field "executionMode" "standard")
BUDGET=$(get_field "autonomyBudget" "0")
MAX_ITER=$(get_field "autonomyMaxIterations" "3")
ESCALATION=$(get_field "escalationThreshold" "3")
ITEM_LIMIT=$(get_field "autonomyItemLimit" "1")
CTX_RESET=$(get_field "autonomyContextReset" "required-per-item")
PERSISTENCE=$(get_field "autonomyPersistenceRequired" "true")
FALLBACK=$(get_field "fallbackExecutionMode" "standard")
LAST_STATUS=$(get_field "lastAutonomyStatus" "idle")

# ── Count cycles in todo.md ─────────────────────────────────────
TODO_FILE="$FEATURE_DIR/todo.md"
CYCLES_CONSUMED=0
if [[ -f "$TODO_FILE" ]]; then
    CYCLES_CONSUMED=$(grep -cE '^## Cycle [0-9]+' "$TODO_FILE" 2>/dev/null || echo "0")
fi

# ── Display ──────────────────────────────────────────────────────
header "🤖 Autonomy Status: $FEATURE_ID"
echo ""

printf "  %-28s %s\n" "Execution Mode:" "$EXEC_MODE"
printf "  %-28s %s\n" "Last Status:" "$LAST_STATUS"
echo ""

if [[ "$EXEC_MODE" == "standard" ]]; then
    info "Feature is in standard (human-driven) mode. No autonomy metrics to display."
    exit 0
fi

STATUS_SUMMARY=""
if [[ -f "$EVIDENCE_SCRIPT" ]]; then
    STATUS_SUMMARY=$(python3 "$EVIDENCE_SCRIPT" summary --repo-root "$REPO_ROOT" --feature-id "$FEATURE_ID" --format text 2>/dev/null || true)
fi

if [[ -n "$STATUS_SUMMARY" ]]; then
    IFS='|' read -r VERDICT_STATUS VERDICT_CONFIDENCE VERDICT_REPAIR_HINT CURRENT_CYCLE NEXT_ACTION BLOCKER CYCLE_COUNT LEDGER_PATH <<< "$STATUS_SUMMARY"
else
    VERDICT_STATUS="retry"
    VERDICT_CONFIDENCE="0.00"
    VERDICT_REPAIR_HINT=""
    CURRENT_CYCLE="0"
    NEXT_ACTION="Start first autonomous cycle and record evidence."
    BLOCKER="none"
    CYCLE_COUNT="0"
    LEDGER_PATH="$FEATURE_DIR/autonomy-progress.md"
fi

header "📊 Budget & Limits"
printf "  %-28s %s\n" "Autonomy Budget:" "$BUDGET cycles"
printf "  %-28s %s\n" "Cycles Consumed:" "$CYCLES_CONSUMED"
if [[ "$BUDGET" -gt 0 ]]; then
    REMAINING=$((BUDGET - CYCLES_CONSUMED))
    if [[ $REMAINING -le 0 ]]; then
        err "Budget EXHAUSTED ($CYCLES_CONSUMED/$BUDGET)"
    elif [[ $REMAINING -le 2 ]]; then
        warn "Budget almost exhausted: $REMAINING cycle(s) remaining"
    else
        ok "Budget healthy: $REMAINING cycle(s) remaining"
    fi
else
    info "No budget cap set"
fi
printf "  %-28s %s\n" "Max Iterations/Cycle:" "$MAX_ITER"
printf "  %-28s %s\n" "Escalation Threshold:" "$ESCALATION"
printf "  %-28s %s\n" "Item Limit/Cycle:" "$ITEM_LIMIT"
echo ""

header "🧪 Structured Verdict"
printf "  %-28s %s\n" "Verdict status:" "$VERDICT_STATUS"
printf "  %-28s %s\n" "Confidence:" "$VERDICT_CONFIDENCE"
printf "  %-28s %s\n" "Repair hint:" "${VERDICT_REPAIR_HINT:--}"
printf "  %-28s %s\n" "Current cycle:" "$CURRENT_CYCLE"
printf "  %-28s %s\n" "Cycle count:" "$CYCLE_COUNT"
printf "  %-28s %s\n" "Blocker:" "$BLOCKER"
printf "  %-28s %s\n" "Next action:" "$NEXT_ACTION"
printf "  %-28s %s\n" "Progress ledger:" "$LEDGER_PATH"
echo ""

header "⚙ Configuration"
printf "  %-28s %s\n" "Context Reset:" "$CTX_RESET"
printf "  %-28s %s\n" "Persistence Required:" "$PERSISTENCE"
printf "  %-28s %s\n" "Fallback Mode:" "$FALLBACK"
echo ""

# ── Provenance summary ───────────────────────────────────────────
if [[ -f "$TODO_FILE" ]]; then
    header "📋 Provenance Summary"
    TODO_CONTENT=$(cat "$TODO_FILE")

    HAS_RATIONALE=false
    HAS_CONFIDENCE=false
    HAS_RISK=false
    HAS_ARTIFACTS=false

    echo "$TODO_CONTENT" | grep -qiE '(rationale|reason)\*?\*?:' && HAS_RATIONALE=true
    echo "$TODO_CONTENT" | grep -qiE 'confidence.*score.*[1-5]|confidence.*[1-5]/5' && HAS_CONFIDENCE=true
    echo "$TODO_CONTENT" | grep -qiE 'risk.*classification.*:\s*\b(low|medium|high|critical)\b' && HAS_RISK=true
    echo "$TODO_CONTENT" | grep -qiE 'touched.*artifact|files.*modified|files.*created' && HAS_ARTIFACTS=true

    [[ "$HAS_RATIONALE" == true ]]   && ok "Rationale present"   || warn "No rationale found"
    [[ "$HAS_CONFIDENCE" == true ]]  && ok "Confidence scores"   || warn "No confidence scores"
    [[ "$HAS_RISK" == true ]]        && ok "Risk classification" || warn "No risk classification"
    [[ "$HAS_ARTIFACTS" == true ]]   && ok "Artifact tracking"   || warn "No artifact list"
    echo ""
else
    warn "No todo.md found — no cycle evidence recorded yet"
fi

# ── Lessons ──────────────────────────────────────────────────────
LESSONS_FILE="$FEATURE_DIR/lessons.md"
if [[ -f "$LESSONS_FILE" ]]; then
    LESSON_COUNT=$(grep -cE '^##' "$LESSONS_FILE" 2>/dev/null || echo "0")
    ok "Lessons file present ($LESSON_COUNT entries)"
else
    info "No lessons.md yet"
fi

echo ""
exit 0
