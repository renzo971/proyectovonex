#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

FEATURE_ID="${1:-}"
if [[ -z "$FEATURE_ID" ]]; then
    echo "Usage: $(basename "$0") <feature-id> [--base <branch>]" >&2
    exit 1
fi
shift || true

BASE_BRANCH=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --base)
            BASE_BRANCH="${2:-}"
            shift 2
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

if [[ -z "$BASE_BRANCH" ]]; then
    BASE_BRANCH=$(git -C "$REPO_ROOT" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##' || true)
    BASE_BRANCH="${BASE_BRANCH:-main}"
fi

BRANCH_NAME="feature/$FEATURE_ID"
WORKTREE_PATH="$REPO_ROOT/.sdd/worktrees/$FEATURE_ID"
OPERATIONAL_PATHS=(
    ".specify/memory/session-state.md"
    ".specify/memory/metrics-log.md"
    ".specify/checkpoints"
)

if ! git -C "$REPO_ROOT" show-ref --verify --quiet "refs/heads/$BRANCH_NAME"; then
    echo "Feature branch not found: $BRANCH_NAME" >&2
    exit 1
fi

if [[ -n "$(git -C "$REPO_ROOT" status --porcelain -- . ':(exclude).sdd/worktrees')" ]]; then
    echo "Repository has uncommitted changes. Commit or stash before shipping." >&2
    exit 1
fi

git -C "$REPO_ROOT" checkout "$BASE_BRANCH"
merge_rc=0
git -C "$REPO_ROOT" merge --squash "$BRANCH_NAME" || merge_rc=$?

for path in "${OPERATIONAL_PATHS[@]}"; do
    git -C "$REPO_ROOT" restore --source="$BASE_BRANCH" --staged --worktree -- "$path" 2>/dev/null || true
done

unmerged=$(git -C "$REPO_ROOT" diff --name-only --diff-filter=U)
if [[ -n "$unmerged" ]]; then
    echo "Unresolved merge conflicts after squash merge:" >&2
    echo "$unmerged" >&2
    exit 1
fi

git -C "$REPO_ROOT" commit -m "feat: ship $FEATURE_ID"

if [[ -d "$WORKTREE_PATH" ]]; then
    git -C "$REPO_ROOT" worktree remove "$WORKTREE_PATH"
fi

git -C "$REPO_ROOT" branch -D "$BRANCH_NAME"

echo "Shipped $FEATURE_ID into $BASE_BRANCH"
echo "Removed worktree: $WORKTREE_PATH"
echo "Deleted branch: $BRANCH_NAME"
