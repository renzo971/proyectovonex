#!/usr/bin/env bash
#
# gate-post-merge.sh — Post-merge integration verification gate (Wave 20 §20.B.8/B.9)
#
# Runs the configured `build_command` and `test_command` from
# `.specify/config.yaml` against the post-merge tree. Captures stdout/stderr
# into `.specify/specs/<feature>/POST-MERGE.md`. On failure, also writes
# `.specify/specs/<feature>/INCIDENT.md` with the failing output. **Never
# auto-reverts** — `sdd ship --rollback` and the operator's VCS tooling remain
# the only revert mechanisms.
#
# Usage: ./gate-post-merge.sh <feature-id>

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SPECS_DIR="$REPO_ROOT/.specify/specs"
CONFIG_FILE="$REPO_ROOT/.specify/config.yaml"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}" >&2; }

FEATURE_ID="${1:-}"
if [[ -z "$FEATURE_ID" ]]; then
    log_error "Usage: $(basename "$0") <feature-id>"
    exit 2
fi

FEATURE_DIR="$SPECS_DIR/$FEATURE_ID"
if [[ ! -d "$FEATURE_DIR" ]]; then
    log_error "Feature workspace not found: $FEATURE_DIR"
    exit 2
fi

# Read build_command / test_command from .specify/config.yaml (or .json)
BUILD_CMD=""
TEST_CMD=""
if [[ -f "$CONFIG_FILE" ]]; then
    BUILD_CMD=$(python3 -c "
import sys
try:
    import yaml
except Exception:
    sys.exit(0)
try:
    cfg = yaml.safe_load(open('$CONFIG_FILE', encoding='utf-8')) or {}
    print(cfg.get('build_command', '') or '')
except Exception:
    pass
" 2>/dev/null)
    TEST_CMD=$(python3 -c "
import sys
try:
    import yaml
except Exception:
    sys.exit(0)
try:
    cfg = yaml.safe_load(open('$CONFIG_FILE', encoding='utf-8')) or {}
    print(cfg.get('test_command', '') or '')
except Exception:
    pass
" 2>/dev/null)
fi

if [[ -z "$BUILD_CMD" && -z "$TEST_CMD" ]]; then
    log_error "Neither build_command nor test_command is set in $CONFIG_FILE."
    log_error "Add at least one of:"
    log_error "  build_command: <shell command>"
    log_error "  test_command: <shell command>"
    exit 2
fi

POST_MERGE_FILE="$FEATURE_DIR/POST-MERGE.md"
INCIDENT_FILE="$FEATURE_DIR/INCIDENT.md"
TIMESTAMP="$(date -u '+%Y-%m-%d %H:%M:%S UTC')"

log_info "Running post-merge verification for $FEATURE_ID"
log_info "  build_command: ${BUILD_CMD:-<unset>}"
log_info "  test_command:  ${TEST_CMD:-<unset>}"

BUILD_LOG="$(mktemp)"
TEST_LOG="$(mktemp)"
BUILD_RC=0
TEST_RC=0

if [[ -n "$BUILD_CMD" ]]; then
    log_info "Running build_command…"
    bash -c "$BUILD_CMD" >"$BUILD_LOG" 2>&1
    BUILD_RC=$?
    log_info "build_command exited with $BUILD_RC"
fi

if [[ -n "$TEST_CMD" ]]; then
    log_info "Running test_command…"
    bash -c "$TEST_CMD" >"$TEST_LOG" 2>&1
    TEST_RC=$?
    log_info "test_command exited with $TEST_RC"
fi

VERDICT="PASS"
if [[ $BUILD_RC -ne 0 || $TEST_RC -ne 0 ]]; then
    VERDICT="FAIL"
fi

cat > "$POST_MERGE_FILE" << EOF
# Post-Merge Verification — $FEATURE_ID

> **Generated:** $TIMESTAMP
> **Verdict:** $VERDICT

## Configuration
- \`build_command\`: \`${BUILD_CMD:-<unset>}\`
- \`test_command\`:  \`${TEST_CMD:-<unset>}\`

## Build Output (exit $BUILD_RC)

\`\`\`
$(cat "$BUILD_LOG" 2>/dev/null | tail -200)
\`\`\`

## Test Output (exit $TEST_RC)

\`\`\`
$(cat "$TEST_LOG" 2>/dev/null | tail -200)
\`\`\`
EOF
log_success "Wrote $POST_MERGE_FILE"

if [[ "$VERDICT" == "FAIL" ]]; then
    cat > "$INCIDENT_FILE" << EOF
# Incident — Post-Merge Verification Failed for $FEATURE_ID

> **Generated:** $TIMESTAMP
> **Status:** OPEN
> **Owner:** <assign>

## Failing Commands

EOF
    if [[ $BUILD_RC -ne 0 ]]; then
        echo "- \`build_command\` (\`$BUILD_CMD\`) exited with $BUILD_RC" >> "$INCIDENT_FILE"
    fi
    if [[ $TEST_RC -ne 0 ]]; then
        echo "- \`test_command\` (\`$TEST_CMD\`) exited with $TEST_RC" >> "$INCIDENT_FILE"
    fi
    {
        echo ""
        echo "## Captured Output"
        echo ""
        if [[ $BUILD_RC -ne 0 ]]; then
            echo "### build_command"
            echo ""
            echo '```'
            tail -200 "$BUILD_LOG" 2>/dev/null
            echo '```'
            echo ""
        fi
        if [[ $TEST_RC -ne 0 ]]; then
            echo "### test_command"
            echo ""
            echo '```'
            tail -200 "$TEST_LOG" 2>/dev/null
            echo '```'
        fi
        echo ""
        echo "## Resolution"
        echo ""
        echo "> Investigate the failing command(s) above. This artifact does NOT auto-revert the merge."
        echo "> Use \`sdd ship --rollback\` (when available) or your VCS tooling to revert if required."
    } >> "$INCIDENT_FILE"
    log_warning "Wrote $INCIDENT_FILE"
fi

rm -f "$BUILD_LOG" "$TEST_LOG"

if [[ "$VERDICT" == "PASS" ]]; then
    log_success "Post-merge verification PASSED for $FEATURE_ID"
    exit 0
fi
log_error "Post-merge verification FAILED for $FEATURE_ID"
exit 1
