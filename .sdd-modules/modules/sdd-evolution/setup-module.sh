#!/usr/bin/env bash
# setup-module.sh — Post-install hook for sdd-evolution module
# Creates the _evolution/ directory structure for framework analysis artifacts.

set -euo pipefail

# Resolve project root (where .sdd-modules/ lives)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

EVOLUTION_DIR="$PROJECT_ROOT/_evolution"

echo "🔧 sdd-evolution: Setting up _evolution/ directory..."

mkdir -p "$EVOLUTION_DIR"

# Create placeholder files if they don't exist
if [[ ! -f "$EVOLUTION_DIR/EVOLUTION.md" ]]; then
  cat > "$EVOLUTION_DIR/EVOLUTION.md" << 'EOF'
# Enterprise SDD Evolution — Feature Harvest Document

> **Last updated:** $(date +%Y-%m-%d)

This document tracks feature harvests from public AI agent frameworks.
Each numbered section represents a harvest cycle.

---
EOF
  echo "  ✅ Created EVOLUTION.md"
fi

if [[ ! -f "$EVOLUTION_DIR/WHATSNEW.md" ]]; then
  cat > "$EVOLUTION_DIR/WHATSNEW.md" << 'EOF'
# Framework Updates — What's New

> Per-framework changelog updated at each refresh cycle.

---
EOF
  echo "  ✅ Created WHATSNEW.md"
fi

echo "✅ sdd-evolution: Setup complete. _evolution/ directory ready."
echo "   Path: $EVOLUTION_DIR"
