#Requires -Version 5.1
<#
.SYNOPSIS
    Pull GitHub/GitLab issue states back into tasks.md.

.DESCRIPTION
    Reads .specify/specs/<feature>/issue-map.json, queries issue states,
    and updates checkbox states in tasks.md accordingly.

.PARAMETER FeatureId
    The feature ID (e.g. 001-user-auth)

.EXAMPLE
    .\issues-to-tasks.ps1 001-user-auth
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$FeatureId
)

$ErrorActionPreference = 'Stop'

$ScriptDir    = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot     = (Resolve-Path (Join-Path $ScriptDir '..\..')).Path

function Write-Info { param([string]$Msg) Write-Host "ℹ️  $Msg" -ForegroundColor Blue }
function Write-Ok   { param([string]$Msg) Write-Host "✅ $Msg" -ForegroundColor Green }
function Write-Warn { param([string]$Msg) Write-Host "⚠️  $Msg" -ForegroundColor Yellow }
function Write-Err  { param([string]$Msg) Write-Host "❌ $Msg" -ForegroundColor Red }

function Test-FeatureId {
    param([string]$Value)

    if ($Value -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]*$') {
        Write-Err "Invalid feature ID: $Value"
        Write-Err 'Feature ID may only contain letters, numbers, dot, underscore, and hyphen.'
        exit 2
    }
}

Test-FeatureId -Value $FeatureId

$FeatureDir   = Join-Path $RepoRoot ".specify\specs\$FeatureId"
$TasksFile    = Join-Path $FeatureDir 'tasks.md'
$IssueMapFile = Join-Path $FeatureDir 'issue-map.json'

if (-not (Test-Path $TasksFile))    { Write-Err "Tasks file not found: $TasksFile"; exit 2 }
if (-not (Test-Path $IssueMapFile)) { Write-Err "Issue map not found: $IssueMapFile`nRun tasks-to-issues.ps1 first."; exit 2 }

function Get-IssueTracker {
    $constitution = Join-Path $RepoRoot '.specify\memory\constitution.md'
    if ((Test-Path $constitution) -and (Get-Content $constitution -Raw) -match '(?i)gitlab') { return 'gitlab' }
    return 'github'
}

$Tracker  = Get-IssueTracker
Write-Info "Issue tracker: $Tracker"

$IssueMap = @{}
try { $IssueMap = Get-Content $IssueMapFile -Raw | ConvertFrom-Json -AsHashtable } catch { $IssueMap = @{} }

function Get-GitHubIssueState {
    param([int]$IssueNum)
    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { return 'unknown' }
    try { return (gh issue view $IssueNum --json state -q '.state' 2>/dev/null).ToLower() } catch { return 'unknown' }
}

function Get-GitLabIssueState {
    param([int]$IssueNum)
    if (Get-Command glab -ErrorAction SilentlyContinue) {
        try {
            $out = glab issue view $IssueNum --output json 2>/dev/null | ConvertFrom-Json
            return $out.state
        } catch { return 'unknown' }
    } elseif ($env:GITLAB_TOKEN -and $env:GITLAB_PROJECT_ID) {
        $gitlabUrl = if ($env:GITLAB_URL) { $env:GITLAB_URL } else { 'https://gitlab.com' }
        try {
            $resp = Invoke-RestMethod -Uri "$gitlabUrl/api/v4/projects/$($env:GITLAB_PROJECT_ID)/issues/$IssueNum" `
                -Headers @{ 'PRIVATE-TOKEN' = $env:GITLAB_TOKEN }
            return $resp.state
        } catch { return 'unknown' }
    }
    return 'unknown'
}

Write-Info "Syncing issue states back to: $TasksFile"
$TasksLines = Get-Content $TasksFile
$Updated = 0

foreach ($TaskId in $IssueMap.Keys) {
    $IssueNum = $IssueMap[$TaskId]

    $State = if ($Tracker -eq 'github') {
        Get-GitHubIssueState -IssueNum $IssueNum
    } else {
        Get-GitLabIssueState -IssueNum $IssueNum
    }

    Write-Info "Task $TaskId (issue #$IssueNum): $State"

    for ($i = 0; $i -lt $TasksLines.Count; $i++) {
        if ($TasksLines[$i] -match [regex]::Escape($TaskId)) {
            if ($State -eq 'closed' -and $TasksLines[$i] -match '^\s*- \[ \]') {
                $TasksLines[$i] = $TasksLines[$i] -replace '^\s*- \[ \]', '- [x]'
                $Updated++
            } elseif ($State -eq 'open' -and $TasksLines[$i] -match '^\s*- \[x\]') {
                $TasksLines[$i] = $TasksLines[$i] -replace '^\s*- \[x\]', '- [ ]'
                $Updated++
            }
        }
    }
}

$TasksLines | Set-Content $TasksFile
Write-Ok "Updated $Updated task(s) in: $TasksFile"
