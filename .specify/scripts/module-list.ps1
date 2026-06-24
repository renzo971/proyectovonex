#Requires -Version 5.1
<#
.SYNOPSIS
    List installed SDD user modules.
.DESCRIPTION
    Reads registry.json and displays installed modules with metadata.
.EXAMPLE
    .\module-list.ps1
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot  = (Resolve-Path (Join-Path $ScriptDir '..\..\')).Path

$Registry = Join-Path $RepoRoot '.sdd-modules\registry.json'

Write-Host ''
Write-Host '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
Write-Host '  📋 Installed SDD Modules'
Write-Host '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
Write-Host ''

if (-not (Test-Path $Registry)) {
    Write-Host "ℹ️  No registry found. Run 'sdd init' first." -ForegroundColor Blue
    exit 0
}

$RegistryData = Get-Content $Registry -Raw | ConvertFrom-Json
$Modules = @($RegistryData.installedModules)

if ($Modules.Count -eq 0) {
    Write-Host "ℹ️  No modules installed." -ForegroundColor Blue
    Write-Host ''
    Write-Host '  Install a module with: sdd module install <name>'
    Write-Host ''
    exit 0
}

Write-Host "$($Modules.Count) module(s) installed:" -ForegroundColor Green
Write-Host ''

$Format = '  {0,-25} {1,-10} {2,-25} {3}'
Write-Host ($Format -f 'NAME', 'VERSION', 'INSTALLED', 'FILES')
Write-Host ($Format -f ('─' * 25), ('─' * 10), ('─' * 25), '─────')

foreach ($mod in $Modules) {
    $fileCount = @($mod.files).Count
    Write-Host ($Format -f $mod.name, $mod.version, $mod.installedAt, $fileCount)
}

Write-Host ''
Write-Host '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
Write-Host ''
