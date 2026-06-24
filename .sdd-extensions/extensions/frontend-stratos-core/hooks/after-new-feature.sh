#!/usr/bin/env bash
# Hook: after-new-feature for frontend-stratos-core
# Validates that the new feature follows the expected MFE folder structure

set -euo pipefail

FEATURE_ID="${1:-}"
SPEC_DIR="${2:-.specify/specs/$FEATURE_ID}"

if [[ -z "$FEATURE_ID" ]]; then
  echo "[frontend-stratos-core] after-new-feature: no feature ID provided, skipping"
  exit 0
fi

echo "[frontend-stratos-core] Validating FE structure for feature: $FEATURE_ID"

# Check that the feature spec exists
if [[ ! -d "$SPEC_DIR" ]]; then
  echo "[frontend-stratos-core] Warning: spec directory $SPEC_DIR not found"
  exit 0
fi

# Remind operator about FE extension instructions
echo "[frontend-stratos-core] Reminder: the following instructions are active:"
echo "  - fe-stratos-design-tokens: Use Stratos Space/Color/Breakpoint tokens"
echo "  - fe-component-ambiguity-resolution: Record UI ambiguities in decisions.md"
echo "  - fe-frontend-architecture-mfe: Follow MFE folder structure"
echo "  - fe-frontend-state-decision-tree: Document state location decisions"
echo "[frontend-stratos-core] Hook complete."
