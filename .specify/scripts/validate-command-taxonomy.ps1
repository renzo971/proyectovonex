#Requires -Version 5.1
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = (Resolve-Path (Join-Path $ScriptDir '..\..')).Path
$taxonomyPath = Join-Path $RepoRoot '.specify\command-taxonomy.json'

if (-not (Test-Path $taxonomyPath)) {
    Write-Error "Missing taxonomy file: $taxonomyPath"
    exit 1
}

$taxonomy = Get-Content $taxonomyPath -Raw | ConvertFrom-Json
$errors = New-Object System.Collections.Generic.List[string]

if (-not $taxonomy.commandPhaseMap -or $taxonomy.commandPhaseMap.Count -eq 0) {
    $errors.Add('commandPhaseMap must be a non-empty list')
}

$seen = @{}
foreach ($item in $taxonomy.commandPhaseMap) {
    $id = [string]$item.id
    $phase = [string]$item.phase
    $prompt = [string]$item.prompt

    if ([string]::IsNullOrWhiteSpace($id)) {
        $errors.Add('commandPhaseMap item missing id')
        continue
    }
    if ($seen.ContainsKey($id)) {
        $errors.Add("Command appears multiple times in commandPhaseMap: $id")
    }
    $seen[$id] = $true

    if ([string]::IsNullOrWhiteSpace($phase)) {
        $errors.Add("Missing phase for command: $id")
    }
    if ([string]::IsNullOrWhiteSpace($prompt)) {
        $errors.Add("Missing prompt for command: $id")
    } else {
        $promptPath = Join-Path $RepoRoot ('.github\prompts\' + $prompt)
        if (-not (Test-Path $promptPath)) {
            $errors.Add("Missing curated prompt file: $prompt")
        }
    }
}

if (-not $taxonomy.curatedPrompts -or $taxonomy.curatedPrompts.Count -ne 8) {
    $errors.Add('curatedPrompts must contain exactly 8 prompt files')
}

foreach ($prompt in $taxonomy.curatedPrompts) {
    $promptPath = Join-Path $RepoRoot ('.github\prompts\' + [string]$prompt)
    if (-not (Test-Path $promptPath)) {
        $errors.Add("Prompt listed in curatedPrompts does not exist: $prompt")
    }
}

foreach ($skill in $taxonomy.skillPhaseMap) {
    $skillId = [string]$skill.id
    if ([string]::IsNullOrWhiteSpace($skillId)) {
        $errors.Add('skillPhaseMap item missing id')
        continue
    }
    $skillPath = Join-Path $RepoRoot ('.github\skills\' + $skillId + '\SKILL.md')
    if (-not (Test-Path $skillPath)) {
        $errors.Add("Missing curated skill: $skillId")
    }
}

if ($errors.Count -gt 0) {
    Write-Error 'Command taxonomy mapping validation failed:'
    foreach ($err in $errors) {
        Write-Error "- $err"
    }
    exit 1
}

Write-Host 'Command taxonomy mapping validation passed'
exit 0
