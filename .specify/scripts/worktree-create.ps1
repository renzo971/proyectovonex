#Requires -Version 5.1
param(
    [Parameter(Mandatory, Position = 0)]
    [string]$FeatureId
)

$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = (Resolve-Path (Join-Path $ScriptDir '..\..')).Path

$worktreeRoot = Join-Path $RepoRoot '.sdd\worktrees'
$worktreePath = Join-Path $worktreeRoot $FeatureId
$branchName = "feature/$FeatureId"

if (-not (git -C $RepoRoot rev-parse --is-inside-work-tree 2>$null)) {
    throw "Not a git repository: $RepoRoot"
}

New-Item -ItemType Directory -Path $worktreeRoot -Force | Out-Null

if (Test-Path $worktreePath) {
    Write-Host "Worktree already exists: $worktreePath"
    exit 0
}

git -C $RepoRoot show-ref --verify --quiet "refs/heads/$branchName" 2>$null
if ($LASTEXITCODE -eq 0) {
    git -C $RepoRoot worktree add $worktreePath $branchName
} else {
    git -C $RepoRoot worktree add $worktreePath -b $branchName
}

Write-Host "Created worktree: $worktreePath"
Write-Host "Branch: $branchName"
