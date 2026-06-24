#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
MEMORY_DIR="$REPO_ROOT/.specify/memory"
SPECS_DIR="$REPO_ROOT/.specify/specs"

FEATURE_ID="${1:-}"
if [[ -z "$FEATURE_ID" ]]; then
    echo "Usage: $(basename "$0") <feature-id>" >&2
    exit 2
fi

FEATURE_DIR="$SPECS_DIR/$FEATURE_ID"
if [[ ! -d "$FEATURE_DIR" ]]; then
    echo "Feature not found: $FEATURE_ID" >&2
    exit 1
fi

INDEX_FILE="$MEMORY_DIR/memory-index.md"
NOW_UTC="$(date -u +"%Y-%m-%d %H:%M:%S UTC")"

cat > "$INDEX_FILE" << EOF
# Memory Index

Last Updated: $NOW_UTC
Feature Context: $FEATURE_ID

## Core Memory Files

- constitution: .specify/memory/constitution.md
- session-state: .specify/memory/session-state.md
- decisions: .specify/memory/decisions.md
- lessons: .specify/memory/lessons.md
- research-cache: .specify/memory/research-cache.md
- metrics-log: .specify/memory/metrics-log.md

## Feature Artifacts

- feature-dir: .specify/specs/$FEATURE_ID/
- spec: .specify/specs/$FEATURE_ID/spec.md
- plan: .specify/specs/$FEATURE_ID/plan.md
- tasks: .specify/specs/$FEATURE_ID/tasks.md
- tests: .specify/specs/$FEATURE_ID/test-cases.md
- analysis: .specify/specs/$FEATURE_ID/analysis-report.md

## Freshness Policy

- stale-threshold-days: 30
- recommended-sync-before-gate: true

EOF

echo "Memory index updated: $INDEX_FILE"
