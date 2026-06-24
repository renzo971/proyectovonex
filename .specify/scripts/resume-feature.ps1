#Requires -Version 5.1
<#
.SYNOPSIS
    Resume a feature from its last checkpoint.
.PARAMETER FeatureId
    Feature directory name (e.g., 001-user-auth).
.PARAMETER Unlock
    Force-remove any stale lock file for this feature.
.PARAMETER StatusOnly
    Show checkpoint status without resuming.
.EXAMPLE
    .\resume-feature.ps1 001-user-auth
    .\resume-feature.ps1 -StatusOnly 001-user-auth
    .\resume-feature.ps1 -Unlock 001-user-auth
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory, Position = 0)]
    [string]$FeatureId,
    [switch]$Unlock,
    [switch]$StatusOnly
)

$ErrorActionPreference = 'Stop'

$ScriptDir      = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot       = (Resolve-Path (Join-Path $ScriptDir '..\..\')).Path
$SpecsDir       = Join-Path $RepoRoot '.specify\specs'
$CheckpointsDir = Join-Path $RepoRoot '.specify\checkpoints'

function Write-Info  { param([string]$Msg) Write-Host "ℹ️  $Msg" -ForegroundColor Blue }
function Write-Ok    { param([string]$Msg) Write-Host "✅ $Msg" -ForegroundColor Green }
function Write-Warn  { param([string]$Msg) Write-Host "⚠️  $Msg" -ForegroundColor Yellow }
function Write-Err   { param([string]$Msg) Write-Host "❌ $Msg" -ForegroundColor Red }

$FeatureDir     = Join-Path $SpecsDir $FeatureId
$CheckpointFile = Join-Path $CheckpointsDir "$FeatureId.checkpoint"
$LockFile       = Join-Path $CheckpointsDir "$FeatureId.lock"
$MetaFile       = Join-Path $FeatureDir '.feature-meta.json'

# Handle --unlock
if ($Unlock) {
    if (Test-Path $LockFile) {
        Remove-Item $LockFile -Force
        Write-Ok "Lock removed for $FeatureId"
    } else {
        Write-Info "No lock found for $FeatureId"
    }
    return
}

# Verify feature exists
if (-not (Test-Path $FeatureDir)) {
    Write-Err "Feature directory not found: $FeatureDir"
    exit 1
}

Write-Host ''
Write-Host '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
Write-Host "  🔄 Resume Feature: $FeatureId"
Write-Host '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
Write-Host ''

# Read ceremony level
$CeremonyLevel = 'standard'
if (Test-Path $MetaFile) {
    try { $CeremonyLevel = (Get-Content $MetaFile -Raw | ConvertFrom-Json).ceremonyLevel } catch {}
    if (-not $CeremonyLevel) { $CeremonyLevel = 'standard' }
}
Write-Info "Ceremony level: $CeremonyLevel"

# Read checkpoint
$LastGate = 0
$LastTime = 'unknown'
if (Test-Path $CheckpointFile) {
    try {
        $cp = Get-Content $CheckpointFile -Raw | ConvertFrom-Json
        $LastGate = [int]$cp.gate
        $LastTime = $cp.timestamp
    } catch {}
    Write-Ok "Last checkpoint: Gate $LastGate passed at $LastTime"
} else {
    Write-Warn 'No checkpoint found — feature has not passed any gate yet'
}

# Determine next phase
Write-Host ''
$NextAgent = ''
$NextGate  = ''
switch ($LastGate) {
    0 {
        if ($CeremonyLevel -eq 'ultra-light') {
            Write-Info 'Next: Fill in spec.md, then @software-engineer (Planning)'
            $NextAgent = '@software-engineer (Planning mode)'
            $NextGate  = '4'
        } else {
            Write-Info 'Next: Phase 1 — Begin with @requirement-analyst'
            $NextAgent = '@requirement-analyst'
            $NextGate  = '1'
        }
    }
    1 { Write-Info 'Next: Phase 2 — Begin with @architect'; $NextAgent = '@architect'; $NextGate = '2' }
    2 { Write-Info 'Next: Phase 3 — Begin with @test-explorer'; $NextAgent = '@test-explorer'; $NextGate = '3' }
    3 { Write-Info 'Next: Phase 4 — Begin TDD with @test-engineer'; $NextAgent = '@test-engineer'; $NextGate = '4' }
    4 { Write-Ok 'All gates passed! Feature is ready to ship.'; $NextAgent = '(none — ready to merge)'; $NextGate = '(done)' }
}

Write-Host ''
Write-Host '  📋 Summary:'
Write-Host "     Feature:         $FeatureId"
Write-Host "     Ceremony:        $CeremonyLevel"
Write-Host "     Last Gate:       $LastGate"
Write-Host "     Next Agent:      $NextAgent"
Write-Host "     Next Gate:       $NextGate"

if ($StatusOnly) {
    Write-Host ''
    Write-Host '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
    return
}

# Check lock
if (Test-Path $LockFile) {
    try {
        $lockData = Get-Content $LockFile -Raw | ConvertFrom-Json
        $lockPid  = $lockData.pid
        try { $proc = Get-Process -Id $lockPid -ErrorAction Stop; $alive = $true } catch { $alive = $false }
        if ($alive) {
            Write-Host ''
            Write-Err "Feature is currently locked (active agent PID: $lockPid)"
            Write-Err 'Use -Unlock to force-remove if the process is stale.'
            exit 1
        } else {
            Write-Warn 'Removing stale lock file'
            Remove-Item $LockFile -Force
        }
    } catch {
        Remove-Item $LockFile -Force
    }
}

Write-Host ''
Write-Host '  To continue, open VS Code Copilot Chat and type:'
Write-Host ''
Write-Host "     $NextAgent"
Write-Host ''
Write-Host '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
