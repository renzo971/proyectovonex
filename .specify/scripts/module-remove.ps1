#Requires -Version 5.1
<#
.SYNOPSIS
    Remove an installed SDD user module.
.DESCRIPTION
    Reads the module's file list from registry.json, removes all installed files,
    cleans the copilot-instructions supplement block, and updates the registry.
.PARAMETER ModuleName
    Name of the module to remove.
.EXAMPLE
    .\module-remove.ps1 core-be
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory, Position = 0)]
    [string]$ModuleName
)

$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot  = (Resolve-Path (Join-Path $ScriptDir '..\..\')).Path

function Write-Info  { param([string]$Msg) Write-Host "ℹ️  $Msg" -ForegroundColor Blue }
function Write-Ok    { param([string]$Msg) Write-Host "✅ $Msg" -ForegroundColor Green }
function Write-Err   { param([string]$Msg) Write-Host "❌ $Msg" -ForegroundColor Red }
function Write-Warn  { param([string]$Msg) Write-Host "⚠️  $Msg" -ForegroundColor Yellow }

Write-Host ''
Write-Host '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
Write-Host "  🗑️  Removing SDD Module: $ModuleName"
Write-Host '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
Write-Host ''

$Registry = Join-Path $RepoRoot '.sdd-modules\registry.json'

# Verify registry exists
if (-not (Test-Path $Registry)) {
    Write-Err "Registry not found at $Registry"
    exit 1
}

$RegistryData = Get-Content $Registry -Raw | ConvertFrom-Json

# Verify module is installed
$ModuleEntry = $RegistryData.installedModules | Where-Object { $_.name -eq $ModuleName }
if (-not $ModuleEntry) {
    Write-Err "Module '$ModuleName' is not installed"
    exit 1
}

$ModuleVersion = if ($ModuleEntry.version) { $ModuleEntry.version } else { 'unknown' }
Write-Info "Removing module v$ModuleVersion..."

# Remove installed files
$RemovedCount = 0
foreach ($file in $ModuleEntry.files) {
    $FilePath = Join-Path $RepoRoot $file
    if (Test-Path $FilePath) {
        Remove-Item $FilePath -Force
        Write-Info "Removed $file"
        $RemovedCount++
    } else {
        Write-Warn "File not found (already removed?): $file"
    }
}
Write-Ok "Removed $RemovedCount file(s)"

# Remove copilot-instructions supplement block
$CopilotInstructions = Join-Path $RepoRoot '.github\copilot-instructions.md'
if (Test-Path $CopilotInstructions) {
    $Content = Get-Content $CopilotInstructions -Raw
    $BeginMarker = "<!-- BEGIN MODULE: $ModuleName -->"
    $EndMarker   = "<!-- END MODULE: $ModuleName -->"
    if ($Content -match [regex]::Escape($BeginMarker)) {
        $Pattern = "(?s)\r?\n?$([regex]::Escape($BeginMarker)).*?$([regex]::Escape($EndMarker))\r?\n?"
        $Content = [regex]::Replace($Content, $Pattern, '')
        Set-Content -Path $CopilotInstructions -Value $Content -Encoding UTF8 -NoNewline
        Write-Ok 'Removed copilot-instructions supplement block'
    }
}

# Update registry — remove module entry
$RegistryData.installedModules = @($RegistryData.installedModules | Where-Object { $_.name -ne $ModuleName })
$RegistryData | ConvertTo-Json -Depth 10 | Set-Content -Path $Registry -Encoding UTF8
Write-Ok 'Registry updated'

Write-Host ''
Write-Host '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
Write-Ok "Module '$ModuleName' removed successfully ($RemovedCount files)"
Write-Host '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
Write-Host ''
