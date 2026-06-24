#Requires -Version 5.1
<#
.SYNOPSIS
    Analyze consistency across specification artifacts.
.PARAMETER FeatureId
    Feature directory name (e.g., 001-user-auth).
.EXAMPLE
    .\analyze-consistency.ps1 001-user-auth
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory, Position = 0)]
    [string]$FeatureId
)

$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot  = (Resolve-Path (Join-Path $ScriptDir '..\..\')).Path
$SpecsDir  = Join-Path $RepoRoot '.specify\specs'

function Write-Info    { param([string]$Msg) Write-Host "ℹ️  $Msg" -ForegroundColor Blue }
function Write-Ok      { param([string]$Msg) Write-Host "✅ $Msg" -ForegroundColor Green }
function Write-Warn    { param([string]$Msg) Write-Host "⚠️  $Msg" -ForegroundColor Yellow }
function Write-Err     { param([string]$Msg) Write-Host "❌ $Msg" -ForegroundColor Red }
function Write-Section { param([string]$Msg) Write-Host "`n═══ $Msg ═══`n" -ForegroundColor Magenta }

$FeatureDir = Join-Path $SpecsDir $FeatureId
if (-not (Test-Path $FeatureDir)) {
    Write-Err "Feature directory not found: $FeatureDir"
    exit 1
}

$SpecFile  = Join-Path $FeatureDir 'spec.md'
$PlanFile  = Join-Path $FeatureDir 'plan.md'
$TestFile  = Join-Path $FeatureDir 'test-cases.md'
$TasksFile = Join-Path $FeatureDir 'tasks.md'

$CriticalIssues = 0
$Warnings       = 0
$CriticalList   = @()
$WarningList    = @()

function Get-Ids {
    param([string]$Path, [string]$Pattern)
    if (-not (Test-Path $Path)) { return @() }
    $content = Get-Content $Path -Raw
    [regex]::Matches($content, $Pattern) | ForEach-Object { $_.Value } | Sort-Object -Unique
}

Write-Host ''
Write-Host '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
Write-Host "  🔍 Consistency Analysis: $FeatureId"
Write-Host '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'

# ============================================================
Write-Section '1. User Story Analysis'
# ============================================================

$UserStories = @()
if (-not (Test-Path $SpecFile)) {
    Write-Err 'spec.md not found'
    $CriticalList += 'spec.md file missing'
    $CriticalIssues++
} else {
    $UserStories = Get-Ids $SpecFile 'US-\d+'
    Write-Info "Found $($UserStories.Count) user stories in spec.md"

    foreach ($us in $UserStories) {
        $specContent = Get-Content $SpecFile -Raw
        $acCount = ([regex]::Matches($specContent, "AC-\d+")).Count
        if ($acCount -lt 1) {
            Write-Warn "$us has no acceptance criteria"
            $WarningList += "$us missing acceptance criteria"
            $Warnings++
        } else {
            Write-Ok "$us has acceptance criteria"
        }
    }
}

# ============================================================
Write-Section '2. Plan Coverage'
# ============================================================

if (-not (Test-Path $PlanFile)) {
    Write-Warn 'plan.md not found (Gate 2 not reached?)'
    $WarningList += 'plan.md not found'
    $Warnings++
} else {
    Write-Info 'Checking user story coverage in plan...'
    $planContent = Get-Content $PlanFile -Raw
    $uncovered = 0
    foreach ($us in $UserStories) {
        if ($planContent -match [regex]::Escape($us)) {
            Write-Ok "$us referenced in plan.md"
        } else {
            Write-Warn "$us NOT referenced in plan.md"
            $WarningList += "$us not referenced in plan"
            $Warnings++
            $uncovered++
        }
    }
    if ($uncovered -eq 0 -and $UserStories.Count -gt 0) { Write-Ok 'All user stories covered in plan' }
}

# ============================================================
Write-Section '3. Test Coverage'
# ============================================================

if (-not (Test-Path $TestFile)) {
    Write-Warn 'test-cases.md not found (Gate 3 not reached?)'
    $WarningList += 'test-cases.md not found'
    $Warnings++
} else {
    Write-Info 'Checking user story coverage in tests...'
    $testContent = Get-Content $TestFile -Raw
    $uncovered = 0
    foreach ($us in $UserStories) {
        if ($testContent -match [regex]::Escape($us)) {
            Write-Ok "$us has test cases"
        } else {
            Write-Err "$us has NO test cases"
            $CriticalList += "$us missing test coverage"
            $CriticalIssues++
            $uncovered++
        }
    }
    if ($uncovered -eq 0 -and $UserStories.Count -gt 0) { Write-Ok 'All user stories have test coverage' }
}

# ============================================================
Write-Section '4. Task Coverage'
# ============================================================

if (-not (Test-Path $TasksFile)) {
    Write-Warn 'tasks.md not found (Gate 3 not reached?)'
    $WarningList += 'tasks.md not found'
    $Warnings++
} else {
    Write-Info 'Checking task traceability...'
    $Tasks = Get-Ids $TasksFile 'T\d+'
    Write-Info "Found $($Tasks.Count) tasks"
    $tasksContent = Get-Content $TasksFile -Raw
    $storiesReferenced = ([regex]::Matches($tasksContent, 'US-\d+') | ForEach-Object { $_.Value } | Sort-Object -Unique).Count
    if ($storiesReferenced -gt 0) {
        Write-Ok "Tasks reference $storiesReferenced user stories"
    } else {
        Write-Warn 'Tasks do not reference user stories directly'
        $WarningList += 'Tasks lack user story references'
        $Warnings++
    }
}

# ============================================================
Write-Section '5. Parallel Execution Markers'
# ============================================================

if (Test-Path $TasksFile) {
    Write-Info 'Checking [P]/[S]/[T] markers on tasks...'
    $tasksLines = Get-Content $TasksFile
    $unmarked = 0
    foreach ($task in $Tasks) {
        $line = $tasksLines | Where-Object { $_ -match "###\s*$task\s" } | Select-Object -First 1
        if ($line -and $line -notmatch '\[(P|S|T)\]') {
            Write-Warn "$task missing execution marker ([P]/[S]/[T])"
            $WarningList += "$task missing execution marker"
            $Warnings++
            $unmarked++
        }
    }
    # Check [S] tasks have Depends On
    for ($i = 0; $i -lt $tasksLines.Count; $i++) {
        if ($tasksLines[$i] -match '\[S\]') {
            $snippet = ($tasksLines[($i+1)..([Math]::Min($i+10,$tasksLines.Count-1))]) -join "`n"
            if ($snippet -notmatch '(?i)depends on') {
                $taskId = [regex]::Match($tasksLines[$i], 'T\d+').Value
                Write-Warn "$taskId is [S] but has no 'Depends On' reference"
            }
        }
    }
    if ($unmarked -eq 0 -and $Tasks.Count -gt 0) { Write-Ok 'All tasks have execution markers' }
} else {
    Write-Warn 'tasks.md not found — skipping marker check'
}

# ============================================================
Write-Section '6. Goal-Backward Check'
# ============================================================

$BusinessFile = Join-Path $FeatureDir 'business-context.md'
if (Test-Path $BusinessFile) {
    $bizContent = Get-Content $BusinessFile -Raw
    $goalCount = ([regex]::Matches($bizContent, '(?m)^\|.*\|.*\|')).Count
    if ($goalCount -lt 2) {
        Write-Warn 'business-context.md has few or no structured goals/metrics'
        $WarningList += 'Business context lacks structured goals'
        $Warnings++
    } else {
        Write-Ok 'business-context.md has structured goals/metrics'
    }
    $AnalysisFile = Join-Path $FeatureDir 'analysis-report.md'
    if (Test-Path $AnalysisFile) {
        if ((Get-Content $AnalysisFile -Raw) -match 'Goal-Backward Verification') {
            Write-Ok 'Analysis report includes goal-backward verification'
        } else {
            Write-Warn 'Analysis report missing goal-backward verification section'
            $WarningList += 'Analysis report missing backward verification'
            $Warnings++
        }
    }
} else {
    Write-Warn 'business-context.md not found — cannot check goals'
}

# ============================================================
Write-Section '7. Traceability Matrix'
# ============================================================

$fmt = '{0,-12} | {1,-12} | {2,-12} | {3,-12} | {4,-10}'
Write-Host ($fmt -f 'User Story','Has ACs','In Plan','Has Tests','Status')
Write-Host ($fmt -f ('-'*12),('-'*12),('-'*12),('-'*12),('-'*10))

foreach ($us in $UserStories) {
    $acStatus   = if ((Test-Path $SpecFile) -and ((Get-Content $SpecFile -Raw) -match 'AC-\d+')) { '✓' } else { '✗' }
    $planStatus = if ((Test-Path $PlanFile) -and ((Get-Content $PlanFile -Raw) -match [regex]::Escape($us))) { '✓' } else { '✗' }
    $testStatus = if ((Test-Path $TestFile) -and ((Get-Content $TestFile -Raw) -match [regex]::Escape($us))) { '✓' } else { '✗' }
    $overall    = if ($acStatus -eq '✗' -or $testStatus -eq '✗') { '❌' } elseif ($planStatus -eq '✗') { '⚠️' } else { '✅' }
    Write-Host ($fmt -f $us, $acStatus, $planStatus, $testStatus, $overall)
}

# ============================================================
Write-Section '8. Summary'
# ============================================================

Write-Host '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'

if ($CriticalIssues -gt 0) {
    Write-Host ''
    Write-Err "Critical Issues ($CriticalIssues):"
    $CriticalList | ForEach-Object { Write-Host "  • $_" }
}
if ($Warnings -gt 0) {
    Write-Host ''
    Write-Warn "Warnings ($Warnings):"
    $WarningList | ForEach-Object { Write-Host "  • $_" }
}

Write-Host ''
Write-Host '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'

if ($CriticalIssues -gt 0) {
    Write-Host ''
    Write-Err 'Verdict: FAIL'
    Write-Host '  Address critical issues before proceeding.'
    exit 1
} elseif ($Warnings -gt 0) {
    Write-Host ''
    Write-Warn 'Verdict: PASS WITH WARNINGS'
    Write-Host '  Consider addressing warnings for better traceability.'
    exit 0
} else {
    Write-Host ''
    Write-Ok 'Verdict: PASS'
    Write-Host '  All artifacts are consistent!'
    exit 0
}
