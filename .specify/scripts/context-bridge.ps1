#Requires -Version 5.1
<#
.SYNOPSIS
    Generate compressed context summary for phase transitions.
.DESCRIPTION
    Reads .specify/specs/<feature-id>/ artifacts and generates a compressed
    context bridge document at .specify/specs/<feature-id>/context-bridge.md.
.PARAMETER FeatureId
    Feature directory name (e.g., 001-user-auth).
.PARAMETER TargetPhase
    Phase number to prepare for (1-5). Default: auto-detect next phase.
.EXAMPLE
    .\context-bridge.ps1 001-user-auth
    .\context-bridge.ps1 001-user-auth 3
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory, Position = 0)]
    [string]$FeatureId,

    [Parameter(Position = 1)]
    [int]$TargetPhase = 0
)

$ErrorActionPreference = 'Stop'

$ScriptDir      = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot       = (Resolve-Path (Join-Path $ScriptDir '..\..\')).Path
$SpecsDir       = Join-Path $RepoRoot '.specify\specs'
$MemoryDir      = Join-Path $RepoRoot '.specify\memory'
$CheckpointsDir = Join-Path $RepoRoot '.specify\checkpoints'

function Write-Info  { param([string]$Msg) Write-Host "ℹ️  $Msg" -ForegroundColor Blue }
function Write-Ok    { param([string]$Msg) Write-Host "✅ $Msg" -ForegroundColor Green }
function Write-Warn  { param([string]$Msg) Write-Host "⚠️  $Msg" -ForegroundColor Yellow }
function Write-Err   { param([string]$Msg) Write-Host "❌ $Msg" -ForegroundColor Red }

$FeatureDir = Join-Path $SpecsDir $FeatureId
if (-not (Test-Path $FeatureDir)) {
    Write-Err "Feature directory not found: $FeatureDir"
    exit 1
}

# Auto-detect target phase from checkpoint
if ($TargetPhase -eq 0) {
    $cpFile = Join-Path $CheckpointsDir "$FeatureId.checkpoint"
    if (Test-Path $cpFile) {
        try {
            $cpData = Get-Content $cpFile -Raw | ConvertFrom-Json
            $TargetPhase = [int]$cpData.gate + 1
        } catch { $TargetPhase = 1 }
    } else {
        $TargetPhase = 1
    }
}

$PhaseNames = @{ 1 = 'Requirements'; 2 = 'Design'; 3 = 'Preparation'; 4 = 'Implementation'; 5 = 'Quality Assurance' }
$PhaseName = if ($PhaseNames.ContainsKey($TargetPhase)) { $PhaseNames[$TargetPhase] } else { 'Unknown' }

# Ceremony level detection
$CeremonyLevel = 'standard'
$metaFile = Join-Path $FeatureDir '.feature-meta.json'
if (Test-Path $metaFile) {
    try { $CeremonyLevel = (Get-Content $metaFile -Raw | ConvertFrom-Json).ceremonyLevel } catch {}
    if (-not $CeremonyLevel) { $CeremonyLevel = 'standard' }
}

$Timestamp = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')

Write-Info "Generating context bridge for $FeatureId → Phase $TargetPhase ($PhaseName)"

# Extract feature name
$FeatureName = $FeatureId
$bizFile = Join-Path $FeatureDir 'business-context.md'
if (Test-Path $bizFile) {
    $firstHeading = (Get-Content $bizFile | Where-Object { $_ -match '^# ' } | Select-Object -First 1) -replace '^# ', ''
    if ($firstHeading) { $FeatureName = $firstHeading }
}

$sb = [System.Text.StringBuilder]::new()
[void]$sb.AppendLine("# Context Bridge: $FeatureName")
[void]$sb.AppendLine('')
[void]$sb.AppendLine("**Feature ID:** $FeatureId")
[void]$sb.AppendLine("**Generated:** $Timestamp")
[void]$sb.AppendLine("**Target Phase:** $TargetPhase — $PhaseName")
[void]$sb.AppendLine("**Ceremony Level:** $CeremonyLevel")
[void]$sb.AppendLine('')
[void]$sb.AppendLine('---')
[void]$sb.AppendLine('')

# Feature Goal
[void]$sb.AppendLine('## Feature Goal')
[void]$sb.AppendLine('')
if (Test-Path $bizFile) {
    $bizContent = Get-Content $bizFile
    $purposeIdx = ($bizContent | Select-String -Pattern '^## Purpose' | Select-Object -First 1).LineNumber
    if ($purposeIdx) {
        $goal = ($bizContent[($purposeIdx)..([Math]::Min($purposeIdx + 2, $bizContent.Count - 1))] | Where-Object { $_ -ne '' }) -join "`n"
        if ($goal) { [void]$sb.AppendLine($goal) } else { [void]$sb.AppendLine('(Not yet defined)') }
    } else { [void]$sb.AppendLine('(Not yet defined)') }
} else { [void]$sb.AppendLine('(business-context.md not yet created)') }
[void]$sb.AppendLine('')

# Completed Phases Summary
[void]$sb.AppendLine('## Completed Phases Summary')
[void]$sb.AppendLine('')

# Phase 1
$specFile = Join-Path $FeatureDir 'spec.md'
if ($TargetPhase -gt 1 -and (Test-Path $specFile)) {
    $specContent = Get-Content $specFile -Raw
    $usCount = ([regex]::Matches($specContent, 'US-\d+') | ForEach-Object { $_.Value } | Sort-Object -Unique).Count
    $acCount = ([regex]::Matches($specContent, 'AC-\d+') | ForEach-Object { $_.Value } | Sort-Object -Unique).Count
    $ncCount = 0
    Get-ChildItem $FeatureDir -Filter '*.md' | ForEach-Object {
        $ncCount += ([regex]::Matches((Get-Content $_.FullName -Raw), '\[NEEDS CLARIFICATION:')).Count
    }
    [void]$sb.AppendLine('### Phase 1: Requirements (Gate 1 ✅)')
    [void]$sb.AppendLine("- **User Stories:** $usCount")
    [void]$sb.AppendLine("- **Acceptance Criteria:** $acCount")
    $clarFile = Join-Path $FeatureDir 'clarifications.md'
    if (Test-Path $clarFile) {
        $decisions = ([regex]::Matches((Get-Content $clarFile -Raw), '(?m)^\*\*Decision:\*\*|^- \*\*Decision')).Count
        [void]$sb.AppendLine("- **Key Decisions:** $decisions recorded")
    }
    [void]$sb.AppendLine("- **Open Questions:** $ncCount remaining [NEEDS CLARIFICATION] markers")
    [void]$sb.AppendLine('')
}

# Phase 2
$planFile = Join-Path $FeatureDir 'plan.md'
if ($TargetPhase -gt 2 -and (Test-Path $planFile)) {
    $planContent = Get-Content $planFile -Raw
    $archMatch = [regex]::Match($planContent, '(?m)^#{2,3}.*[Aa]rchitect.*')
    $arch = if ($archMatch.Success) { $archMatch.Value -replace '^#+ ', '' } else { 'Not specified' }
    $hasOpenapi = if (Test-Path (Join-Path $FeatureDir 'contracts\openapi.yaml')) { 'yes' } else { 'no' }
    $hasAsyncapi = if (Test-Path (Join-Path $FeatureDir 'contracts\asyncapi.yaml')) { 'yes' } else { 'no' }
    [void]$sb.AppendLine('### Phase 2: Design (Gate 2 ✅)')
    [void]$sb.AppendLine("- **Architecture Pattern:** $arch")
    [void]$sb.AppendLine("- **Contracts:** OpenAPI: $hasOpenapi, AsyncAPI: $hasAsyncapi")
    [void]$sb.AppendLine('')
}

# Phase 3
$testFile = Join-Path $FeatureDir 'test-cases.md'
if ($TargetPhase -gt 3 -and (Test-Path $testFile)) {
    $tcCount = ([regex]::Matches((Get-Content $testFile -Raw), 'TC-\d+') | ForEach-Object { $_.Value } | Sort-Object -Unique).Count
    $taskCount = 0
    $tasksFile = Join-Path $FeatureDir 'tasks.md'
    if (Test-Path $tasksFile) {
        $taskCount = ([regex]::Matches((Get-Content $tasksFile -Raw), 'T\d{3}') | ForEach-Object { $_.Value } | Sort-Object -Unique).Count
    }
    $verdict = 'Not available'
    $analysisFile = Join-Path $FeatureDir 'analysis-report.md'
    if (Test-Path $analysisFile) {
        $ac = Get-Content $analysisFile -Raw
        if ($ac -match '(?i)Verdict:\s*PASS\b') { $verdict = 'PASS' }
        elseif ($ac -match '(?i)Verdict:\s*PASS WITH WARNINGS') { $verdict = 'PASS WITH WARNINGS' }
        elseif ($ac -match '(?i)Verdict:\s*FAIL') { $verdict = 'FAIL' }
    }
    [void]$sb.AppendLine('### Phase 3: Preparation (Gate 3 ✅)')
    [void]$sb.AppendLine("- **Test Cases:** $tcCount")
    [void]$sb.AppendLine("- **Tasks:** $taskCount")
    [void]$sb.AppendLine("- **Analysis Verdict:** $verdict")
    [void]$sb.AppendLine('')
}

# Artifacts Available
[void]$sb.AppendLine('## Artifacts Available')
[void]$sb.AppendLine('')
Get-ChildItem $FeatureDir -Filter '*.md' -ErrorAction SilentlyContinue | ForEach-Object { [void]$sb.AppendLine("- $($_.Name)") }
$contractsDir = Join-Path $FeatureDir 'contracts'
if (Test-Path $contractsDir) {
    Get-ChildItem $contractsDir -Include '*.yaml','*.yml' -ErrorAction SilentlyContinue | ForEach-Object { [void]$sb.AppendLine("- $($_.Name)") }
}
[void]$sb.AppendLine('')

# Key Constraints
[void]$sb.AppendLine('## Key Constraints')
[void]$sb.AppendLine('')
$constitutionFile = Join-Path $MemoryDir 'constitution.md'
if (Test-Path $constitutionFile) {
    [void]$sb.AppendLine('(See .specify/memory/constitution.md for project-wide constraints)')
} else {
    [void]$sb.AppendLine('(No constitution defined)')
}
[void]$sb.AppendLine('')

$OutputFile = Join-Path $FeatureDir 'context-bridge.md'
Set-Content -Path $OutputFile -Value $sb.ToString() -Encoding UTF8 -NoNewline

Write-Ok "Context bridge generated: $OutputFile"
Write-Host ''
Write-Host "  Target: Phase $TargetPhase — $PhaseName"
Write-Host "  Ceremony: $CeremonyLevel"
Write-Host ''
