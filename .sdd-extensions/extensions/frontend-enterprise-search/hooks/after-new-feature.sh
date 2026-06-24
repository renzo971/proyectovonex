#!/usr/bin/env bash
# Hook: after-new-feature for frontend-enterprise-search
# Reminds about search-specific patterns when a new feature is created

set -euo pipefail

FEATURE_ID="${1:-}"

if [[ -z "$FEATURE_ID" ]]; then
  echo "[frontend-enterprise-search] after-new-feature: no feature ID provided, skipping"
  exit 0
fi

echo "[frontend-enterprise-search] Search pattern guidance for feature: $FEATURE_ID"
echo "  Active search instructions:"
echo "  - fe-advanced-search-form: Multi-section form with handleChange contract"
echo "  - fe-advanced-search-results: Paginated table with chips and export"
echo "  - fe-item-status-badge: Feature-scoped status badge pattern"
echo "  Ensure: frontend-stratos-core pack is also installed (required base)."
echo "[frontend-enterprise-search] Hook complete."
