#!/usr/bin/env bash
#
# issues-to-tasks.sh - Pull GitHub/GitLab issue states back into tasks.md
#
# Usage: ./issues-to-tasks.sh <feature-id>
# Example: ./issues-to-tasks.sh 001-user-auth
#
# Reads:     .specify/specs/<feature>/issue-map.json
#            .specify/specs/<feature>/tasks.md
# Updates:   .specify/specs/<feature>/tasks.md (checkbox states)
#
# Requires: gh (GitHub CLI) or GITLAB_TOKEN env var
#

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

log_info()    { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error()   { echo -e "${RED}❌ $1${NC}" >&2; }

validate_feature_id() {
    local feature_id="$1"
    if [[ ! "$feature_id" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]]; then
        log_error "Invalid feature ID: $feature_id"
        log_error "Feature ID may only contain letters, numbers, dot, underscore, and hyphen."
        exit 2
    fi
}

FEATURE_ID="${1:?Feature ID required. Usage: $0 <feature-id>}"
validate_feature_id "$FEATURE_ID"
FEATURE_DIR="$REPO_ROOT/.specify/specs/$FEATURE_ID"
TASKS_FILE="$FEATURE_DIR/tasks.md"
ISSUE_MAP_FILE="$FEATURE_DIR/issue-map.json"

if [[ ! -f "$TASKS_FILE" ]]; then
    log_error "Tasks file not found: $TASKS_FILE"
    exit 2
fi

if [[ ! -f "$ISSUE_MAP_FILE" ]]; then
    log_error "Issue map not found: $ISSUE_MAP_FILE"
    log_error "Run tasks-to-issues.sh first to create the mapping."
    exit 2
fi

# Detect issue tracker from constitution
detect_issue_tracker() {
    local CONSTITUTION="$REPO_ROOT/.specify/memory/constitution.md"
    if [[ -f "$CONSTITUTION" ]] && grep -qi "gitlab" "$CONSTITUTION"; then
        echo "gitlab"
    else
        echo "github"
    fi
}

TRACKER=$(detect_issue_tracker)
log_info "Issue tracker: $TRACKER"

# Load issue map
ISSUE_MAP=$(cat "$ISSUE_MAP_FILE")

get_github_issue_state() {
    local ISSUE_NUM="$1"
    if ! command -v gh &>/dev/null; then
        echo "unknown"
        return
    fi
    gh issue view "$ISSUE_NUM" --json state -q '.state' 2>/dev/null | tr '[:upper:]' '[:lower:]' || echo "unknown"
}

get_gitlab_issue_state() {
    local ISSUE_NUM="$1"
    if command -v glab &>/dev/null; then
        glab issue view "$ISSUE_NUM" --output json 2>/dev/null | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('state','unknown'))" 2>/dev/null || echo "unknown"
    elif [[ -n "${GITLAB_TOKEN:-}" && -n "${GITLAB_PROJECT_ID:-}" ]]; then
        local GITLAB_URL="${GITLAB_URL:-https://gitlab.com}"
        curl -s "$GITLAB_URL/api/v4/projects/$GITLAB_PROJECT_ID/issues/$ISSUE_NUM" \
            -H "PRIVATE-TOKEN: $GITLAB_TOKEN" 2>/dev/null | \
            python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('state','unknown'))" 2>/dev/null || echo "unknown"
    else
        echo "unknown"
    fi
}

# Get all task IDs from map
TASK_IDS=$(echo "$ISSUE_MAP" | python3 -c "import json,sys; d=json.load(sys.stdin); [print(k) for k in d.keys()]" 2>/dev/null || echo "")

if [[ -z "$TASK_IDS" ]]; then
    log_warning "No tasks in issue map — nothing to sync"
    exit 0
fi

log_info "Syncing issue states back to: $TASKS_FILE"
UPDATED=0
TASKS_CONTENT=$(cat "$TASKS_FILE")

while IFS= read -r TASK_ID; do
    [[ -z "$TASK_ID" ]] && continue

    ISSUE_NUM=$(echo "$ISSUE_MAP" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('$TASK_ID',''))" 2>/dev/null || echo "")
    [[ -z "$ISSUE_NUM" ]] && continue

    if [[ "$TRACKER" == "github" ]]; then
        STATE=$(get_github_issue_state "$ISSUE_NUM")
    else
        STATE=$(get_gitlab_issue_state "$ISSUE_NUM")
    fi

    log_info "Task $TASK_ID (issue #$ISSUE_NUM): $STATE"

    # Escape TASK_ID for use in sed regex (handles special chars like + . etc.)
    TASK_ID_ESC=""
    TASK_ID_ESC=$(printf '%s' "$TASK_ID" | sed 's/[[\.*^$()+?{|]/\\&/g')

    if [[ "$STATE" == "closed" ]]; then
        # Mark as done: - [ ] → - [x]
        TASKS_CONTENT=$(echo "$TASKS_CONTENT" | sed -E "s/^(\s*- )\[ \]( .*${TASK_ID_ESC}.*)/\1[x]\2/")
        ((UPDATED++)) || true
    elif [[ "$STATE" == "open" ]]; then
        # Ensure open tasks are unchecked
        TASKS_CONTENT=$(echo "$TASKS_CONTENT" | sed -E "s/^(\s*- )\[x\]( .*${TASK_ID_ESC}.*)/\1[ ]\2/")
    fi
done <<< "$TASK_IDS"

echo "$TASKS_CONTENT" > "$TASKS_FILE"
log_success "Updated $UPDATED task(s) in: $TASKS_FILE"
