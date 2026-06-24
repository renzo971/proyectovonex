#Requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(Mandatory, Position = 0)]
    [string]$SkillName,

    [Parameter(Mandatory, Position = 1)]
    [string]$FeatureId,

    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = (Resolve-Path (Join-Path $ScriptDir '..\..')).Path
$FeatureDir = Join-Path $RepoRoot ('.specify\specs\' + $FeatureId)

if (-not (Test-Path $FeatureDir)) {
    Write-Error "Feature not found: $FeatureId"
    exit 1
}

$skillPathGithub = Join-Path $RepoRoot ('.github\skills\' + $SkillName + '\SKILL.md')
$skillPathLocal = Join-Path $RepoRoot ('.specify\skills\' + $SkillName + '.skill.md')
$skillFile = $null
if (Test-Path $skillPathGithub) {
    $skillFile = $skillPathGithub
} elseif (Test-Path $skillPathLocal) {
    $skillFile = $skillPathLocal
} else {
    Write-Error "Skill not found: $SkillName"
    exit 1
}

Write-Host '== Skill Execution =='
Write-Host "Skill: $SkillName"
Write-Host "Feature: $FeatureId"
Write-Host "Skill file: $skillFile"
Write-Host ''

Write-Host '[Checks]'
foreach ($required in @('spec.md', 'plan.md', 'tasks.md')) {
    $path = Join-Path $FeatureDir $required
    if (Test-Path $path) {
        Write-Host "- $required`: present"
    } else {
        Write-Host "- $required`: missing"
    }
}
Write-Host ''

Write-Host '[Plan]'
Get-Content $skillFile | Select-String -Pattern 'Execution Plan|Flow|Checklist|Steps|^[0-9]+\.'
Write-Host ''

if ($DryRun) {
    Write-Host 'DRY-RUN: no command was executed.'
    exit 0
}

Write-Host '[Execution]'
Write-Host 'Execution is policy-driven: apply actions manually or via dedicated automation for this skill.'
Write-Host 'Completed: deterministic skill run context emitted.'
exit 0
