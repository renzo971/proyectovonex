#Requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(Mandatory, Position = 0)]
    [string]$SkillName,
    [switch]$Rationalizations
)

$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = (Resolve-Path (Join-Path $ScriptDir '..\..')).Path
$SkillFile = Join-Path $RepoRoot ('.specify\skills\' + $SkillName + '.skill.md')

if (-not (Test-Path $SkillFile)) {
    Write-Error "Skill not found: $SkillName"
    exit 1
}

$content = Get-Content $SkillFile -Raw
if ($content -notmatch '(?m)^#\s+') {
    Write-Error 'Invalid skill: missing title header'
    exit 1
}
if ($content -notmatch 'Purpose:') {
    Write-Error 'Invalid skill: missing Purpose section'
    exit 1
}

if ($Rationalizations) {
    if ($content -notmatch '(?m)^## Common Rationalizations') {
        Write-Error "Skill '$SkillName' is missing '## Common Rationalizations' section (required by skill-authoring.instructions.md)"
        exit 1
    }
    # Check section is non-empty (has at least one table row)
    if ($content -notmatch '(?ms)## Common Rationalizations.*\|') {
        Write-Error "Skill '$SkillName': '## Common Rationalizations' section exists but appears empty"
        exit 1
    }
    Write-Host "  PASS: '## Common Rationalizations' section present and non-empty"
}

Write-Host "Skill validation passed: $SkillName"
exit 0
