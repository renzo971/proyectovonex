#Requires -Version 5.1
<#!
.SYNOPSIS
    Synchronize structured memory for a feature.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory, Position = 0)]
    [string]$FeatureId
)

$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$BashScript = Join-Path $ScriptDir 'memory-sync.sh'

if (-not (Test-Path $BashScript)) {
    Write-Error "Script not found: $BashScript"
    exit 2
}

if (-not (Get-Command bash -ErrorAction SilentlyContinue)) {
    Write-Error 'bash is required to run memory-sync.ps1'
    exit 2
}

& bash $BashScript $FeatureId
$exitCode = $LASTEXITCODE
if ($null -eq $exitCode) { $exitCode = 0 }
exit $exitCode
