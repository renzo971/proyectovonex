#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
SANDBOX_PARENT="$(mktemp -d)"
SANDBOX_ROOT="$SANDBOX_PARENT/enterprise-sdd-sandbox"

cleanup() {
  rm -rf "$SANDBOX_PARENT"
}
trap cleanup EXIT

cp -a "$REPO_ROOT/." "$SANDBOX_ROOT"

"$SCRIPT_DIR/test-std-fe-module.sh" "$SANDBOX_ROOT"
"$SCRIPT_DIR/test-aws-fe-module.sh" "$SANDBOX_ROOT"

echo "PASS all module sandbox tests"
