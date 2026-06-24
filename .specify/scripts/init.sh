#!/usr/bin/env bash
#
# init.sh - Quick initialize .specify structure
#
# Usage: ./init.sh
#
# Creates the full directory structure if not exists
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🏗️  Initializing .specify Structure"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Create directories
log_info "Creating directories..."
mkdir -p "$REPO_ROOT/.specify/memory"
mkdir -p "$REPO_ROOT/.specify/specs"
mkdir -p "$REPO_ROOT/.specify/templates"
mkdir -p "$REPO_ROOT/.specify/scripts"
mkdir -p "$REPO_ROOT/.specify/checkpoints"
mkdir -p "$REPO_ROOT/.specify/checkpoints/stuck-history"
mkdir -p "$REPO_ROOT/.specify/templates/setup"
mkdir -p "$REPO_ROOT/.github/agents"
mkdir -p "$REPO_ROOT/.github/skills"
mkdir -p "$REPO_ROOT/.specify/skills"
mkdir -p "$REPO_ROOT/.sdd-modules/modules"

log_success "Directory structure created"

# Create module registry if absent
if [[ ! -f "$REPO_ROOT/.sdd-modules/registry.json" ]]; then
    cat > "$REPO_ROOT/.sdd-modules/registry.json" << 'REGEOF'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "version": "1.0.0",
  "installedModules": []
}
REGEOF
    log_success "Created .sdd-modules/registry.json"
fi

if [[ ! -f "$REPO_ROOT/.sdd-modules/README.md" ]]; then
    cat > "$REPO_ROOT/.sdd-modules/README.md" << 'READMEEOF'
# SDD User Modules

User Modules add domain-specific technical knowledge to Enterprise SDD without
modifying core agents, gates, or scripts.

See `registry.json` for installed modules.

Commands: `sdd module install|remove|update|list`
READMEEOF
    log_success "Created .sdd-modules/README.md"
fi

# Create structured memory files if absent (Wave 8)
MEMORY_TARGET="$REPO_ROOT/.specify/memory"

create_memory_file() {
    local file="$MEMORY_TARGET/$1"
    [[ -f "$file" ]] && return
    cat > "$file" << 'MEMEOF'
$2
MEMEOF
    log_success "Created memory/$1"
}

if [[ ! -f "$MEMORY_TARGET/session-state.md" ]]; then
    cat > "$MEMORY_TARGET/session-state.md" << 'EOF'
# Session State

> **Auto-updated** by gate scripts and agents. Manual edits are allowed.

## Active Feature

- **Feature ID:** (none)
- **Feature Name:** (none)
- **Ceremony Level:** standard
- **Current Phase:** —
- **Last Gate Passed:** —
- **Last Gate Timestamp:** —

## Phase Progress

- [ ] Phase 0: Constitution
- [ ] Phase 1: Requirements (Gate 1)
- [ ] Phase 2: Design (Gate 2)
- [ ] Phase 3: Preparation (Gate 3)
- [ ] Phase 4: Implementation
- [ ] Phase 5: Quality Assurance (Gate 4)

## Current Agent

- **Active:** (none)
- **Mode:** —

## Key Decisions (This Feature)

- (none yet)

## Files Modified (This Session)

- (none yet)

## Next Step

- Initialize a feature with `sdd new "feature name"`
EOF
    log_success "Created memory/session-state.md"
fi

if [[ ! -f "$MEMORY_TARGET/decisions.md" ]]; then
    cat > "$MEMORY_TARGET/decisions.md" << 'EOF'
# Decisions Log

> **Project-wide** architectural and design decisions with rationale.
> Agents append entries when significant decisions are made.

---

## Decisions

<!-- Append new decisions below this line -->
EOF
    log_success "Created memory/decisions.md"
fi

if [[ ! -f "$MEMORY_TARGET/lessons.md" ]]; then
    cat > "$MEMORY_TARGET/lessons.md" << 'EOF'
# Lessons Learned

> **Project-wide** record of what worked and what didn't.
> Agents append entries after corrections, stuck detection, or failed gates.

---

## Lessons

<!-- Append new lessons below this line -->
EOF
    log_success "Created memory/lessons.md"
fi

if [[ ! -f "$MEMORY_TARGET/research-cache.md" ]]; then
    cat > "$MEMORY_TARGET/research-cache.md" << 'EOF'
# Research Cache

> **Project-wide** cache of external research findings.
> Entries expire after 7 days by default.

---

## Cache

<!-- Append new research entries below this line -->
EOF
    log_success "Created memory/research-cache.md"
fi

if [[ ! -f "$MEMORY_TARGET/metrics-log.md" ]]; then
    cat > "$MEMORY_TARGET/metrics-log.md" << 'EOF'
# Metrics Log

> **Project-wide** gate pass/fail history.
> Auto-updated by `validate-gate.sh` / `.ps1` after each gate run.

---

| Date | Feature | Gate | Ceremony | Result | Errors | Warnings | Duration | Notes |
|------|---------|------|----------|--------|--------|----------|----------|-------|

<!-- Gate results are appended automatically by validate-gate scripts -->
EOF
    log_success "Created memory/metrics-log.md"
fi

if [[ ! -f "$MEMORY_TARGET/memory-index.md" ]]; then
    cat > "$MEMORY_TARGET/memory-index.md" << 'EOF'
# Memory Index

> Feature-scoped memory map generated and refreshed by `memory-index.sh`.

## Core Memory Files

- constitution: .specify/memory/constitution.md
- session-state: .specify/memory/session-state.md
- decisions: .specify/memory/decisions.md
- lessons: .specify/memory/lessons.md
- research-cache: .specify/memory/research-cache.md
- metrics-log: .specify/memory/metrics-log.md

## Feature Artifacts

- feature-dir: .specify/specs/<feature-id>/
- spec: .specify/specs/<feature-id>/spec.md
- plan: .specify/specs/<feature-id>/plan.md
- tasks: .specify/specs/<feature-id>/tasks.md
- tests: .specify/specs/<feature-id>/test-cases.md
- analysis: .specify/specs/<feature-id>/analysis-report.md

EOF
    log_success "Created memory/memory-index.md"
fi

# Make scripts executable
log_info "Making scripts executable..."
chmod +x "$REPO_ROOT/.specify/scripts/"*.sh 2>/dev/null || true

log_success "Scripts are executable"

# Check for templates
if [[ -z "$(ls -A "$REPO_ROOT/.specify/templates" 2>/dev/null)" ]]; then
    echo ""
    echo -e "${BLUE}ℹ️  Templates directory is empty${NC}"
    echo "  Copy templates from the spec-kit repository or create your own."
fi

# Check for agents
if [[ -z "$(ls -A "$REPO_ROOT/.github/agents" 2>/dev/null)" ]]; then
    echo ""
    echo -e "${BLUE}ℹ️  Agents directory is empty${NC}"
    echo "  Copy agent files from the spec-kit repository."
fi

# Check for constitution
if [[ ! -f "$REPO_ROOT/.specify/memory/constitution.md" ]]; then
    echo ""
    echo -e "${BLUE}ℹ️  No constitution found${NC}"
    echo "  Run the Constitution Agent to establish project principles."
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_success "Initialization complete!"
echo ""
echo "  Directory structure:"
echo "  .specify/"
echo "  ├── memory/          # Project-wide context"
echo "  │   ├── constitution.md    # Project principles and standards"
echo "  │   ├── session-state.md   # Current feature + phase status"
echo "  │   ├── decisions.md       # Architectural decisions with rationale"
echo "  │   ├── lessons.md         # Lessons learned across features"
echo "  │   ├── research-cache.md  # Cached research findings"
echo "  │   ├── metrics-log.md     # Gate pass/fail history"
echo "  │   └── memory-index.md    # Feature memory map and freshness anchor"
echo "  ├── specs/           # Feature specifications"
echo "  ├── templates/       # Artifact templates"
echo "  │   └── setup/           # Project setup templates"
echo "  ├── skills/          # Local skill descriptors"
echo "  ├── scripts/         # Automation scripts"
echo "  └── checkpoints/     # Gate checkpoint files"
echo "      └── stuck-history/  # Artifact checksums for stuck detection"
echo ""
echo "  .github/"
echo "  ├── agents/          # Agent definitions"
echo "  └── skills/          # Curated SKILL packs"
echo ""
echo "  .sdd-modules/"
echo "  ├── registry.json    # Installed module tracking"
echo "  ├── README.md        # Module system documentation"
echo "  └── modules/         # Module packages (populated by installs)"
echo ""
echo "  Next steps:"
echo "  1. Set up templates in .specify/templates/"
echo "  2. Create constitution with @constitution agent"
echo "  3. Start a feature: ./new-feature.sh \"feature name\""
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
