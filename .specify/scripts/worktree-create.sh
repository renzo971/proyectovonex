#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

FEATURE_ID="${1:-}"
if [[ -z "$FEATURE_ID" ]]; then
    echo "Usage: $(basename "$0") <feature-id>" >&2
    exit 1
fi

WORKTREE_ROOT="$REPO_ROOT/.sdd/worktrees"
WORKTREE_PATH="$WORKTREE_ROOT/$FEATURE_ID"
BRANCH_NAME="feature/$FEATURE_ID"

if ! git -C "$REPO_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Not a git repository: $REPO_ROOT" >&2
    exit 1
fi

mkdir -p "$WORKTREE_ROOT"

if [[ -d "$WORKTREE_PATH" ]]; then
    echo "Worktree already exists: $WORKTREE_PATH"
    exit 0
fi

if git -C "$REPO_ROOT" show-ref --verify --quiet "refs/heads/$BRANCH_NAME"; then
    git -C "$REPO_ROOT" worktree add "$WORKTREE_PATH" "$BRANCH_NAME"
else
    git -C "$REPO_ROOT" worktree add "$WORKTREE_PATH" -b "$BRANCH_NAME"
fi

# Copy feature specs into the worktree
SPECS_SRC="$REPO_ROOT/.specify/specs/$FEATURE_ID"
if [[ -d "$SPECS_SRC" ]]; then
    SPECS_DST="$WORKTREE_PATH/.specify/specs/$FEATURE_ID"
    mkdir -p "$SPECS_DST"
    cp -r "$SPECS_SRC/"* "$SPECS_DST/" 2>/dev/null || true
    echo "Copied feature specs to worktree"
fi

echo "Created worktree: $WORKTREE_PATH"
echo "Branch: $BRANCH_NAME"
