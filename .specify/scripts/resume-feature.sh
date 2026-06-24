#!/usr/bin/env bash
#
# resume-feature.sh - Resume a feature from its last checkpoint
#
# Usage: ./resume-feature.sh <feature-id>
# Example: ./resume-feature.sh 001-user-auth
#
# Reads .specify/checkpoints/<feature-id>.checkpoint to determine
# the last successfully passed gate, then advises on next steps.
#
# Also provides lock-file management to prevent concurrent agent
# execution on the same feature.
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
CHECKPOINTS_DIR="$REPO_ROOT/.specify/checkpoints"

# Helper functions
log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS] <feature-id>

Resume a feature from its last checkpoint.

Arguments:
    feature-id     Feature directory name (e.g., 001-user-auth)

Options:
    -h, --help      Show this help message
    --unlock        Force-remove any stale lock file for this feature
    --status        Show checkpoint status without resuming

Examples:
    $(basename "$0") 001-user-auth
    $(basename "$0") --status 001-user-auth
    $(basename "$0") --unlock 001-user-auth

EOF
    exit 0
}

# Lock file management
acquire_lock() {
    local feature_id="$1"
    local lock_file="$CHECKPOINTS_DIR/${feature_id}.lock"
    
    if [[ -f "$lock_file" ]]; then
        local lock_pid lock_time lock_agent
        lock_pid=$(python3 -c "import json; print(json.load(open('$lock_file',encoding='utf-8-sig')).get('pid','unknown'))" 2>/dev/null || echo "unknown")
        lock_time=$(python3 -c "import json; print(json.load(open('$lock_file',encoding='utf-8-sig')).get('timestamp','unknown'))" 2>/dev/null || echo "unknown")
        lock_agent=$(python3 -c "import json; print(json.load(open('$lock_file',encoding='utf-8-sig')).get('agent','unknown'))" 2>/dev/null || echo "unknown")
        
        # Check if the locking process is still alive
        if [[ "$lock_pid" != "unknown" ]] && kill -0 "$lock_pid" 2>/dev/null; then
            log_error "Feature $feature_id is locked by agent '$lock_agent' (PID: $lock_pid, since: $lock_time)"
            log_error "Wait for it to finish, or use --unlock to force-remove the lock."
            return 1
        else
            log_warning "Found stale lock (PID $lock_pid no longer running). Removing."
            rm -f "$lock_file"
        fi
    fi
    
    mkdir -p "$CHECKPOINTS_DIR"
    echo "{\"pid\":$$,\"agent\":\"resume-feature\",\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" > "$lock_file"
    return 0
}

release_lock() {
    local feature_id="$1"
    rm -f "$CHECKPOINTS_DIR/${feature_id}.lock"
}

# Parse arguments
UNLOCK=false
STATUS_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help) usage ;;
        --unlock) UNLOCK=true; shift ;;
        --status) STATUS_ONLY=true; shift ;;
        -*) log_error "Unknown option: $1"; usage ;;
        *) FEATURE_ID="$1"; shift ;;
    esac
done

if [[ -z "${FEATURE_ID:-}" ]]; then
    log_error "Feature ID is required"
    usage
fi

FEATURE_DIR="$SPECS_DIR/$FEATURE_ID"
CHECKPOINT_FILE="$CHECKPOINTS_DIR/${FEATURE_ID}.checkpoint"
LOCK_FILE="$CHECKPOINTS_DIR/${FEATURE_ID}.lock"
META_FILE="$FEATURE_DIR/.feature-meta.json"

# Handle --unlock
if $UNLOCK; then
    if [[ -f "$LOCK_FILE" ]]; then
        rm -f "$LOCK_FILE"
        log_success "Lock removed for $FEATURE_ID"
    else
        log_info "No lock found for $FEATURE_ID"
    fi
    exit 0
fi

# Verify feature exists
if [[ ! -d "$FEATURE_DIR" ]]; then
    log_error "Feature directory not found: $FEATURE_DIR"
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🔄 Resume Feature: $FEATURE_ID"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Read ceremony level
CEREMONY_LEVEL="standard"
if [[ -f "$META_FILE" ]] && command -v python3 &>/dev/null; then
    CEREMONY_LEVEL=$(python3 -c "import json; print(json.load(open('$META_FILE',encoding='utf-8-sig')).get('ceremonyLevel','standard'))" 2>/dev/null || echo "standard")
fi
log_info "Ceremony level: $CEREMONY_LEVEL"

# Read checkpoint
if [[ -f "$CHECKPOINT_FILE" ]]; then
    LAST_GATE=$(python3 -c "import json; print(json.load(open('$CHECKPOINT_FILE',encoding='utf-8-sig')).get('gate',0))" 2>/dev/null || echo "0")
    LAST_TIME=$(python3 -c "import json; print(json.load(open('$CHECKPOINT_FILE',encoding='utf-8-sig')).get('timestamp','unknown'))" 2>/dev/null || echo "unknown")
    log_success "Last checkpoint: Gate $LAST_GATE passed at $LAST_TIME"
else
    LAST_GATE=0
    log_warning "No checkpoint found — feature has not passed any gate yet"
fi

# Determine next phase
echo ""
case $LAST_GATE in
    0)
        if [[ "$CEREMONY_LEVEL" == "ultra-light" ]]; then
            log_info "Next: Fill in spec.md, then @software-engineer (Planning)"
            NEXT_AGENT="@software-engineer (Planning mode)"
            NEXT_GATE="4"
        else
            log_info "Next: Phase 1 — Begin with @requirement-analyst"
            NEXT_AGENT="@requirement-analyst"
            NEXT_GATE="1"
        fi
        ;;
    1)
        log_info "Next: Phase 2 — Begin with @architect"
        NEXT_AGENT="@architect"
        NEXT_GATE="2"
        ;;
    2)
        log_info "Next: Phase 3 — Begin with @test-explorer"
        NEXT_AGENT="@test-explorer"
        NEXT_GATE="3"
        ;;
    3)
        log_info "Next: Phase 4 — Begin TDD with @test-engineer"
        NEXT_AGENT="@test-engineer"
        NEXT_GATE="4"
        ;;
    4)
        log_success "All gates passed! Feature is ready to ship."
        NEXT_AGENT="(none — ready to merge)"
        NEXT_GATE="(done)"
        ;;
esac

echo ""
echo "  📋 Summary:"
echo "     Feature:         $FEATURE_ID"
echo "     Ceremony:        $CEREMONY_LEVEL"
echo "     Last Gate:       $LAST_GATE"
echo "     Next Agent:      $NEXT_AGENT"
echo "     Next Gate:       $NEXT_GATE"

if $STATUS_ONLY; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    exit 0
fi

# Check lock
if [[ -f "$LOCK_FILE" ]]; then
    lock_pid=$(python3 -c "import json; print(json.load(open('$LOCK_FILE',encoding='utf-8-sig')).get('pid','unknown'))" 2>/dev/null || echo "unknown")
    if [[ "$lock_pid" != "unknown" ]] && kill -0 "$lock_pid" 2>/dev/null; then
        echo ""
        log_error "Feature is currently locked (active agent PID: $lock_pid)"
        log_error "Use --unlock to force-remove if the process is stale."
        exit 1
    else
        log_warning "Removing stale lock file"
        rm -f "$LOCK_FILE"
    fi
fi

echo ""
echo "  To continue, open VS Code Copilot Chat and type:"
echo ""
echo "     $NEXT_AGENT"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
