#Requires -Version 5.1
<#
.SYNOPSIS
    Initialize a new feature directory with templates.
.DESCRIPTION
    Creates .specify/specs/NNN-feature-name/ with ceremony-appropriate templates.
.PARAMETER FeatureName
    Name of the feature (will be slugified).
.PARAMETER Level
    Ceremony level: ultra-light, standard, full (default: standard).
.PARAMETER PO
    Product Owner name (default: from git config).
.PARAMETER Team
    Team name (optional).
.PARAMETER DryRun
    Show what would be created without creating.
.PARAMETER Worktree
    Create an isolated git worktree for this feature.
.EXAMPLE
    .\new-feature.ps1 "user authentication"
    .\new-feature.ps1 -Level ultra-light "fix login typo"
    .\new-feature.ps1 -Level full -PO "John Doe" "microservice migration"
    .\new-feature.ps1 -Worktree "payments reconciliation"
    .\new-feature.ps1 -DryRun "api gateway"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory, Position = 0)]
    [string]$FeatureName,

    [ValidateSet('ultra-light','standard','full')]
    [string]$Level = 'standard',

    [string]$Template,

    [string]$PO,
    [string]$Team,
    [switch]$DryRun,
    [switch]$Worktree,

    [ValidateSet('standard','autonomous-guided','autonomous-governed')]
    [string]$ExecutionMode = 'standard',

    [int]$AutonomyBudget = -1
)

$ErrorActionPreference = 'Stop'

$ScriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot   = (Resolve-Path (Join-Path $ScriptDir '..\..\')).Path
$SpecsDir   = Join-Path $RepoRoot '.specify\specs'
$TemplatesDir = Join-Path $RepoRoot '.specify\templates'
$MemoryDir  = Join-Path $RepoRoot '.specify\memory'
$TargetRepoRoot = $RepoRoot
$TargetSpecsDir = $SpecsDir
$TargetTemplatesDir = $TemplatesDir
$TargetMemoryDir = $MemoryDir

function Write-Info    { param([string]$Msg) Write-Host "ℹ️  $Msg" -ForegroundColor Blue }
function Write-Ok      { param([string]$Msg) Write-Host "✅ $Msg" -ForegroundColor Green }
function Write-Warn    { param([string]$Msg) Write-Host "⚠️  $Msg" -ForegroundColor Yellow }
function Write-Err     { param([string]$Msg) Write-Host "❌ $Msg" -ForegroundColor Red }

function ConvertTo-Slug {
    param([string]$Text)
    $Text.ToLower() -replace '[^a-z0-9-]','-' -replace '-+','-' -replace '^-|-$',''
}

function Get-NextFeatureNumber {
    $max = 0
    if (Test-Path $SpecsDir) {
        Get-ChildItem $SpecsDir -Directory | ForEach-Object {
            if ($_.Name -match '^(\d+)-') {
                $n = [int]$Matches[1]
                if ($n -gt $max) { $max = $n }
            }
        }
    }
    '{0:D3}' -f ($max + 1)
}

function New-FeatureFromTemplate {
    param([string]$TemplatePath, [string]$OutputPath, [string]$Name, [string]$Id, [string]$Slug, [string]$Owner, [string]$Date)
    if (Test-Path $TemplatePath) {
        $content = Get-Content $TemplatePath -Raw
        $content = $content -replace '\[FEATURE_NAME\]', $Name `
                            -replace '\[NNN\]',          $Id `
                            -replace '\[feature-slug\]', $Slug `
                            -replace '\[DATE\]',         $Date `
                            -replace '\[Product Owner Name\]', $Owner `
                            -replace '\[Product Owner name\]', $Owner `
                            -replace '\[Name\]',         $Owner
        Set-Content -Path $OutputPath -Value $content -Encoding UTF8
        Write-Ok "Created $(Split-Path -Leaf $OutputPath)"
    } else {
        Write-Warn "Template not found: $TemplatePath"
    }
}

function Get-BudgetCeiling {
    param([string]$ConstitutionPath)

    $default = 50.00
    if (-not (Test-Path $ConstitutionPath)) { return $default }

    $content = Get-Content $ConstitutionPath -Raw -ErrorAction SilentlyContinue
    if (-not $content) { return $default }

    $m = [regex]::Match($content, '(?im)budget ceiling[^\d]*(\d+(?:\.\d+)?)')
    if (-not $m.Success) { return $default }

    $parsed = 0.0
    if ([double]::TryParse($m.Groups[1].Value, [ref]$parsed)) {
        return [math]::Round($parsed, 2)
    }

    return $default
}

function Invoke-ExtensionHooks {
    param([string]$HookName, [string[]]$HookArgs)

    $extDir = Join-Path $TargetRepoRoot '.sdd-extensions'
    if (-not (Test-Path $extDir)) { return }

    foreach ($extSubDir in Get-ChildItem $extDir -Directory -ErrorAction SilentlyContinue) {
        $manifest = Join-Path $extSubDir.FullName 'sdd-extension.json'
        if (-not (Test-Path $manifest)) { continue }
        try {
            $data = Get-Content $manifest -Raw | ConvertFrom-Json
            $hookScript = $data.hooks.$HookName
            if (-not $hookScript) { continue }
            $hookPath = Join-Path $extSubDir.FullName $hookScript
            if (-not (Test-Path $hookPath)) { continue }
            Write-Info "Running extension hook: $HookName from $($extSubDir.Name)"
            try { & bash $hookPath @HookArgs }
            catch { Write-Warn "Extension hook failed (non-fatal): $hookPath" }
        } catch {
            Write-Warn "Could not parse extension manifest: $manifest"
        }
    }
}

# Defaults
if (-not $PO) {
    try { $PO = (git config user.name 2>$null) } catch {}
    if (-not $PO) { $PO = 'Unknown' }
}

if ($Template) {
    switch ($Template) {
        'minimal'    { $Level = 'ultra-light' }
        'standard'   { $Level = 'standard' }
        'full'       { $Level = 'full' }
        'enterprise' { $Level = 'full' }
        default      { Write-Warn "Unknown template '$Template' - using level '$Level'" }
    }
}

$Slug       = ConvertTo-Slug $FeatureName
$FeatureNum = Get-NextFeatureNumber
$FeatureId  = "$FeatureNum-$Slug"
$Today      = Get-Date -Format 'yyyy-MM-dd'

if ($Worktree) {
    $worktreeScript = Join-Path $ScriptDir 'worktree-create.ps1'
    if (-not (Test-Path $worktreeScript)) {
        throw "Worktree script not found: $worktreeScript"
    }
    & $worktreeScript $FeatureId
    $TargetRepoRoot = Join-Path $RepoRoot ".sdd\worktrees\$FeatureId"
    $TargetSpecsDir = Join-Path $TargetRepoRoot '.specify\specs'
    $TargetTemplatesDir = Join-Path $TargetRepoRoot '.specify\templates'
    $TargetMemoryDir = Join-Path $TargetRepoRoot '.specify\memory'
}

$FeatureDir = Join-Path $TargetSpecsDir $FeatureId

if (-not $DryRun) {
    Invoke-ExtensionHooks -HookName 'before-new-feature' -HookArgs @($FeatureId)
}

Write-Host ''
Write-Host '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
Write-Host '  🚀 New Feature Initialization'
Write-Host '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
Write-Host ''
Write-Info "Feature Name:  $FeatureName"
Write-Info "Feature ID:    $FeatureId"
Write-Info "Directory:     $FeatureDir"
Write-Info "Owner:         $PO"
Write-Info "Date:          $Today"
Write-Info "Ceremony:      $Level"
Write-Info "Execution Mode: $ExecutionMode"
Write-Info "Worktree:      $Worktree"
if ($Template) { Write-Info "Template:      $Template" }
Write-Host ''

if ($DryRun) {
    Write-Warn 'DRY RUN - No files will be created'
    Write-Host ''
    Write-Host 'Would create:'
    Write-Host "  $FeatureDir/"
    Write-Host "  ├── .feature-meta.json       (ceremony: $Level)"
    Write-Host '  ├── cost-log.json            (budget + token/cost entries)'
    if ($Level -eq 'ultra-light') {
        Write-Host '  ├── spec.md                  (minimal)'
        Write-Host '  ├── tasks.md'
        Write-Host '  └── ship-checklist.md'
    } else {
        Write-Host '  ├── business-context.md'
        Write-Host '  ├── spec.md'
        Write-Host '  ├── clarifications.md'
        Write-Host '  ├── plan.md'
        Write-Host '  ├── test-cases.md'
        Write-Host '  ├── tasks.md'
        Write-Host '  ├── analysis-report.md'
        Write-Host '  ├── ship-checklist.md'
        Write-Host '  └── contracts/'
    }
    if ($Worktree) {
        Write-Host "  + git worktree under .sdd/worktrees/$FeatureId"
    }
    Write-Host ''
    return
}

# Validate constitution
$constitution = Join-Path $MemoryDir 'constitution.md'
if (-not (Test-Path $constitution)) {
    Write-Warn "No constitution found at $constitution"
    Write-Warn 'Consider running the Constitution Agent first.'
    $reply = Read-Host 'Continue anyway? [y/N]'
    if ($reply -notmatch '^[Yy]') { return }
}

# Create directories
Write-Info 'Creating directory structure...'
if ($Level -ne 'ultra-light') {
    New-Item -ItemType Directory -Path (Join-Path $FeatureDir 'contracts') -Force | Out-Null
} else {
    New-Item -ItemType Directory -Path $FeatureDir -Force | Out-Null
}

# Resolve autonomy budget default
if ($AutonomyBudget -lt 0) {
    if ($ExecutionMode -eq 'standard') { $AutonomyBudget = 0 } else { $AutonomyBudget = 10 }
}

# Write feature metadata
$meta = [ordered]@{
    featureId                   = $FeatureId
    featureName                 = $FeatureName
    ceremonyLevel               = $Level
    template                    = $(if ($Template) { $Template } else { 'default' })
    owner                       = $PO
    createdAt                   = $Today
    status                      = 'active'
    executionMode               = $ExecutionMode
    autonomyBudget              = $AutonomyBudget
    autonomyMaxIterations       = 3
    escalationThreshold         = 3
    autonomyItemLimit            = 1
    autonomyContextReset        = 'required-per-item'
    autonomyPersistenceRequired = $true
    fallbackExecutionMode       = 'standard'
    lastAutonomyStatus          = 'idle'
} | ConvertTo-Json
Set-Content -Path (Join-Path $FeatureDir '.feature-meta.json') -Value $meta -Encoding UTF8
Write-Ok "Created .feature-meta.json (ceremony: $Level, mode: $ExecutionMode)"

$budgetCeiling = Get-BudgetCeiling -ConstitutionPath $constitution
$costLog = [ordered]@{
    featureId = $FeatureId
    entries = @()
    totalCost = 0.0
    budgetCeiling = $budgetCeiling
} | ConvertTo-Json -Depth 10
Set-Content -Path (Join-Path $FeatureDir 'cost-log.json') -Value $costLog -Encoding UTF8
Write-Ok ("Created cost-log.json (budget ceiling: {0:N2})" -f $budgetCeiling)

# Create files from templates
Write-Info "Creating files from templates (ceremony: $Level)..."

if ($Level -eq 'ultra-light') {
    New-FeatureFromTemplate (Join-Path $TargetTemplatesDir 'spec-template.md')           (Join-Path $FeatureDir 'spec.md')           $FeatureName $FeatureNum $Slug $PO $Today
    New-FeatureFromTemplate (Join-Path $TargetTemplatesDir 'tasks-template.md')          (Join-Path $FeatureDir 'tasks.md')          $FeatureName $FeatureNum $Slug $PO $Today
    New-FeatureFromTemplate (Join-Path $TargetTemplatesDir 'ship-checklist-template.md') (Join-Path $FeatureDir 'ship-checklist.md') $FeatureName $FeatureNum $Slug $PO $Today
} else {
    New-FeatureFromTemplate (Join-Path $TargetTemplatesDir 'business-context-template.md') (Join-Path $FeatureDir 'business-context.md') $FeatureName $FeatureNum $Slug $PO $Today
    New-FeatureFromTemplate (Join-Path $TargetTemplatesDir 'spec-template.md')             (Join-Path $FeatureDir 'spec.md')             $FeatureName $FeatureNum $Slug $PO $Today
    New-FeatureFromTemplate (Join-Path $TargetTemplatesDir 'clarifications-template.md')   (Join-Path $FeatureDir 'clarifications.md')   $FeatureName $FeatureNum $Slug $PO $Today
    New-FeatureFromTemplate (Join-Path $TargetTemplatesDir 'plan-template.md')             (Join-Path $FeatureDir 'plan.md')             $FeatureName $FeatureNum $Slug $PO $Today
    New-FeatureFromTemplate (Join-Path $TargetTemplatesDir 'test-cases-template.md')       (Join-Path $FeatureDir 'test-cases.md')       $FeatureName $FeatureNum $Slug $PO $Today
    New-FeatureFromTemplate (Join-Path $TargetTemplatesDir 'tasks-template.md')            (Join-Path $FeatureDir 'tasks.md')            $FeatureName $FeatureNum $Slug $PO $Today
    New-FeatureFromTemplate (Join-Path $TargetTemplatesDir 'analysis-report-template.md')  (Join-Path $FeatureDir 'analysis-report.md')  $FeatureName $FeatureNum $Slug $PO $Today
    New-FeatureFromTemplate (Join-Path $TargetTemplatesDir 'ship-checklist-template.md')   (Join-Path $FeatureDir 'ship-checklist.md')   $FeatureName $FeatureNum $Slug $PO $Today
}

# Placeholder for contracts (not needed for ultra-light)
if ($Level -ne 'ultra-light') {
    $gitkeep = Join-Path $FeatureDir 'contracts\.gitkeep'
    if (-not (Test-Path $gitkeep)) { New-Item $gitkeep -ItemType File -Force | Out-Null }
}

# Compatibility scaffold for Wave 9 CLI contract.
if (-not (Test-Path (Join-Path $FeatureDir 'design.md'))) {
    $planPath = Join-Path $FeatureDir 'plan.md'
    $designPath = Join-Path $FeatureDir 'design.md'
    if (Test-Path $planPath) {
        Copy-Item $planPath $designPath -Force
    } else {
        @"
# Design: $FeatureName

## Architecture Decisions

- [Add key design decisions]

## Technical Approach

- [Describe implementation approach]
"@ | Set-Content -Path $designPath -Encoding UTF8
    }
    Write-Ok 'Created design.md'
}

if (-not (Test-Path (Join-Path $FeatureDir 'implementation.md'))) {
    @"
# Implementation: $FeatureName

## Plan

- [Implementation steps]

## Progress

- [ ] Step 1

## Notes

- [Add implementation notes]
"@ | Set-Content -Path (Join-Path $FeatureDir 'implementation.md') -Encoding UTF8
    Write-Ok 'Created implementation.md'
}

# Reset session state for new feature (Wave 8: structured memory)
$sessionState = Join-Path $TargetMemoryDir 'session-state.md'
if (Test-Path $sessionState) {
    $ssContent = Get-Content $sessionState -Raw
    $ssContent = $ssContent -replace '(?m)^- \*\*Feature ID:\*\* .*', "- **Feature ID:** $FeatureId"
    $ssContent = $ssContent -replace '(?m)^- \*\*Feature Name:\*\* .*', "- **Feature Name:** $FeatureName"
    $ssContent = $ssContent -replace '(?m)^- \*\*Ceremony Level:\*\* .*', "- **Ceremony Level:** $Level"
    $ssContent = $ssContent -replace '(?m)^- \*\*Current Phase:\*\* .*', '- **Current Phase:** Phase 1'
    $ssContent = $ssContent -replace '(?m)^- \*\*Last Gate Passed:\*\* .*', '- **Last Gate Passed:** —'
    $ssContent = $ssContent -replace '(?m)^- \*\*Last Gate Timestamp:\*\* .*', '- **Last Gate Timestamp:** —'
    $ssContent = $ssContent -replace '(?m)^- \[x\]', '- [ ]'
    Set-Content -Path $sessionState -Value $ssContent -Encoding UTF8 -NoNewline
}

Write-Host ''
Write-Host '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
Write-Ok "Feature $FeatureId initialized successfully! (ceremony: $Level)"

Invoke-ExtensionHooks -HookName 'after-new-feature' -HookArgs @($FeatureId)

Write-Host ''
Write-Host "  📂 $FeatureDir"
Write-Host ''

if ($Level -eq 'ultra-light') {
    Write-Host '  Next steps (ultra-light — skip Phases 1-2):'
    Write-Host '  1. Fill in spec.md with the quick scope'
    Write-Host '  2. Generate tasks: @software-engineer (Planning mode)'
    Write-Host '  3. Implement: @test-engineer → @software-engineer'
    Write-Host "  4. Review: @review → validate-gate.ps1 $FeatureId 4"
} elseif ($Level -eq 'full') {
    Write-Host '  Next steps (full ceremony — all phases + extra review):'
    Write-Host '  1. Work with PO to complete business-context.md'
    Write-Host '  2. Run: @requirement-analyst with vision mode'
    Write-Host '  3. Mandatory clarification: @clarification'
    Write-Host '  4. Full pipeline through all gates with extra review'
} else {
    Write-Host '  Next steps:'
    Write-Host '  1. Work with PO to complete business-context.md'
    Write-Host '  2. Run: @requirement-analyst with vision mode'
    Write-Host '  3. After PO approval, elaborate spec.md with FA'
}
Write-Host ''
Write-Host '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
