#!/usr/bin/env bash
#
# status.sh - Show status dashboard for all features
#
# Usage: ./status.sh
#

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SPECS_DIR="$REPO_ROOT/.specify/specs"
MEMORY_DIR="$REPO_ROOT/.specify/memory"
WORKTREES_DIR="$REPO_ROOT/.sdd/worktrees"
FEATURE_FILTER=""
SHOW_GRAPH=false
SHOW_AUTONOMY=false

# Parse flags
while [[ $# -gt 0 ]]; do
    case "$1" in
        --graph) SHOW_GRAPH=true; shift ;;
        --autonomy) SHOW_AUTONOMY=true; shift ;;
        -h|--help)
            echo "Usage: $(basename "$0") [<feature-id>] [--graph]"
            echo ""
            echo "Options:"
            echo "  --graph    Show artifact dependency graph for the feature"
            echo "  --autonomy Include autonomy evidence summary (best with a feature-id)"
            echo "  -h,--help  Show this help message"
            exit 0
            ;;
        -*) echo "Unknown option: $1" >&2; exit 1 ;;
        *) FEATURE_FILTER="$1"; shift ;;
    esac
done

check_file() {
    [[ -f "$1" ]] && echo "✓" || echo "✗"
}

# ── Artifact Dependency Graph (OpenSpec MVP — Evolution §12 item #1) ──

render_artifact_graph() {
    local feature_dir="$1"
    local feature_name
    feature_name=$(basename "$feature_dir")

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "  ${BOLD}📐 Artifact Dependency Graph: $feature_name${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    local status_char
    artifact_status() {
        local file="$1"
        if [[ ! -f "$file" ]]; then
            echo "✗ Missing"
        elif is_file_ready "$file"; then
            echo "✓ Present"
        else
            echo "⚠ Template"
        fi
    }

    local constitution_s=$(artifact_status "$MEMORY_DIR/constitution.md")
    local biz_s=$(artifact_status "$feature_dir/business-context.md")
    local spec_s=$(artifact_status "$feature_dir/spec.md")
    local clarify_s=$(artifact_status "$feature_dir/clarifications.md")
    local plan_s=$(artifact_status "$feature_dir/plan.md")
    local tests_s=$(artifact_status "$feature_dir/test-cases.md")
    local tasks_s=$(artifact_status "$feature_dir/tasks.md")
    local report_s=$(artifact_status "$feature_dir/analysis-report.md")
    local decisions_s=$(artifact_status "$MEMORY_DIR/decisions.md")
    local lessons_s=$(artifact_status "$MEMORY_DIR/lessons.md")
    local metrics_s=$(artifact_status "$MEMORY_DIR/metrics-log.md")

    echo "  constitution.md [$constitution_s]"
    echo "    └─► business-context.md [$biz_s]"
    echo "         └─► spec.md [$spec_s]"
    echo "              ├─► clarifications.md [$clarify_s]"
    echo "              └─► plan.md (design) [$plan_s]"
    echo "                   ├─► test-cases.md [$tests_s]"
    echo "                   └─► tasks.md [$tasks_s]"
    echo "                        └─► analysis-report.md [$report_s]"
    echo "                             └─► memory/"
    echo "                                  ├─► decisions.md [$decisions_s]"
    echo "                                  ├─► lessons.md [$lessons_s]"
    echo "                                  └─► metrics-log.md [$metrics_s]"
    echo ""
    echo "  Legend: ✓ Present  ✗ Missing  ⚠ Template (not compiled)"
    echo ""
}

# Check if a file exists AND has real content (not just a template)
is_file_ready() {
    local file="$1"
    [[ ! -f "$file" ]] && return 1

    # Reject files that still contain template placeholder markers
    if grep -qE '\[FEATURE_NAME\]|\[NNN\]|<!-- INSTRUCTION -->' "$file" 2>/dev/null; then
        return 1
    fi

    # Reject files where the Status field still shows multiple choices (template)
    # e.g. "**Status:** Draft | Under Review | Approved" → not yet compiled
    if grep -qE '^\*\*Status:\*\*.*\|.*\|' "$file" 2>/dev/null; then
        return 1
    fi

    # Reject files with typical template placeholders like [Story Title]
    if grep -qE '\[Story [Tt]itle\]|\[Describe |\[Add ' "$file" 2>/dev/null; then
        return 1
    fi

    return 0
}

# P = Present (real content), T = Template (exists but not compiled), M = Missing
check_file_ascii() {
    if [[ ! -f "$1" ]]; then
        echo "M"
    elif is_file_ready "$1"; then
        echo "P"
    else
        echo "T"
    fi
}

determine_phase() {
    local dir="$1"
    
    # Check artifacts in reverse order to find current phase
    # Only count files with real content (not templates)
    if [[ -f "$dir/ship-checklist.md" ]] && grep -q '\[x\]' "$dir/ship-checklist.md" 2>/dev/null; then
        echo "5-Ship"
    elif is_file_ready "$dir/analysis-report.md"; then
        echo "4-Impl"
    elif is_file_ready "$dir/tasks.md"; then
        echo "3.2-Tasks"
    elif is_file_ready "$dir/test-cases.md"; then
        echo "3.1-Tests"
    elif is_file_ready "$dir/plan.md"; then
        echo "2-Design"
    elif is_file_ready "$dir/clarifications.md"; then
        echo "1.3-Clarify"
    elif is_file_ready "$dir/spec.md"; then
        echo "1.2-Spec"
    elif is_file_ready "$dir/business-context.md"; then
        echo "1.1-Vision"
    else
        echo "0-Init"
    fi
}

memory_freshness_score() {
    local feature_dir="$1"
    local now epoch latest=0
    now=$(date +%s)

    for file in \
        "$MEMORY_DIR/decisions.md" \
        "$MEMORY_DIR/lessons.md" \
        "$MEMORY_DIR/metrics-log.md" \
        "$feature_dir/.feature-meta.json"; do
        if [[ -f "$file" ]]; then
            epoch=$(stat -c %Y "$file" 2>/dev/null || echo 0)
            if [[ "$epoch" -gt "$latest" ]]; then
                latest="$epoch"
            fi
        fi
    done

    if [[ "$latest" -eq 0 ]]; then
        echo "N/A"
        return
    fi

    local age_days=$(( (now - latest) / 86400 ))
    if [[ "$age_days" -le 7 ]]; then
        echo "100"
    elif [[ "$age_days" -le 14 ]]; then
        echo "80"
    elif [[ "$age_days" -le 30 ]]; then
        echo "60"
    elif [[ "$age_days" -le 60 ]]; then
        echo "40"
    else
        echo "20"
    fi
}

cost_metrics() {
    local feature_dir="$1"
    local cost_log="$feature_dir/cost-log.json"

    if [[ ! -f "$cost_log" ]]; then
        echo "0.00|N/A|N/A|-"
        return
    fi

    python3 - "$cost_log" << 'PY'
import json
import sys
from collections import defaultdict

path = sys.argv[1]
try:
    data = json.load(open(path, encoding="utf-8"))
except Exception:
    print("0.00|N/A|N/A|invalid")
    raise SystemExit(0)

total = float(data.get("totalCost", 0.0) or 0.0)
budget = data.get("budgetCeiling")
entries = data.get("entries", []) or []

if (not total) and entries:
    total = sum(float(item.get("estimatedCost", 0.0) or 0.0) for item in entries)

by_phase = defaultdict(float)
for item in entries:
    phase = str(item.get("phase", "?")).strip()
    by_phase[phase] += float(item.get("estimatedCost", 0.0) or 0.0)

def phase_key(raw: str):
    try:
        return int(raw)
    except Exception:
        return 9999

trend = ",".join(f"p{p}:{by_phase[p]:.2f}" for p in sorted(by_phase, key=phase_key))
if not trend:
    trend = "-"

if budget in (None, "", 0):
    util = "N/A"
    budget_s = "N/A"
else:
    b = float(budget)
    budget_s = f"{b:.2f}"
    util = f"{(total / b) * 100:.1f}%" if b > 0 else "N/A"

print(f"{total:.2f}|{budget_s}|{util}|{trend}")
PY
}

collect_feature_dirs() {
    declare -A seen=()
    local dir name

    if [[ -d "$SPECS_DIR" ]]; then
        for dir in "$SPECS_DIR"/*/; do
            [[ ! -d "$dir" ]] && continue
            name=$(basename "$dir")
            if [[ -n "$FEATURE_FILTER" && "$name" != "$FEATURE_FILTER" ]]; then
                continue
            fi
            seen["$name"]="$dir"
        done
    fi

    if [[ -d "$WORKTREES_DIR" ]]; then
        for dir in "$WORKTREES_DIR"/*/.specify/specs/*/; do
            [[ ! -d "$dir" ]] && continue
            name=$(basename "$dir")
            if [[ -n "$FEATURE_FILTER" && "$name" != "$FEATURE_FILTER" ]]; then
                continue
            fi
            if [[ -z "${seen[$name]:-}" ]]; then
                seen["$name"]="$dir"
            fi
        done
    fi

    for name in "${!seen[@]}"; do
        printf '%s\n' "${seen[$name]}"
    done | sort
}

get_gate_status() {
    local dir="$1"
    local phase="$2"
    case "$phase" in
        "5-Ship")     echo "Gate 4" ;;
        "4-Impl")     echo "Gate 3" ;;
        "3"*)         echo "→ Gate 3" ;;
        "2-Design")   echo "Gate 2" ;;
        "1.3-Clarify") echo "→ Gate 1" ;;
        "1"*)         echo "Pre-Gate" ;;
        *)            echo "-" ;;
    esac
}

render_autonomy_summary() {
    local feature_dir="$1"
    local feature_id
    feature_id=$(basename "$feature_dir")
    local evidence_script="$SCRIPT_DIR/autonomy-evidence.py"

    if [[ ! -f "$evidence_script" ]]; then
        echo -e "${YELLOW}⚠${NC} Autonomy evidence script not found: $evidence_script"
        return 0
    fi

    local meta_file="$feature_dir/.feature-meta.json"
    if [[ ! -f "$meta_file" ]]; then
        echo -e "${YELLOW}⚠${NC} No .feature-meta.json found for $feature_id"
        return 0
    fi

    local exec_mode
    exec_mode=$(python3 - <<PY
import json
from pathlib import Path
path = Path(r"$meta_file")
try:
    data = json.loads(path.read_text(encoding="utf-8"))
    print(data.get("executionMode", "standard"))
except Exception:
    print("standard")
PY
)

    if [[ "$exec_mode" == "standard" ]]; then
        echo -e "${BLUE}ℹ️${NC} Feature $feature_id is in standard mode; autonomy evidence not required."
        return 0
    fi

    local summary
    summary=$(python3 "$evidence_script" sync --repo-root "$REPO_ROOT" --feature-id "$feature_id" --format text 2>/dev/null || true)
    if [[ -z "$summary" ]]; then
        echo -e "${YELLOW}⚠${NC} Could not compute autonomy summary for $feature_id"
        return 0
    fi

    local status confidence repair_hint current_cycle next_action blocker cycle_count ledger_path
    IFS='|' read -r status confidence repair_hint current_cycle next_action blocker cycle_count ledger_path <<< "$summary"

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "  ${BOLD}🤖 Autonomy Evidence Summary: $feature_id${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    printf "  %-28s %s\n" "Latest verdict status:" "$status"
    printf "  %-28s %s\n" "Confidence:" "$confidence"
    printf "  %-28s %s\n" "Repair hint:" "${repair_hint:--}"
    printf "  %-28s %s\n" "Current cycle:" "$current_cycle"
    printf "  %-28s %s\n" "Cycle count:" "$cycle_count"
    printf "  %-28s %s\n" "Blocker:" "$blocker"
    printf "  %-28s %s\n" "Next action:" "$next_action"
    printf "  %-28s %s\n" "Progress ledger:" "$ledger_path"
}

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "  ${BOLD}📊 Feature Status Dashboard${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check constitution
if [[ -f "$MEMORY_DIR/constitution.md" ]]; then
    echo -e "${GREEN}✓${NC} Constitution established"
else
    echo -e "${YELLOW}⚠${NC} No constitution found - run Constitution Agent first"
fi

echo ""

# Check if any features exist
FEATURE_DIRS="$(collect_feature_dirs)"
if [[ -z "$FEATURE_DIRS" ]]; then
    echo -e "${BLUE}ℹ️  No features found${NC}"
    echo ""
    echo "  Create a new feature with:"
    echo -e "  ${CYAN}.specify/scripts/new-feature.sh \"feature name\"${NC}"
    echo ""
    exit 0
fi

# Header
printf "%-25s | %-10s | %-12s | %-6s | %-6s | %-6s | %-6s | %-6s | %-6s | %-8s | %-8s\n" \
    "Feature" "Phase" "Gate" "Spec" "Plan" "Tests" "Tasks" "Report" "MFS" "Cost" "Budget%"
printf "%-25s-+-%-10s-+-%-12s-+-%-6s-+-%-6s-+-%-6s-+-%-6s-+-%-6s-+-%-6s-+-%-8s-+-%-8s\n" \
    "-------------------------" "----------" "------------" "------" "------" "------" "------" "------" "------" "--------" "--------"

# List features
while IFS= read -r feature_dir; do
    [[ -z "$feature_dir" ]] && continue
    
    feature_name=$(basename "$feature_dir")
    phase=$(determine_phase "$feature_dir")
    gate=$(get_gate_status "$feature_dir" "$phase")
    mfs=$(memory_freshness_score "$feature_dir")
    IFS='|' read -r total_cost budget_val budget_util trend <<< "$(cost_metrics "$feature_dir")"
    
    spec=$(check_file_ascii "$feature_dir/spec.md")
    plan=$(check_file_ascii "$feature_dir/plan.md")
    tests=$(check_file_ascii "$feature_dir/test-cases.md")
    tasks=$(check_file_ascii "$feature_dir/tasks.md")
    report=$(check_file_ascii "$feature_dir/analysis-report.md")
    
    # Nessun colore nella tabella
    printf "%-25s | %-10s | %-12s | %-6s | %-6s | %-6s | %-6s | %-6s | %-6s | %-8s | %-8s\n" \
        "$feature_name" "$phase" "$gate" "$spec" "$plan" "$tests" "$tasks" "$report" "$mfs" "$total_cost" "$budget_util"

    if [[ "$trend" != "-" ]]; then
        printf "%-25s | %-10s | %-12s | %-6s | %-6s | %-6s | %-6s | %-6s | %-6s | %-8s | %-8s\n" \
            "" "" "" "" "" "" "" "" "" "trend" "$trend"
    fi

    if [[ "$budget_util" != "N/A" ]]; then
        util_num="${budget_util%%%}"
        if [[ $(printf '%.0f' "$util_num") -ge 80 ]]; then
            echo -e "${YELLOW}⚠ Budget warning for $feature_name: $total_cost / $budget_val ($budget_util)${NC}"
        fi
    fi
done <<< "$FEATURE_DIRS"

if $SHOW_AUTONOMY; then
    if [[ -n "$FEATURE_FILTER" ]]; then
        while IFS= read -r feature_dir; do
            [[ -z "$feature_dir" ]] && continue
            render_autonomy_summary "$feature_dir"
        done <<< "$FEATURE_DIRS"
    else
        echo -e "${BLUE}ℹ️${NC} --autonomy without feature-id: rendering summaries for all discovered features"
        while IFS= read -r feature_dir; do
            [[ -z "$feature_dir" ]] && continue
            render_autonomy_summary "$feature_dir"
        done <<< "$FEATURE_DIRS"
    fi
fi

# ── Artifact graph mode (OpenSpec MVP) ────────────────────────────────
if $SHOW_GRAPH; then
    if [[ -z "$FEATURE_FILTER" ]]; then
        # Render graph for every feature
        while IFS= read -r feature_dir; do
            [[ -z "$feature_dir" ]] && continue
            render_artifact_graph "$feature_dir"
        done <<< "$FEATURE_DIRS"
    else
        # Render graph for the filtered feature only
        while IFS= read -r feature_dir; do
            [[ -z "$feature_dir" ]] && continue
            render_artifact_graph "$feature_dir"
        done <<< "$FEATURE_DIRS"
    fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  Legend:"
echo -e "    P = Present (real content)    T = Template (not compiled)    M = Missing"
echo ""
echo "  Phases: 1.1-Vision → 1.2-Spec → 1.3-Clarify → 2-Design → 3.1-Tests → 3.2-Tasks → 4-Impl → 5-Ship"
echo ""
echo "  Commands:"
echo -e "    ${CYAN}./validate-gate.sh <feature> <1|2|3|4>${NC}  - Validate gate criteria"
echo -e "    ${CYAN}./analyze-consistency.sh <feature>${NC}      - Run consistency analysis"
echo -e "    ${CYAN}./generate-report.sh <feature>${NC}          - Generate analysis report"
echo -e "    ${CYAN}./memory-status.sh <feature>${NC}            - Show memory freshness metrics"
echo -e "    ${CYAN}./memory-sync.sh <feature>${NC}              - Refresh memory index + logs"
echo -e "    ${CYAN}./memory-doctor.sh <feature>${NC}            - Diagnose memory drift/conflicts"
echo -e "    ${CYAN}./status.sh <feature> --autonomy${NC}         - Show structured autonomy evidence summary"
echo ""
