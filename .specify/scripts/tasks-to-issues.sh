#!/usr/bin/env bash
#
# tasks-to-issues.sh - Push tasks.md entries to GitHub/GitLab Issues
#
# Usage: ./tasks-to-issues.sh <feature-id>
# Example: ./tasks-to-issues.sh 001-user-auth
#
# Reads:     .specify/specs/<feature>/tasks.md
# Creates:   GitHub or GitLab issues for each task
# Writes:    .specify/specs/<feature>/issue-map.json
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

# Load or initialize issue map
if [[ -f "$ISSUE_MAP_FILE" ]]; then
    ISSUE_MAP=$(cat "$ISSUE_MAP_FILE")
else
    ISSUE_MAP="{}"
fi

push_to_github() {
    local TASK_LINE="$1"
    local TASK_ID
    local TASK_DESC
    local CLEANED_LINE

    # Strip checkbox markers (- [ ] or - [x]) before extracting task ID/description
    CLEANED_LINE=$(echo "$TASK_LINE" | sed -E 's/^\s*- \[[xX ]\] //')
    TASK_ID=$(echo "$CLEANED_LINE" | grep -oE '[A-Z]+-[0-9]+' | head -1 || echo "")
    TASK_DESC=$(echo "$CLEANED_LINE" | sed -E 's/^[A-Z]+-[0-9]+:\s*//')

    if [[ -z "$TASK_ID" ]]; then
        log_warning "Skipping task with no ID: $TASK_LINE"
        return 0
    fi

    local TITLE="[$FEATURE_ID] $TASK_ID: $TASK_DESC"

    local EXISTING_NUM
    EXISTING_NUM=$(echo "$ISSUE_MAP" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('$TASK_ID',''))" 2>/dev/null || echo "")

    if [[ -n "$EXISTING_NUM" ]]; then
        log_info "Task $TASK_ID already mapped to issue #$EXISTING_NUM — skipping"
        return 0
    fi

    if ! command -v gh &>/dev/null; then
        log_warning "gh CLI not found — cannot create GitHub issue for $TASK_ID"
        return 0
    fi

    log_info "Creating GitHub issue for $TASK_ID..."
    local ISSUE_NUM
    ISSUE_NUM=$(gh issue create --title "$TITLE" --body "Feature: $FEATURE_ID\nTask: $TASK_ID\n\n$TASK_DESC" --label "sdd-task" 2>/dev/null | grep -oE '[0-9]+$' || echo "")

    if [[ -n "$ISSUE_NUM" ]]; then
        ISSUE_MAP=$(echo "$ISSUE_MAP" | python3 -c "import json,sys; d=json.load(sys.stdin); d['$TASK_ID']=$ISSUE_NUM; print(json.dumps(d, indent=2))")
        log_success "Created issue #$ISSUE_NUM for $TASK_ID"
    fi
}

push_to_gitlab() {
    local TASK_LINE="$1"
    local TASK_ID
    local TASK_DESC
    local CLEANED_LINE

    # Strip checkbox markers (- [ ] or - [x]) before extracting task ID/description
    CLEANED_LINE=$(echo "$TASK_LINE" | sed -E 's/^\s*- \[[xX ]\] //')
    TASK_ID=$(echo "$CLEANED_LINE" | grep -oE '[A-Z]+-[0-9]+' | head -1 || echo "")
    TASK_DESC=$(echo "$CLEANED_LINE" | sed -E 's/^[A-Z]+-[0-9]+:\s*//')

    if [[ -z "$TASK_ID" ]]; then
        log_warning "Skipping task with no ID: $TASK_LINE"
        return 0
    fi

    local TITLE="[$FEATURE_ID] $TASK_ID: $TASK_DESC"

    local EXISTING_NUM
    EXISTING_NUM=$(echo "$ISSUE_MAP" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('$TASK_ID',''))" 2>/dev/null || echo "")

    if [[ -n "$EXISTING_NUM" ]]; then
        log_info "Task $TASK_ID already mapped to issue #$EXISTING_NUM — skipping"
        return 0
    fi

    if command -v glab &>/dev/null; then
        log_info "Creating GitLab issue for $TASK_ID via glab..."
        local ISSUE_NUM
        ISSUE_NUM=$(glab issue create --title "$TITLE" --description "Feature: $FEATURE_ID\nTask: $TASK_ID\n\n$TASK_DESC" 2>/dev/null | grep -oE '#[0-9]+' | tr -d '#' || echo "")
        if [[ -n "$ISSUE_NUM" ]]; then
            ISSUE_MAP=$(echo "$ISSUE_MAP" | python3 -c "import json,sys; d=json.load(sys.stdin); d['$TASK_ID']=$ISSUE_NUM; print(json.dumps(d, indent=2))")
            log_success "Created issue #$ISSUE_NUM for $TASK_ID"
        fi
    elif [[ -n "${GITLAB_TOKEN:-}" && -n "${GITLAB_PROJECT_ID:-}" ]]; then
        log_info "Creating GitLab issue for $TASK_ID via REST API..."
        local GITLAB_URL="${GITLAB_URL:-https://gitlab.com}"
        local RESPONSE
        RESPONSE=$(curl -s -X POST "$GITLAB_URL/api/v4/projects/$GITLAB_PROJECT_ID/issues" \
            -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
            -H "Content-Type: application/json" \
            -d "{\"title\":\"$TITLE\",\"description\":\"Feature: $FEATURE_ID\\nTask: $TASK_ID\"}" 2>/dev/null)
        local ISSUE_NUM
        ISSUE_NUM=$(echo "$RESPONSE" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('iid',''))" 2>/dev/null || echo "")
        if [[ -n "$ISSUE_NUM" ]]; then
            ISSUE_MAP=$(echo "$ISSUE_MAP" | python3 -c "import json,sys; d=json.load(sys.stdin); d['$TASK_ID']=$ISSUE_NUM; print(json.dumps(d, indent=2))")
            log_success "Created issue #$ISSUE_NUM for $TASK_ID"
        fi
    else
        log_warning "No GitLab CLI (glab) or GITLAB_TOKEN+GITLAB_PROJECT_ID env vars — skipping $TASK_ID"
    fi
}

# Main loop
log_info "Reading tasks from: $TASKS_FILE"
TASK_COUNT=0
while IFS= read -r LINE; do
    if [[ "$TRACKER" == "github" ]]; then
        push_to_github "$LINE"
    else
        push_to_gitlab "$LINE"
    fi
    ((TASK_COUNT++)) || true
done < <(grep -E '^\s*- \[[ xX]\] ' "$TASKS_FILE" || true)

# Save updated issue map
echo "$ISSUE_MAP" > "$ISSUE_MAP_FILE"
log_success "Issue map saved to: $ISSUE_MAP_FILE"
log_success "Processed $TASK_COUNT task(s)"
