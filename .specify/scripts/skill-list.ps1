#Requires -Version 5.1
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = (Resolve-Path (Join-Path $ScriptDir '..\..')).Path
$SkillsDir = Join-Path $RepoRoot '.specify\skills'

if (-not (Test-Path $SkillsDir)) {
    Write-Error "Skills directory not found: $SkillsDir"
    exit 1
}

Get-ChildItem $SkillsDir -File -Filter '*.skill.md' |
    Sort-Object Name |
    ForEach-Object { $_.BaseName -replace '\.skill$','' }
