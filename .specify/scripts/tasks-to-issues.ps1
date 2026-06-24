#Requires -Version 5.1
<#
.SYNOPSIS
    Push tasks.md entries to GitHub/GitLab Issues.

.DESCRIPTION
    Reads .specify/specs/<feature>/tasks.md and creates issues in GitHub or GitLab
    for each task. Writes a .specify/specs/<feature>/issue-map.json with the mapping.

.PARAMETER FeatureId
    The feature ID (e.g. 001-user-auth)

.EXAMPLE
    .\tasks-to-issues.ps1 001-user-auth
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$FeatureId
)

$ErrorActionPreference = 'Stop'

$ScriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot   = (Resolve-Path (Join-Path $ScriptDir '..\..')).Path

function Write-Info    { param([string]$Msg) Write-Host "ℹ️  $Msg" -ForegroundColor Blue }
function Write-Ok      { param([string]$Msg) Write-Host "✅ $Msg" -ForegroundColor Green }
function Write-Warn    { param([string]$Msg) Write-Host "⚠️  $Msg" -ForegroundColor Yellow }
function Write-Err     { param([string]$Msg) Write-Host "❌ $Msg" -ForegroundColor Red }

function Test-FeatureId {
    param([string]$Value)

    if ($Value -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]*$') {
        Write-Err "Invalid feature ID: $Value"
        Write-Err 'Feature ID may only contain letters, numbers, dot, underscore, and hyphen.'
        exit 2
    }
}

Test-FeatureId -Value $FeatureId

$FeatureDir = Join-Path $RepoRoot ".specify\specs\$FeatureId"
$TasksFile  = Join-Path $FeatureDir 'tasks.md'
$IssueMapFile = Join-Path $FeatureDir 'issue-map.json'

if (-not (Test-Path $TasksFile)) {
    Write-Err "Tasks file not found: $TasksFile"
    exit 2
}

# Detect issue tracker from constitution
function Get-IssueTracker {
    $constitution = Join-Path $RepoRoot '.specify\memory\constitution.md'
    if ((Test-Path $constitution) -and (Get-Content $constitution -Raw) -match '(?i)gitlab') {
        return 'gitlab'
    }
    return 'github'
}

$Tracker = Get-IssueTracker
Write-Info "Issue tracker: $Tracker"

# Load or initialize issue map
$IssueMap = @{}
if (Test-Path $IssueMapFile) {
    try { $IssueMap = Get-Content $IssueMapFile -Raw | ConvertFrom-Json -AsHashtable } catch { $IssueMap = @{} }
}

function Push-ToGitHub {
    param([string]$TaskLine)
    # Strip checkbox markers (- [ ] or - [x]) before extracting task ID/description
    $CleanedLine = $TaskLine -replace '^\s*- \[[xX ]\] ', ''
    if ($CleanedLine -notmatch '([A-Z]+-[0-9]+)') { Write-Warn "No task ID in: $TaskLine"; return }
    $TaskId   = $Matches[1]
    $TaskDesc = $CleanedLine -replace '^[A-Z]+-[0-9]+:\s*', ''
    $Title    = "[$FeatureId] ${TaskId}: $TaskDesc"

    if ($IssueMap.ContainsKey($TaskId)) {
        Write-Info "Task $TaskId already mapped to issue #$($IssueMap[$TaskId]) — skipping"
        return
    }

    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
        Write-Warn "gh CLI not found — cannot create GitHub issue for $TaskId"
        return
    }

    Write-Info "Creating GitHub issue for $TaskId..."
    try {
        $output = gh issue create --title $Title --body "Feature: $FeatureId`nTask: $TaskId`n`n$TaskDesc" --label 'sdd-task' 2>&1
        if ($output -match '(\d+)$') {
            $IssueNum = [int]$Matches[1]
            $IssueMap[$TaskId] = $IssueNum
            Write-Ok "Created issue #$IssueNum for $TaskId"
        }
    } catch { Write-Warn "Failed to create GitHub issue for $TaskId: $_" }
}

function Push-ToGitLab {
    param([string]$TaskLine)
    # Strip checkbox markers (- [ ] or - [x]) before extracting task ID/description
    $CleanedLine = $TaskLine -replace '^\s*- \[[xX ]\] ', ''
    if ($CleanedLine -notmatch '([A-Z]+-[0-9]+)') { Write-Warn "No task ID in: $TaskLine"; return }
    $TaskId   = $Matches[1]
    $TaskDesc = $CleanedLine -replace '^[A-Z]+-[0-9]+:\s*', ''
    $Title    = "[$FeatureId] ${TaskId}: $TaskDesc"

    if ($IssueMap.ContainsKey($TaskId)) {
        Write-Info "Task $TaskId already mapped to issue #$($IssueMap[$TaskId]) — skipping"
        return
    }

    if (Get-Command glab -ErrorAction SilentlyContinue) {
        Write-Info "Creating GitLab issue for $TaskId via glab..."
        try {
            $output = glab issue create --title $Title --description "Feature: $FeatureId`nTask: $TaskId`n`n$TaskDesc" 2>&1
            if ($output -match '#(\d+)') {
                $IssueNum = [int]$Matches[1]
                $IssueMap[$TaskId] = $IssueNum
                Write-Ok "Created issue #$IssueNum for $TaskId"
            }
        } catch { Write-Warn "Failed to create GitLab issue: $_" }
    } elseif ($env:GITLAB_TOKEN -and $env:GITLAB_PROJECT_ID) {
        Write-Info "Creating GitLab issue for $TaskId via REST API..."
        $gitlabUrl = if ($env:GITLAB_URL) { $env:GITLAB_URL } else { 'https://gitlab.com' }
        $body = @{ title = $Title; description = "Feature: $FeatureId`nTask: $TaskId" } | ConvertTo-Json
        try {
            $resp = Invoke-RestMethod -Uri "$gitlabUrl/api/v4/projects/$($env:GITLAB_PROJECT_ID)/issues" `
                -Method POST -Headers @{ 'PRIVATE-TOKEN' = $env:GITLAB_TOKEN } `
                -ContentType 'application/json' -Body $body
            $IssueMap[$TaskId] = $resp.iid
            Write-Ok "Created issue #$($resp.iid) for $TaskId"
        } catch { Write-Warn "Failed to create GitLab issue: $_" }
    } else {
        Write-Warn "No GitLab CLI or GITLAB_TOKEN+GITLAB_PROJECT_ID — skipping $TaskId"
    }
}

# Main loop
Write-Info "Reading tasks from: $TasksFile"
$TaskCount = 0
$taskPattern = '^\s*- \[[ xX]\] '
Get-Content $TasksFile | Where-Object { $_ -match $taskPattern } | ForEach-Object {
    $line = $_ -replace '^\s*- \[[ xX]\] ', ''
    if ($Tracker -eq 'github') { Push-ToGitHub $line } else { Push-ToGitLab $line }
    $TaskCount++
}

# Save updated issue map
$IssueMap | ConvertTo-Json -Depth 5 | Set-Content $IssueMapFile
Write-Ok "Issue map saved to: $IssueMapFile"
Write-Ok "Processed $TaskCount task(s)"
