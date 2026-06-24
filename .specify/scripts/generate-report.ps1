#Requires -Version 5.1
<#
.SYNOPSIS
    Generate analysis-report.md for a feature.
.PARAMETER FeatureId
    Feature directory name (e.g., 001-user-auth).
.PARAMETER DryRun
    Print to stdout instead of file.
.EXAMPLE
    .\generate-report.ps1 001-user-auth
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory, Position = 0)]
    [string]$FeatureId,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot  = (Resolve-Path (Join-Path $ScriptDir '..\..\')).Path
$SpecsDir  = Join-Path $RepoRoot '.specify\specs'

function Write-Info { param([string]$Msg) Write-Host "ℹ️  $Msg" -ForegroundColor Blue }
function Write-Ok   { param([string]$Msg) Write-Host "✅ $Msg" -ForegroundColor Green }
function Write-Err  { param([string]$Msg) Write-Host "❌ $Msg" -ForegroundColor Red }
function Write-Warn { param([string]$Msg) Write-Host "⚠️  $Msg" -ForegroundColor Yellow }

$FeatureDir = Join-Path $SpecsDir $FeatureId
if (-not (Test-Path $FeatureDir)) {
    Write-Err "Feature directory not found: $FeatureDir"
    exit 1
}

$SpecFile   = Join-Path $FeatureDir 'spec.md'
$PlanFile   = Join-Path $FeatureDir 'plan.md'
$TestFile   = Join-Path $FeatureDir 'test-cases.md'
$TasksFile  = Join-Path $FeatureDir 'tasks.md'
$OutputFile = Join-Path $FeatureDir 'analysis-report.md'

# Warn if analysis-report.md already contains non-template content
if ((Test-Path $OutputFile) -and -not ((Get-Content $OutputFile -Raw) -match '\[FEATURE_NAME\]|\[NNN\]|<!-- INSTRUCTION -->')) {
    Write-Warn 'analysis-report.md already exists with non-template content'
    Write-Warn 'This script will overwrite it.'
    $reply = Read-Host 'Continue and overwrite? [y/N]'
    if ($reply -notmatch '^[Yy]') {
        Write-Info 'Aborted. Existing analysis-report.md preserved.'
        return
    }
}

# Extract feature name
$FeatureName = $FeatureId
$bcPath = Join-Path $FeatureDir 'business-context.md'
if (Test-Path $bcPath) {
    $m = [regex]::Match((Get-Content $bcPath -Raw), '^# Business Context:\s*(.+)', 'Multiline')
    if ($m.Success) { $FeatureName = $m.Groups[1].Value.Trim() }
} elseif (Test-Path $SpecFile) {
    $m = [regex]::Match((Get-Content $SpecFile -Raw), '^# Feature Specification:\s*(.+)', 'Multiline')
    if ($m.Success) { $FeatureName = $m.Groups[1].Value.Trim() }
}

Write-Info "Generating analysis report for: $FeatureName"

$Today = Get-Date -Format 'yyyy-MM-dd'
$CriticalCount = 0
$WarningCount  = 0
$CriticalIssues = ''
$WarningIssues  = ''
$Matrix = ''

# User stories
$UserStories = @()
if (Test-Path $SpecFile) {
    $specContent = Get-Content $SpecFile -Raw
    $UserStories = [regex]::Matches($specContent, 'US-\d+') | ForEach-Object { $_.Value } | Sort-Object -Unique

    foreach ($us in $UserStories) {
        $planCov = '✗'; $taskCov = '✗'; $testCov = '✗'
        $planLoc = 'MISSING'; $taskIds = 'MISSING'; $testIds = 'MISSING'

        if ((Test-Path $PlanFile) -and ((Get-Content $PlanFile -Raw) -match [regex]::Escape($us))) {
            $planCov = '✓'; $planLoc = 'Found'
        }
        if ((Test-Path $TasksFile) -and ((Get-Content $TasksFile -Raw) -match [regex]::Escape($us))) {
            $taskCov = '✓'
            $taskIds = ([regex]::Matches((Get-Content $TasksFile -Raw), 'T\d+') | ForEach-Object { $_.Value } | Select-Object -First 3) -join ', '
        }
        if ((Test-Path $TestFile) -and ((Get-Content $TestFile -Raw) -match [regex]::Escape($us))) {
            $testCov = '✓'
            $testIds = ([regex]::Matches((Get-Content $TestFile -Raw), 'TC-\d+') | ForEach-Object { $_.Value } | Sort-Object -Unique) -join ', '
        }

        $status = 'OK'
        if ($planCov -eq '✗' -or $taskCov -eq '✗' -or $testCov -eq '✗') {
            $status = 'WARN'
            $WarningCount++
            if ($taskCov -eq '✗') { $WarningIssues += "- $us missing task coverage`n" }
            if ($testCov -eq '✗') { $WarningIssues += "- $us missing test coverage`n" }
        }

        $Matrix += "| $us     | $planCov $planLoc | $taskCov $taskIds  | $testCov $testIds      | $status     |`n"
    }
}

# Verdict
$Verdict = if ($CriticalCount -gt 0) { 'FAIL' } elseif ($WarningCount -gt 0) { 'PASS WITH WARNINGS' } else { 'PASS' }

$VerdictText = switch ($Verdict) {
    'PASS'               { '✅ Artifacts are consistent and complete. Proceed to Gate 3.' }
    'PASS WITH WARNINGS' { '⚠️ Artifacts pass minimum requirements but have noted concerns.' }
    default              { '❌ Artifacts have critical gaps that must be addressed.' }
}

$CriticalSection = if ($CriticalCount -eq 0) { '- None' } else { $CriticalIssues }
$WarningSection  = if ($WarningCount -eq 0)  { '- None' } else { $WarningIssues }

$memoryStatusText = 'Memory status script not available'
$memoryStatusScript = Join-Path $ScriptDir 'memory-status.ps1'
if (Test-Path $memoryStatusScript) {
    try {
        $memoryOutput = & $memoryStatusScript $FeatureId 2>$null
        if ($memoryOutput) {
            $memoryStatusText = ($memoryOutput | ForEach-Object { "- $_" }) -join "`n"
        }
    } catch {
        $memoryStatusText = '- Memory status collection failed'
    }
}

# ── Artifact Dependency Graph (OpenSpec MVP — Evolution §12 item #1) ──

$MemoryDir = Join-Path $RepoRoot '.specify\memory'

function Get-ArtifactMark {
    param([string]$FilePath)
    if (-not (Test-Path $FilePath)) { return '✗ Missing' }
    $c = Get-Content $FilePath -Raw -ErrorAction SilentlyContinue
    if ($c -match '\[FEATURE_NAME\]|\[NNN\]|<!-- INSTRUCTION -->') { return '⚠ Template' }
    return '✓ Present'
}

$graphLines = @(
    "constitution.md [$(Get-ArtifactMark (Join-Path $MemoryDir 'constitution.md'))]"
    "  └─► business-context.md [$(Get-ArtifactMark (Join-Path $FeatureDir 'business-context.md'))]"
    "       └─► spec.md [$(Get-ArtifactMark (Join-Path $FeatureDir 'spec.md'))]"
    "            ├─► clarifications.md [$(Get-ArtifactMark (Join-Path $FeatureDir 'clarifications.md'))]"
    "            └─► plan.md (design) [$(Get-ArtifactMark (Join-Path $FeatureDir 'plan.md'))]"
    "                 ├─► test-cases.md [$(Get-ArtifactMark (Join-Path $FeatureDir 'test-cases.md'))]"
    "                 └─► tasks.md [$(Get-ArtifactMark (Join-Path $FeatureDir 'tasks.md'))]"
    "                      └─► analysis-report.md [$(Get-ArtifactMark (Join-Path $FeatureDir 'analysis-report.md'))]"
    "                           └─► memory/"
    "                                ├─► decisions.md [$(Get-ArtifactMark (Join-Path $MemoryDir 'decisions.md'))]"
    "                                ├─► lessons.md [$(Get-ArtifactMark (Join-Path $MemoryDir 'lessons.md'))]"
    "                                └─► metrics-log.md [$(Get-ArtifactMark (Join-Path $MemoryDir 'metrics-log.md'))]"
    ""
    "Legend: ✓ Present  ✗ Missing  ⚠ Template"
)
$artifactGraph = $graphLines -join "`n"

$report = @"
# Consistency Analysis: $FeatureName

**Feature ID:** $FeatureId
**Generated:** $Today
**Verdict:** $Verdict

---

## Executive Summary

| Metric | Count |
|--------|-------|
| Critical Issues | $CriticalCount |
| Warnings | $WarningCount |
| User Stories Analyzed | $($UserStories.Count) |

---

## Traceability Matrix

| User Story | Plan Coverage | Task Coverage | Test Coverage | Status |
|------------|---------------|---------------|---------------|--------|
$Matrix

---

## Issues Found

### Critical

$CriticalSection

### Warnings

$WarningSection

---

## Recommendations

$(if ($Verdict -eq 'PASS') { '✅ All artifacts are consistent. Ready for Gate 3 review.' } else { "⚠️ Address the warnings above before proceeding.`n`n1. Review warnings and determine if blocking`n2. Add missing test/task coverage`n3. Re-run analysis after fixes" })

---

## Quality Metrics

| Metric | Value | Prompt Field |
|--------|-------|--------------|
| Generate-to-Review Ratio (G2R) | [fill] | generated units / review interventions |
| Intervention Rate | [fill] | human interventions / execution cycles |

Interpretation:
- G2R < 2:1 -> stabilization needed
- G2R 2:1 to < 4:1 -> acceptable baseline
- G2R >= 4:1 -> strong flow (verify with gate quality)

---

## Memory Lifecycle Status

$memoryStatusText

---

## Artifact Dependency Graph

``````
$artifactGraph
``````

---

## Verdict: $Verdict

$VerdictText

---

*This report was auto-generated by generate-report.ps1*
"@

if ($DryRun) {
    Write-Output $report
} else {
    Set-Content -Path $OutputFile -Value $report -Encoding UTF8
    Write-Ok "Report generated: $OutputFile"
}
