#Requires -Version 5.1
param(
    [Parameter(Mandatory, Position = 0)]
    [string]$FeatureId,

    [string]$Base
)

$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = (Resolve-Path (Join-Path $ScriptDir '..\..')).Path

if (-not $Base) {
    $Base = (git -C $RepoRoot symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>$null) -replace '^origin/',''
    if (-not $Base) { $Base = 'main' }
}

$branchName = "feature/$FeatureId"
$worktreePath = Join-Path $RepoRoot ".sdd\worktrees\$FeatureId"
$operationalPaths = @(
    '.specify/memory/session-state.md',
    '.specify/memory/metrics-log.md',
    '.specify/checkpoints'
)

git -C $RepoRoot show-ref --verify --quiet "refs/heads/$branchName" 2>$null
if ($LASTEXITCODE -ne 0) {
    throw "Feature branch not found: $branchName"
}

$dirty = git -C $RepoRoot status --porcelain -- . ':(exclude).sdd/worktrees'
if ($dirty) {
    throw 'Repository has uncommitted changes. Commit or stash before shipping.'
}

git -C $RepoRoot checkout $Base
$null = git -C $RepoRoot merge --squash $branchName 2>$null
$mergeRc = $LASTEXITCODE

foreach ($path in $operationalPaths) {
    git -C $RepoRoot restore --source=$Base --staged --worktree -- $path 2>$null | Out-Null
}

$unmerged = git -C $RepoRoot diff --name-only --diff-filter=U
if ($unmerged) {
    throw "Unresolved merge conflicts after squash merge:`n$unmerged"
}

git -C $RepoRoot commit -m "feat: ship $FeatureId"

if (Test-Path $worktreePath) {
    git -C $RepoRoot worktree remove $worktreePath
}

git -C $RepoRoot branch -D $branchName

Write-Host "Shipped $FeatureId into $Base"
Write-Host "Removed worktree: $worktreePath"
Write-Host "Deleted branch: $branchName"
