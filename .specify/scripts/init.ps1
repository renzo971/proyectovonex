#Requires -Version 5.1
<#
.SYNOPSIS
    Initialize .specify structure.
.DESCRIPTION
    Creates the full directory structure for the enterprise SDD workflow.
.EXAMPLE
    .\init.ps1
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = (Resolve-Path (Join-Path $ScriptDir '..\..\')).Path

function Write-Info  { param([string]$Msg) Write-Host "ℹ️  $Msg" -ForegroundColor Blue }
function Write-Ok    { param([string]$Msg) Write-Host "✅ $Msg" -ForegroundColor Green }

Write-Host ''
Write-Host '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
Write-Host '  🏗️  Initializing .specify Structure'
Write-Host '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
Write-Host ''

Write-Info 'Creating directories...'
$dirs = @(
    '.specify\memory',
    '.specify\specs',
    '.specify\templates',
    '.specify\scripts',
    '.specify\checkpoints',
    '.specify\checkpoints\stuck-history',
    '.specify\templates\setup',
    '.specify\skills',
    '.github\agents',
    '.github\skills',
    '.sdd-modules\modules'
)
foreach ($d in $dirs) {
    $full = Join-Path $RepoRoot $d
    if (-not (Test-Path $full)) { New-Item -ItemType Directory -Path $full -Force | Out-Null }
}
Write-Ok 'Directory structure created'

# Create module registry if absent
$ModuleRegistryPath = Join-Path $RepoRoot '.sdd-modules\registry.json'
if (-not (Test-Path $ModuleRegistryPath)) {
    $RegistryContent = @'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "version": "1.0.0",
  "installedModules": []
}
'@
    Set-Content -Path $ModuleRegistryPath -Value $RegistryContent -Encoding UTF8 -NoNewline
    Write-Ok 'Created .sdd-modules/registry.json'
}

$ModuleReadmePath = Join-Path $RepoRoot '.sdd-modules\README.md'
if (-not (Test-Path $ModuleReadmePath)) {
    $ReadmeContent = @'
# SDD User Modules

User Modules add domain-specific technical knowledge to Enterprise SDD without
modifying core agents, gates, or scripts.

See `registry.json` for installed modules.

Commands: `sdd module install|remove|update|list`
'@
    Set-Content -Path $ModuleReadmePath -Value $ReadmeContent -Encoding UTF8 -NoNewline
    Write-Ok 'Created .sdd-modules/README.md'
}

# Create structured memory files if absent (Wave 8)
$MemoryTarget = Join-Path $RepoRoot '.specify\memory'

$memoryDefaults = @{
    'session-state.md' = @'
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
'@
    'decisions.md' = @'
# Decisions Log

> **Project-wide** architectural and design decisions with rationale.
> Agents append entries when significant decisions are made.

---

## Decisions

<!-- Append new decisions below this line -->
'@
    'lessons.md' = @'
# Lessons Learned

> **Project-wide** record of what worked and what didn't.
> Agents append entries after corrections, stuck detection, or failed gates.

---

## Lessons

<!-- Append new lessons below this line -->
'@
    'research-cache.md' = @'
# Research Cache

> **Project-wide** cache of external research findings.
> Entries expire after 7 days by default.

---

## Cache

<!-- Append new research entries below this line -->
'@
    'metrics-log.md' = @'
# Metrics Log

> **Project-wide** gate pass/fail history.
> Auto-updated by `validate-gate.sh` / `.ps1` after each gate run.

---

| Date | Feature | Gate | Ceremony | Result | Errors | Warnings | Duration | Notes |
|------|---------|------|----------|--------|--------|----------|----------|-------|

<!-- Gate results are appended automatically by validate-gate scripts -->
'@
    'memory-index.md' = @'
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
'@
}

foreach ($entry in $memoryDefaults.GetEnumerator()) {
    $target = Join-Path $MemoryTarget $entry.Key
    if (-not (Test-Path $target)) {
        Set-Content -Path $target -Value $entry.Value -Encoding UTF8 -NoNewline
        Write-Ok "Created memory/$($entry.Key)"
    }
}

# Check for templates
$templatesDir = Join-Path $RepoRoot '.specify\templates'
if (-not (Get-ChildItem $templatesDir -ErrorAction SilentlyContinue | Select-Object -First 1)) {
    Write-Host ''
    Write-Info 'Templates directory is empty'
    Write-Host '  Copy templates from the spec-kit repository or create your own.'
}

# Check for agents
$agentsDir = Join-Path $RepoRoot '.github\agents'
if (-not (Get-ChildItem $agentsDir -ErrorAction SilentlyContinue | Select-Object -First 1)) {
    Write-Host ''
    Write-Info 'Agents directory is empty'
    Write-Host '  Copy agent files from the spec-kit repository.'
}

# Check for constitution
$constitution = Join-Path $RepoRoot '.specify\memory\constitution.md'
if (-not (Test-Path $constitution)) {
    Write-Host ''
    Write-Info 'No constitution found'
    Write-Host '  Run the Constitution Agent to establish project principles.'
}

Write-Host ''
Write-Host '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
Write-Ok 'Initialization complete!'
Write-Host ''
Write-Host '  Directory structure:'
Write-Host '  .specify/'
Write-Host '  ├── memory/          # Project-wide context'
Write-Host '  │   ├── constitution.md    # Project principles and standards'
Write-Host '  │   ├── session-state.md   # Current feature + phase status'
Write-Host '  │   ├── decisions.md       # Architectural decisions with rationale'
Write-Host '  │   ├── lessons.md         # Lessons learned across features'
Write-Host '  │   ├── research-cache.md  # Cached research findings'
Write-Host '  │   ├── metrics-log.md     # Gate pass/fail history'
Write-Host '  │   └── memory-index.md    # Feature memory map and freshness anchor'
Write-Host '  ├── specs/           # Feature specifications'
Write-Host '  ├── templates/       # Artifact templates'
Write-Host '  │   └── setup/           # Project setup templates'
Write-Host '  ├── skills/          # Local skill descriptors'
Write-Host '  ├── scripts/         # Automation scripts'
Write-Host '  └── checkpoints/     # Gate checkpoint files'
Write-Host '      └── stuck-history/  # Artifact checksums for stuck detection'
Write-Host ''
Write-Host '  .github/'
Write-Host '  ├── agents/          # Agent definitions'
Write-Host '  └── skills/          # Curated SKILL packs'
Write-Host ''
Write-Host '  .sdd-modules/'
Write-Host '  ├── registry.json    # Installed module tracking'
Write-Host '  ├── README.md        # Module system documentation'
Write-Host '  └── modules/         # Module packages (populated by installs)'
Write-Host ''
Write-Host '  Next steps:'
Write-Host '  1. Set up templates in .specify/templates/'
Write-Host '  2. Create constitution with @constitution agent'
Write-Host '  3. Start a feature: .\new-feature.ps1 "feature name"'
Write-Host ''
Write-Host '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
