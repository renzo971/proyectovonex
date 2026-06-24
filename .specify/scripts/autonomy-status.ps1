# ─────────────────────────────────────────────────────────────────
# autonomy-status.ps1 — Show autonomy execution status for a feature
# Wave 11 · Phase J · Enterprise SDD
# ─────────────────────────────────────────────────────────────────
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$FeatureId
)

$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot  = if ($env:SDD_REPO_ROOT) { $env:SDD_REPO_ROOT } else { Resolve-Path (Join-Path $ScriptDir '../..') }

# ── Helpers ──────────────────────────────────────────────────────
function Write-Info  { param([string]$m) Write-Host "ℹ $m" -ForegroundColor Cyan }
function Write-Ok    { param([string]$m) Write-Host "✔ $m" -ForegroundColor Green }
function Write-Warn2 { param([string]$m) Write-Host "⚠ $m" -ForegroundColor Yellow }
function Write-Err2  { param([string]$m) Write-Host "✘ $m" -ForegroundColor Red }
function Write-Header{ param([string]$m) Write-Host "`n$m" -ForegroundColor White -NoNewline; Write-Host '' }

# ── Resolve feature directory ────────────────────────────────────
if ($FeatureId) {
    $FeatureDir = Join-Path $RepoRoot ".specify/specs/$FeatureId"
} elseif (Test-Path '.feature-meta.json') {
    $FeatureDir = (Get-Location).Path
    $FeatureId  = Split-Path -Leaf $FeatureDir
} elseif (Test-Path (Join-Path $RepoRoot '.specify/active-feature')) {
    $FeatureId  = Get-Content (Join-Path $RepoRoot '.specify/active-feature') -Raw
    $FeatureId  = $FeatureId.Trim()
    $FeatureDir = Join-Path $RepoRoot ".specify/specs/$FeatureId"
} else {
    Write-Err2 'No feature-id provided and no active feature detected.'
    Write-Host 'Usage: sdd autonomy status [feature-id]'
    exit 2
}

$MetaFile = Join-Path $FeatureDir '.feature-meta.json'

if (-not (Test-Path $FeatureDir)) {
    Write-Err2 "Feature directory not found: $FeatureDir"
    exit 2
}
if (-not (Test-Path $MetaFile)) {
    Write-Err2 "No .feature-meta.json in $FeatureDir"
    exit 2
}

$EvidenceScript = Join-Path $ScriptDir 'autonomy-evidence.py'
if (Test-Path $EvidenceScript) {
    # Idempotent sync: writes per-cycle artifacts and refreshes autonomy-progress.md
    try {
        & python3 $EvidenceScript sync --repo-root $RepoRoot --feature-id $FeatureId --format json *> $null
    } catch {
        # Non-fatal: status should still render base metadata
    }
}

# ── Read metadata ────────────────────────────────────────────────
function Get-MetaField2 {
    param([string]$Field, [string]$Default = '')
    try {
        $meta = Get-Content $MetaFile -Raw | ConvertFrom-Json
        $val = $meta.$Field
        if ($null -eq $val) { return $Default }
        return [string]$val
    } catch { return $Default }
}

$ExecMode    = Get-MetaField2 'executionMode' 'standard'
$Budget      = [int](Get-MetaField2 'autonomyBudget' '0')
$MaxIter     = Get-MetaField2 'autonomyMaxIterations' '3'
$Escalation  = Get-MetaField2 'escalationThreshold' '3'
$ItemLimit   = Get-MetaField2 'autonomyItemLimit' '1'
$CtxReset    = Get-MetaField2 'autonomyContextReset' 'required-per-item'
$Persistence = Get-MetaField2 'autonomyPersistenceRequired' 'true'
$Fallback    = Get-MetaField2 'fallbackExecutionMode' 'standard'
$LastStatus  = Get-MetaField2 'lastAutonomyStatus' 'idle'

# ── Count cycles ─────────────────────────────────────────────────
$TodoFile = Join-Path $FeatureDir 'todo.md'
$CyclesConsumed = 0
if (Test-Path $TodoFile) {
    $CyclesConsumed = ([regex]::Matches((Get-Content $TodoFile -Raw), '## Cycle \d+')).Count
}

# ── Display ──────────────────────────────────────────────────────
Write-Header "🤖 Autonomy Status: $FeatureId"
Write-Host ''
Write-Host ("  {0,-28} {1}" -f 'Execution Mode:', $ExecMode)
Write-Host ("  {0,-28} {1}" -f 'Last Status:', $LastStatus)
Write-Host ''

if ($ExecMode -eq 'standard') {
    Write-Info 'Feature is in standard (human-driven) mode. No autonomy metrics to display.'
    exit 0
}

$verdictStatus = 'retry'
$verdictConfidence = '0.00'
$verdictRepairHint = ''
$currentCycle = '0'
$nextAction = 'Start first autonomous cycle and record evidence.'
$blocker = 'none'
$cycleCount = '0'
$ledgerPath = Join-Path $FeatureDir 'autonomy-progress.md'

if (Test-Path $EvidenceScript) {
    try {
        $summaryRaw = & python3 $EvidenceScript summary --repo-root $RepoRoot --feature-id $FeatureId --format text
        if ($summaryRaw) {
            $parts = ($summaryRaw -join "") -split '\|', 8
            if ($parts.Count -ge 8) {
                $verdictStatus = $parts[0]
                $verdictConfidence = $parts[1]
                $verdictRepairHint = $parts[2]
                $currentCycle = $parts[3]
                $nextAction = $parts[4]
                $blocker = $parts[5]
                $cycleCount = $parts[6]
                $ledgerPath = $parts[7]
            }
        }
    } catch {
        # Keep defaults if summary extraction fails
    }
}

Write-Header '📊 Budget & Limits'
Write-Host ("  {0,-28} {1}" -f 'Autonomy Budget:', "$Budget cycles")
Write-Host ("  {0,-28} {1}" -f 'Cycles Consumed:', $CyclesConsumed)

if ($Budget -gt 0) {
    $Remaining = $Budget - $CyclesConsumed
    if ($Remaining -le 0)     { Write-Err2 "Budget EXHAUSTED ($CyclesConsumed/$Budget)" }
    elseif ($Remaining -le 2) { Write-Warn2 "Budget almost exhausted: $Remaining cycle(s) remaining" }
    else                      { Write-Ok "Budget healthy: $Remaining cycle(s) remaining" }
} else {
    Write-Info 'No budget cap set'
}

Write-Host ("  {0,-28} {1}" -f 'Max Iterations/Cycle:', $MaxIter)
Write-Host ("  {0,-28} {1}" -f 'Escalation Threshold:', $Escalation)
Write-Host ("  {0,-28} {1}" -f 'Item Limit/Cycle:', $ItemLimit)
Write-Host ''

Write-Header '🧪 Structured Verdict'
Write-Host ("  {0,-28} {1}" -f 'Verdict status:', $verdictStatus)
Write-Host ("  {0,-28} {1}" -f 'Confidence:', $verdictConfidence)
Write-Host ("  {0,-28} {1}" -f 'Repair hint:', $(if ($verdictRepairHint) { $verdictRepairHint } else { '-' }))
Write-Host ("  {0,-28} {1}" -f 'Current cycle:', $currentCycle)
Write-Host ("  {0,-28} {1}" -f 'Cycle count:', $cycleCount)
Write-Host ("  {0,-28} {1}" -f 'Blocker:', $blocker)
Write-Host ("  {0,-28} {1}" -f 'Next action:', $nextAction)
Write-Host ("  {0,-28} {1}" -f 'Progress ledger:', $ledgerPath)
Write-Host ''

Write-Header '⚙ Configuration'
Write-Host ("  {0,-28} {1}" -f 'Context Reset:', $CtxReset)
Write-Host ("  {0,-28} {1}" -f 'Persistence Required:', $Persistence)
Write-Host ("  {0,-28} {1}" -f 'Fallback Mode:', $Fallback)
Write-Host ''

# ── Provenance summary ───────────────────────────────────────────
if (Test-Path $TodoFile) {
    Write-Header '📋 Provenance Summary'
    $content = Get-Content $TodoFile -Raw

    if ($content -match '(?i)(rationale|reason)\\*?\\*?:')                                    { Write-Ok 'Rationale present' }   else { Write-Warn2 'No rationale found' }
    if ($content -match '(?i)confidence.*score.*[1-5]|confidence.*[1-5]/5')            { Write-Ok 'Confidence scores' }   else { Write-Warn2 'No confidence scores' }
    if ($content -match '(?i)risk.*classification.*:\s*\b(low|medium|high|critical)\b') { Write-Ok 'Risk classification' } else { Write-Warn2 'No risk classification' }
    if ($content -match '(?i)touched.*artifact|files.*modified|files.*created')        { Write-Ok 'Artifact tracking' }   else { Write-Warn2 'No artifact list' }
    Write-Host ''
} else {
    Write-Warn2 'No todo.md found — no cycle evidence recorded yet'
}

# ── Lessons ──────────────────────────────────────────────────────
$LessonsFile = Join-Path $FeatureDir 'lessons.md'
if (Test-Path $LessonsFile) {
    $LessonCount = ([regex]::Matches((Get-Content $LessonsFile -Raw), '^##')).Count
    Write-Ok "Lessons file present ($LessonCount entries)"
} else {
    Write-Info 'No lessons.md yet'
}

Write-Host ''
exit 0
