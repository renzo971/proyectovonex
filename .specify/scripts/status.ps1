#Requires -Version 5.1
<#
.SYNOPSIS
    Show status dashboard for all features.
.EXAMPLE
    .\status.ps1
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$FeatureId,

    [switch]$Graph
)

$ErrorActionPreference = 'Stop'

$ScriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot   = (Resolve-Path (Join-Path $ScriptDir '..\..\')).Path
$SpecsDir   = Join-Path $RepoRoot '.specify\specs'
$MemoryDir  = Join-Path $RepoRoot '.specify\memory'
$WorktreesDir = Join-Path $RepoRoot '.sdd\worktrees'

function Write-Info { param([string]$Msg) Write-Host "ℹ️  $Msg" -ForegroundColor Blue }
function Write-Ok   { param([string]$Msg) Write-Host "✅ $Msg" -ForegroundColor Green }
function Write-Warn { param([string]$Msg) Write-Host "⚠️  $Msg" -ForegroundColor Yellow }

function Test-FileReady {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return $false }
    $c = Get-Content $Path -Raw -ErrorAction SilentlyContinue
    if ($c -match '\[FEATURE_NAME\]|\[NNN\]|<!-- INSTRUCTION -->') { return $false }
    if ($c -match '(?m)^\*\*Status:\*\*.*\|.*\|')                 { return $false }
    if ($c -match '\[Story [Tt]itle\]|\[Describe |\[Add ')         { return $false }
    return $true
}

function Get-FileStatus {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return 'M' }
    if (Test-FileReady $Path)   { return 'P' }
    return 'T'
}

function Get-Phase {
    param([string]$Dir)
    $ship = Join-Path $Dir 'ship-checklist.md'
    if ((Test-Path $ship) -and ((Get-Content $ship -Raw -ErrorAction SilentlyContinue) -match '\[x\]')) { return '5-Ship' }
    if (Test-FileReady (Join-Path $Dir 'analysis-report.md')) { return '4-Impl' }
    if (Test-FileReady (Join-Path $Dir 'tasks.md'))           { return '3.2-Tasks' }
    if (Test-FileReady (Join-Path $Dir 'test-cases.md'))      { return '3.1-Tests' }
    if (Test-FileReady (Join-Path $Dir 'plan.md'))            { return '2-Design' }
    if (Test-FileReady (Join-Path $Dir 'clarifications.md'))  { return '1.3-Clarify' }
    if (Test-FileReady (Join-Path $Dir 'spec.md'))            { return '1.2-Spec' }
    if (Test-FileReady (Join-Path $Dir 'business-context.md')){ return '1.1-Vision' }
    return '0-Init'
}

function Get-GateStatus {
    param([string]$Phase)
    switch -Wildcard ($Phase) {
        '5-Ship'      { 'Gate 4' }
        '4-Impl'      { 'Gate 3' }
        '3*'          { '→ Gate 3' }
        '2-Design'    { 'Gate 2' }
        '1.3-Clarify' { '→ Gate 1' }
        '1*'          { 'Pre-Gate' }
        default       { '-' }
    }
}

function Get-MemoryFreshnessScore {
    param([string]$FeatureDir)

    $files = @(
        (Join-Path $MemoryDir 'decisions.md'),
        (Join-Path $MemoryDir 'lessons.md'),
        (Join-Path $MemoryDir 'metrics-log.md'),
        (Join-Path $FeatureDir '.feature-meta.json')
    )

    $timestamps = @()
    foreach ($f in $files) {
        if (Test-Path $f) {
            $timestamps += (Get-Item $f).LastWriteTimeUtc
        }
    }

    if ($timestamps.Count -eq 0) { return 'N/A' }

    $latest = ($timestamps | Sort-Object -Descending | Select-Object -First 1)
    $ageDays = [int](([DateTime]::UtcNow - $latest).TotalDays)

    if ($ageDays -le 7) { return '100' }
    if ($ageDays -le 14) { return '80' }
    if ($ageDays -le 30) { return '60' }
    if ($ageDays -le 60) { return '40' }
    return '20'
}

function Get-CostMetrics {
    param([string]$FeatureDir)

    $costLog = Join-Path $FeatureDir 'cost-log.json'
    if (-not (Test-Path $costLog)) {
        return [pscustomobject]@{
            Total = '0.00'
            Budget = 'N/A'
            Util = 'N/A'
            Trend = '-'
        }
    }

    try {
        $payload = Get-Content $costLog -Raw | ConvertFrom-Json
    } catch {
        return [pscustomobject]@{
            Total = '0.00'
            Budget = 'N/A'
            Util = 'N/A'
            Trend = 'invalid'
        }
    }

    $total = [double]($payload.totalCost)
    $entries = @($payload.entries)
    if ($total -eq 0 -and $entries.Count -gt 0) {
        $total = ($entries | Measure-Object -Property estimatedCost -Sum).Sum
    }

    $phaseTotals = @{}
    foreach ($entry in $entries) {
        $phase = [string]$entry.phase
        if (-not $phase) { $phase = '?' }
        if (-not $phaseTotals.ContainsKey($phase)) { $phaseTotals[$phase] = 0.0 }
        $phaseTotals[$phase] += [double]$entry.estimatedCost
    }

    if ($phaseTotals.Count -eq 0) {
        $trend = '-'
    } else {
        $keys = $phaseTotals.Keys | Sort-Object {[int]($_ -replace '[^0-9]','')}
        $trend = ($keys | ForEach-Object { "p$_:{0:N2}" -f $phaseTotals[$_] }) -join ','
    }

    $budgetRaw = $payload.budgetCeiling
    if ($null -eq $budgetRaw -or [double]$budgetRaw -eq 0) {
        $budget = 'N/A'
        $util = 'N/A'
    } else {
        $budgetNum = [double]$budgetRaw
        $budget = '{0:N2}' -f $budgetNum
        $util = '{0:N1}%' -f (($total / $budgetNum) * 100)
    }

    return [pscustomobject]@{
        Total = '{0:N2}' -f $total
        Budget = $budget
        Util = $util
        Trend = $trend
    }
}

function Get-FeatureDirectories {
    $seen = @{}

    if (Test-Path $SpecsDir) {
        Get-ChildItem $SpecsDir -Directory -ErrorAction SilentlyContinue | ForEach-Object {
            if ($FeatureId -and $_.Name -ne $FeatureId) { return }
            $seen[$_.Name] = $_.FullName
        }
    }

    if (Test-Path $WorktreesDir) {
        Get-ChildItem $WorktreesDir -Directory -ErrorAction SilentlyContinue | ForEach-Object {
            $specsPath = Join-Path $_.FullName '.specify\specs'
            if (-not (Test-Path $specsPath)) { return }
            Get-ChildItem $specsPath -Directory -ErrorAction SilentlyContinue | ForEach-Object {
                if ($FeatureId -and $_.Name -ne $FeatureId) { return }
                if (-not $seen.ContainsKey($_.Name)) {
                    $seen[$_.Name] = $_.FullName
                }
            }
        }
    }

    return $seen.GetEnumerator() | Sort-Object Name | ForEach-Object { $_.Value }
}

Write-Host ''
Write-Host '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
Write-Host '  📊 Feature Status Dashboard' -ForegroundColor White
Write-Host '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
Write-Host ''

$constitutionPath = Join-Path $MemoryDir 'constitution.md'
if (Test-Path $constitutionPath) {
    Write-Host '✓ Constitution established' -ForegroundColor Green
} else {
    Write-Host '⚠ No constitution found - run Constitution Agent first' -ForegroundColor Yellow
}
Write-Host ''

$featureDirs = @(Get-FeatureDirectories)
if ($featureDirs.Count -eq 0) {
    Write-Info 'No features found'
    Write-Host ''
    Write-Host '  Create a new feature with:'
    Write-Host '  .\new-feature.ps1 "feature name"' -ForegroundColor Cyan
    Write-Host ''
    return
}

# Header
$fmt = '{0,-25} | {1,-10} | {2,-12} | {3,-6} | {4,-6} | {5,-6} | {6,-6} | {7,-6} | {8,-6} | {9,-8} | {10,-8}'
Write-Host ($fmt -f 'Feature','Phase','Gate','Spec','Plan','Tests','Tasks','Report','MFS','Cost','Budget%')
Write-Host ($fmt -f ('-'*25),('-'*10),('-'*12),('-'*6),('-'*6),('-'*6),('-'*6),('-'*6),('-'*6),('-'*8),('-'*8))

foreach ($d in $featureDirs) {
    $name  = Split-Path $d -Leaf
    $phase = Get-Phase $d
    $gate  = Get-GateStatus $phase
    $spec  = Get-FileStatus (Join-Path $d 'spec.md')
    $plan  = Get-FileStatus (Join-Path $d 'plan.md')
    $tests = Get-FileStatus (Join-Path $d 'test-cases.md')
    $tasks = Get-FileStatus (Join-Path $d 'tasks.md')
    $report= Get-FileStatus (Join-Path $d 'analysis-report.md')
    $mfs   = Get-MemoryFreshnessScore $d
    $cost  = Get-CostMetrics $d

    Write-Host ($fmt -f $name,$phase,$gate,$spec,$plan,$tests,$tasks,$report,$mfs,$cost.Total,$cost.Util)
    if ($cost.Trend -ne '-') {
        Write-Host ($fmt -f '','','','','','','','','','trend',$cost.Trend)
    }

    if ($cost.Util -ne 'N/A') {
        $utilNum = [double]($cost.Util -replace '%','')
        if ($utilNum -ge 80) {
            Write-Host "⚠ Budget warning for $name: $($cost.Total) / $($cost.Budget) ($($cost.Util))" -ForegroundColor Yellow
        }
    }
}

Write-Host ''
Write-Host '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
Write-Host ''
Write-Host '  Legend:'
Write-Host '    P = Present (real content)    T = Template (not compiled)    M = Missing'
Write-Host ''
Write-Host '  Phases: 1.1-Vision → 1.2-Spec → 1.3-Clarify → 2-Design → 3.1-Tests → 3.2-Tasks → 4-Impl → 5-Ship'
Write-Host ''
Write-Host '  Commands:'
Write-Host '    .\validate-gate.ps1 <feature> <1|2|3|4>  - Validate gate criteria' -ForegroundColor Cyan
Write-Host '    .\analyze-consistency.ps1 <feature>       - Run consistency analysis' -ForegroundColor Cyan
Write-Host '    .\generate-report.ps1 <feature>           - Generate analysis report' -ForegroundColor Cyan
Write-Host '    .\memory-status.ps1 <feature>             - Show memory freshness metrics' -ForegroundColor Cyan
Write-Host '    .\memory-sync.ps1 <feature>               - Refresh memory index + logs' -ForegroundColor Cyan
Write-Host '    .\memory-doctor.ps1 <feature>             - Diagnose memory drift/conflicts' -ForegroundColor Cyan
Write-Host '    .\status.ps1 <feature> -Graph             - Show artifact dependency graph' -ForegroundColor Cyan
Write-Host ''

# ── Artifact Dependency Graph (OpenSpec MVP — Evolution §12 item #1) ──

function Get-ArtifactLabel {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return 'Missing' }
    if (Test-FileReady $Path)   { return 'Present' }
    return 'Template'
}

function Get-ArtifactSymbol {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return [char]0x2717 } # ✗
    if (Test-FileReady $Path)   { return [char]0x2713 } # ✓
    return [char]0x26A0 # ⚠
}

if ($Graph) {
    foreach ($d in $featureDirs) {
        $name = Split-Path $d -Leaf
        Write-Host ''
        Write-Host ([string]::new([char]0x2501, 81))
        Write-Host "  Artifact Dependency Graph: $name" -ForegroundColor White
        Write-Host ([string]::new([char]0x2501, 81))
        Write-Host ''

        $items = @{
            constitution   = Join-Path $MemoryDir 'constitution.md'
            biz            = Join-Path $d 'business-context.md'
            spec           = Join-Path $d 'spec.md'
            clarify        = Join-Path $d 'clarifications.md'
            plan           = Join-Path $d 'plan.md'
            tests          = Join-Path $d 'test-cases.md'
            tasks          = Join-Path $d 'tasks.md'
            report         = Join-Path $d 'analysis-report.md'
            decisions      = Join-Path $MemoryDir 'decisions.md'
            lessons        = Join-Path $MemoryDir 'lessons.md'
            metrics        = Join-Path $MemoryDir 'metrics-log.md'
        }

        function Stat($key) { "$(Get-ArtifactSymbol $items[$key]) $(Get-ArtifactLabel $items[$key])" }

        Write-Host "  constitution.md [$(Stat 'constitution')]"
        Write-Host "    `u{2514}`u{2500}`u{25BA} business-context.md [$(Stat 'biz')]"
        Write-Host "         `u{2514}`u{2500}`u{25BA} spec.md [$(Stat 'spec')]"
        Write-Host "              `u{251C}`u{2500}`u{25BA} clarifications.md [$(Stat 'clarify')]"
        Write-Host "              `u{2514}`u{2500}`u{25BA} plan.md (design) [$(Stat 'plan')]"
        Write-Host "                   `u{251C}`u{2500}`u{25BA} test-cases.md [$(Stat 'tests')]"
        Write-Host "                   `u{2514}`u{2500}`u{25BA} tasks.md [$(Stat 'tasks')]"
        Write-Host "                        `u{2514}`u{2500}`u{25BA} analysis-report.md [$(Stat 'report')]"
        Write-Host "                             `u{2514}`u{2500}`u{25BA} memory/"
        Write-Host "                                  `u{251C}`u{2500}`u{25BA} decisions.md [$(Stat 'decisions')]"
        Write-Host "                                  `u{251C}`u{2500}`u{25BA} lessons.md [$(Stat 'lessons')]"
        Write-Host "                                  `u{2514}`u{2500}`u{25BA} metrics-log.md [$(Stat 'metrics')]"
        Write-Host ''
        Write-Host '  Legend: ✓ Present  ✗ Missing  ⚠ Template (not compiled)'
        Write-Host ''
    }
}
