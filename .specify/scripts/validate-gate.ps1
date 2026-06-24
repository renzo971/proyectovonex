#Requires -Version 5.1
<#
.SYNOPSIS
    Validate gate criteria for a feature.
.DESCRIPTION
    Gates:
      1 - Three Amigos Review (spec complete)
      2 - Technical Alignment (design complete)
      3 - Implementation Gate (tests & tasks ready)
      4 - Ship Gate (everything complete)
.PARAMETER FeatureId
    Feature directory name (e.g., 001-user-auth).
.PARAMETER GateNumber
    Gate to validate (1, 2, 3, or 4).
.PARAMETER Verbose
    Show detailed checks.
.EXAMPLE
    .\validate-gate.ps1 001-user-auth 1
    .\validate-gate.ps1 001-user-auth 4
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory, Position = 0)]
    [string]$FeatureId,

    [Parameter(Mandatory, Position = 1)]
    [ValidateRange(1,4)]
    [int]$GateNumber
)

$ErrorActionPreference = 'Stop'

$ScriptDir      = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot       = (Resolve-Path (Join-Path $ScriptDir '..\..\')).Path
$SpecsDir       = Join-Path $RepoRoot '.specify\specs'
$MemoryDir      = Join-Path $RepoRoot '.specify\memory'
$CheckpointsDir = Join-Path $RepoRoot '.specify\checkpoints'
$ConfigFile     = Join-Path $RepoRoot '.specify\config.json'

# ── Helper functions ──────────────────────────────────────────────────

function Write-Info  { param([string]$Msg) Write-Host "ℹ️  $Msg" -ForegroundColor Blue }
function Write-Ok    { param([string]$Msg) Write-Host "✅ $Msg" -ForegroundColor Green }
function Write-Warn  { param([string]$Msg) Write-Host "⚠️  $Msg" -ForegroundColor Yellow }
function Write-Err   { param([string]$Msg) Write-Host "❌ $Msg" -ForegroundColor Red }
function Write-Check { param([string]$Msg) Write-Host "   ↳ $Msg" -ForegroundColor Cyan }

function Test-FileExists {
    param([string]$Path, [string]$Desc)
    if (Test-Path $Path) { Write-Ok "$Desc exists"; return $true }
    Write-Err "$Desc MISSING"; return $false
}

function Test-FileNotTemplate {
    param([string]$Path, [string]$Desc)
    if (-not (Test-Path $Path)) { return $false }
    $c = Get-Content $Path -Raw
    if ($c -match '\[FEATURE_NAME\]|\[NNN\]|\[DATE\]|<!-- INSTRUCTION -->') {
        Write-Warn "$Desc contains template placeholders"; return $false
    }
    if ($c -match '(?m)^\*\*Status:\*\*.*\|.*\|') {
        Write-Warn "$Desc is still a template (Status field not filled)"; return $false
    }
    if ($c -match '\[Story [Tt]itle\]|\[Describe |\[Add ') {
        Write-Warn "$Desc contains unfilled template placeholders"; return $false
    }
    $contentLines = ($c -split "`n" | Where-Object { $_ -notmatch '^\s*$|^#|^-' }).Count
    if ($contentLines -lt 5) { Write-Warn "$Desc appears to be mostly empty"; return $false }
    return $true
}

function Test-AcceptanceCriteria {
    param([string]$SpecFile)
    if (-not (Test-Path $SpecFile)) { return $false }
    $c = Get-Content $SpecFile -Raw
    $acCount = ([regex]::Matches($c, 'AC-\d+')).Count
    if ($acCount -lt 1) { Write-Err 'No acceptance criteria found in spec.md'; return $false }
    Write-Check "Found $acCount acceptance criteria"
    return $true
}

function Test-UserStories {
    param([string]$SpecFile)
    if (-not (Test-Path $SpecFile)) { return $false }
    $usCount = ([regex]::Matches((Get-Content $SpecFile -Raw), '(?m)^#{2,4}\s+US-\d+')).Count
    if ($usCount -lt 1) { Write-Err 'No user stories found in spec.md'; return $false }
    Write-Check "Found $usCount user stories"
    return $true
}

function Test-USInPlan {
    param([string]$SpecFile, [string]$PlanFile)
    if (-not (Test-Path $SpecFile) -or -not (Test-Path $PlanFile)) { return $false }
    $specC = Get-Content $SpecFile -Raw
    $planC = Get-Content $PlanFile -Raw
    $ids = [regex]::Matches($specC, 'US-\d{3}') | ForEach-Object { $_.Value } | Sort-Object -Unique
    if ($ids.Count -eq 0) { Write-Warn 'No US-XXX IDs found in spec.md'; return $true }
    $found = 0; $missing = @()
    foreach ($id in $ids) {
        if ($planC -match [regex]::Escape($id)) { $found++ } else { $missing += $id }
    }
    if ($missing.Count -gt 0) { Write-Err "User stories NOT in plan.md: $($missing -join ', ')" }
    Write-Check "Spec → Plan traceability: $found/$($ids.Count) user stories"
    return ($found -eq $ids.Count)
}

function Test-TestCoverage {
    param([string]$TestFile, [string]$SpecFile)
    if (-not (Test-Path $TestFile) -or -not (Test-Path $SpecFile)) { return $false }
    $specC = Get-Content $SpecFile -Raw
    $testC = Get-Content $TestFile -Raw
    $ids = [regex]::Matches($specC, 'US-\d+') | ForEach-Object { $_.Value } | Sort-Object -Unique
    $found = 0; $missing = @()
    foreach ($id in $ids) {
        if ($testC -match [regex]::Escape($id)) { $found++ } else { $missing += $id }
    }
    if ($missing.Count -gt 0) { Write-Warn "Missing test coverage for: $($missing -join ', ')" }
    Write-Check "Test coverage: $found/$($ids.Count) user stories"
    return ($found -eq $ids.Count)
}

function Test-TasksCoverage {
    param([string]$TasksFile)
    if (-not (Test-Path $TasksFile)) { return $false }
    $taskCount = ([regex]::Matches((Get-Content $TasksFile -Raw), '(?m)^\s*-\s*\[.\]\s*T\d+|^### T\d+')).Count
    if ($taskCount -lt 1) { Write-Err 'No tasks found in tasks.md'; return $false }
    Write-Check "Found $taskCount tasks"
    return $true
}

function Test-NeedsClarificationMarkers {
    param([string]$Dir, [int]$MaxPerFile = 3)
    $errors = 0; $total = 0
    Write-Info 'Checking [NEEDS CLARIFICATION] markers:'
    Get-ChildItem $Dir -Filter '*.md' | ForEach-Object {
        $count = ([regex]::Matches((Get-Content $_.FullName -Raw), '\[NEEDS CLARIFICATION:')).Count
        $total += $count
        if ($count -gt $MaxPerFile) {
            Write-Err "$($_.Name) has $count [NEEDS CLARIFICATION] markers (max $MaxPerFile)"
            $errors++
        } elseif ($count -gt 0) {
            Write-Warn "$($_.Name) has $count [NEEDS CLARIFICATION] marker(s)"
        }
    }
    if ($total -eq 0) { Write-Ok 'No unresolved [NEEDS CLARIFICATION] markers' }
    else              { Write-Check "Total markers: $total" }
    return ($errors -eq 0)
}

function Test-AnalysisStatus {
    param([string]$AnalysisFile)
    if (-not (Test-Path $AnalysisFile)) { return $false }
    $c = Get-Content $AnalysisFile -Raw
    if ($c -match '(?i)Verdict:\s*PASS\b') { Write-Ok 'Analysis verdict: PASS'; return $true }
    if ($c -match '(?i)Verdict:\s*PASS WITH WARNINGS') { Write-Warn 'Analysis verdict: PASS WITH WARNINGS'; return $true }
    Write-Err 'Analysis verdict: FAIL or not determined'; return $false
}

function Test-ShipChecklist {
    param([string]$ChecklistFile)
    if (-not (Test-Path $ChecklistFile)) { return $false }
    $c = Get-Content $ChecklistFile -Raw
    $total     = ([regex]::Matches($c, '(?m)^\s*-\s*\[.\]')).Count
    $completed = ([regex]::Matches($c, '(?m)^\s*-\s*\[[xX]\]')).Count
    Write-Check "Checklist: $completed/$total items complete"
    return ($completed -ge $total)
}

# ── Goal-Backward Verification (Wave 8) ──────────────────────────────

function Test-GoalBackward {
    param([string]$Dir)
    $analysisFile = Join-Path $Dir 'analysis-report.md'
    $bizContext = Join-Path $Dir 'business-context.md'

    if (-not (Test-Path $analysisFile) -or -not (Test-Path $bizContext)) {
        Write-Warn 'Cannot verify goal-backward: missing analysis-report.md or business-context.md'
        return $true
    }

    $content = Get-Content $analysisFile -Raw
    if ($content -notmatch 'Goal-Backward Verification') {
        Write-Err "Analysis report missing 'Goal-Backward Verification' section"
        Write-Check 'Re-run Analysis agent to generate backward verification'
        return $false
    }

    if ($content -match '(?i)Backward Verification Verdict.*GOAL DRIFT') {
        Write-Err 'Goal-backward verification detected GOAL DRIFT'
        return $false
    }

    if ($content -match '(?i)Backward Verification Verdict.*PARTIAL') {
        Write-Warn 'Goal-backward verification: PARTIAL coverage (review gaps)'
        return $true
    }

    Write-Ok 'Goal-backward verification: ALL GOALS ACHIEVED'
    return $true
}

# ── Stuck detection (Wave 8) ─────────────────────────────────────────

function Test-StuckDetection {
    param([string]$Dir, [int]$Gate)
    $featureId = Split-Path $Dir -Leaf
    $stuckDir = Join-Path $CheckpointsDir 'stuck-history'
    if (-not (Test-Path $stuckDir)) { New-Item -ItemType Directory -Path $stuckDir -Force | Out-Null }
    $historyFile = Join-Path $stuckDir "$featureId-gate$Gate.checksums"

    $currentChecksums = ''
    Get-ChildItem $Dir -Filter '*.md' -ErrorAction SilentlyContinue | ForEach-Object {
        $hash = (Get-FileHash $_.FullName -Algorithm MD5).Hash
        $currentChecksums += "$($_.Name):$hash`n"
    }

    if (Test-Path $historyFile) {
        $previous = (Get-Content $historyFile -Raw).TrimEnd()
        if ($currentChecksums.TrimEnd() -eq $previous) {
            Write-Warn 'STUCK DETECTED: Artifact checksums unchanged since last gate validation'
            Write-Check 'Agents may be producing the same output. Review artifacts manually.'
        }
    }

    Set-Content -Path $historyFile -Value $currentChecksums -Encoding UTF8 -NoNewline
}

function Invoke-ExtensionHooks {
    param([string]$HookName, [string[]]$HookArgs)
    $ExtDir = Join-Path $RepoRoot '.sdd-extensions'
    if (-not (Test-Path $ExtDir)) { return }
    foreach ($extSubDir in Get-ChildItem $ExtDir -Directory -ErrorAction SilentlyContinue) {
        $manifest = Join-Path $extSubDir.FullName 'sdd-extension.json'
        if (-not (Test-Path $manifest)) { continue }
        try {
            $data = Get-Content $manifest -Raw | ConvertFrom-Json
            $hookScript = $data.hooks.$HookName
            if ($hookScript) {
                $hookPath = Join-Path $extSubDir.FullName $hookScript
                if (Test-Path $hookPath) {
                    Write-Info "Running extension hook: $HookName from $($extSubDir.Name)"
                    try { & bash $hookPath @HookArgs }
                    catch { Write-Warn "Extension hook failed (non-fatal): $hookPath" }
                }
            }
        } catch { Write-Warn "Could not parse extension manifest: $manifest" }
    }
}

# ── Autonomy provenance checks (Wave 11 Phase J) ─────────────────────

function Get-ExecutionMode {
    param([string]$Dir)
    $mf = Join-Path $Dir '.feature-meta.json'
    if (-not (Test-Path $mf)) { return 'standard' }
    try { return (Get-Content $mf -Raw | ConvertFrom-Json).executionMode } catch { return 'standard' }
}

function Get-MetaField {
    param([string]$Dir, [string]$Field, [string]$Default = '')
    $mf = Join-Path $Dir '.feature-meta.json'
    if (-not (Test-Path $mf)) { return $Default }
    try {
        $val = (Get-Content $mf -Raw | ConvertFrom-Json).$Field
        if ($null -eq $val) { return $Default }
        return $val
    } catch { return $Default }
}

function Test-AutonomyProvenance {
    param([string]$Dir, [int]$Gate)
    $execMode = Get-ExecutionMode $Dir
    if ($execMode -eq 'standard') { return 0 }

    $e = 0
    $todoFile = Join-Path $Dir 'todo.md'

    Write-Host ''
    Write-Info "🤖 Autonomy Provenance Checks (mode: $execMode)"
    Write-Host ''

    if (-not (Test-Path $todoFile)) {
        Write-Err 'AUTONOMY: todo.md MISSING — autonomous cycles must persist evidence in todo.md'
        Write-Check 'Next step: Create todo.md with cycle evidence blocks before running the gate'
        $e++
    } else {
        $todoContent = Get-Content $todoFile -Raw

        $evidenceCount = ([regex]::Matches($todoContent, '## Cycle \d+')).Count
        if ($evidenceCount -lt 1) {
            Write-Err 'AUTONOMY: No cycle evidence blocks found in todo.md'
            Write-Check 'Next step: Each autonomous cycle must write a ''## Cycle N'' evidence section'
            $e++
        } else {
            Write-Ok "Found $evidenceCount cycle evidence block(s) in todo.md"
        }

        if ($todoContent -notmatch '(?i)(rationale|reason)\\*?\\*?:') {
            Write-Err 'AUTONOMY: No rationale found in cycle evidence'
            Write-Check 'Next step: Each cycle must include a rationale'
            $e++
        } else { Write-Ok 'Rationale found in cycle evidence' }

        if ($todoContent -notmatch '(?i)confidence.*score.*[1-5]|confidence.*[1-5]/5') {
            Write-Err 'AUTONOMY: No confidence score found in cycle evidence'
            Write-Check 'Next step: Each cycle must record a confidence score (1-5)'
            $e++
        } else { Write-Ok 'Confidence score recorded' }

        if ($todoContent -notmatch '(?i)risk.*classification.*:\s*\b(low|medium|high|critical)\b') {
            Write-Err 'AUTONOMY: No risk classification found in cycle evidence'
            Write-Check 'Next step: Each cycle must record risk as low/medium/high/critical'
            $e++
        } else { Write-Ok 'Risk classification recorded' }

        if ($todoContent -notmatch '(?i)traceability|US-\d+|TC-\d+|T\d+') {
            Write-Warn 'AUTONOMY: No traceability references found in cycle evidence'
        } else { Write-Ok 'Traceability references found' }

        if ($todoContent -notmatch '(?i)touched.*artifact|files.*modified|files.*created') {
            Write-Err 'AUTONOMY: No touched-artifact list in cycle evidence'
            Write-Check 'Next step: Each cycle must list files created/modified'
            $e++
        } else { Write-Ok 'Touched-artifact list found' }

        if ($evidenceCount -gt 1) {
            $resetCount = ([regex]::Matches($todoContent, '(?i)context.reset|fresh.session|new.cycle')).Count
            $expectedResets = $evidenceCount - 1
            if ($resetCount -lt $expectedResets) {
                Write-Err "AUTONOMY: Missing context-reset markers between cycles ($resetCount found, $expectedResets expected)"
                Write-Check 'Next step: Each cycle must start from a fresh context'
                $e++
            } else { Write-Ok 'Context-reset markers present between cycles' }
        }
    }

    # Budget check
    $budget = [int](Get-MetaField $Dir 'autonomyBudget' '0')
    if ((Test-Path $todoFile) -and $budget -gt 0) {
        $cyclesConsumed = ([regex]::Matches((Get-Content $todoFile -Raw), '## Cycle \d+')).Count
        if ($cyclesConsumed -gt $budget) {
            Write-Err "AUTONOMY: Budget exceeded ($cyclesConsumed cycles consumed, budget: $budget)"
            Write-Check 'Next step: Switch to standard mode or request budget increase'
            $e++
        } else {
            Write-Ok "Budget: $cyclesConsumed/$budget cycles consumed"
        }
    }

    if ($e -gt 0) {
        Write-Host ''
        Write-Err "AUTONOMY PROVENANCE FAILED: $e issue(s) detected"
        Write-Check '💡 Recommended action: Switch executionMode to ''standard'' in .feature-meta.json'
        Write-Check '   and resolve the issues manually before re-enabling autonomous mode.'
        Write-Host ''
    } else {
        Write-Host ''
        Write-Ok 'AUTONOMY PROVENANCE: All checks passed'
        Write-Host ''
    }

    return $e
}

# ── Gate validators ───────────────────────────────────────────────────

function Invoke-Gate1 {
    param([string]$Dir)
    $e = 0
    Write-Host ''
    Write-Host '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
    Write-Host '  🚪 Gate 1: Three Amigos Review'
    Write-Host '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
    Write-Host ''

    # Delta-spec detection: if delta-spec.md exists, use delta validation path
    $deltaPath = Join-Path $Dir 'delta-spec.md'
    if (Test-Path $deltaPath) {
        Write-Host 'Checking: Delta specification completeness'; Write-Host ''
        Write-Info 'Delta spec detected — using reduced-ceremony validation'
        if (-not (Test-FileExists $deltaPath 'delta-spec.md')) { $e++ }
        if (-not (Test-FileNotTemplate $deltaPath 'delta-spec.md')) { $e++ }

        $deltaContent = Get-Content $deltaPath -Raw

        # Validate required fields based on change_type
        if ($deltaContent -match '(?i)MODIFIED|RENAMED') {
            Write-Info 'Change type MODIFIED/RENAMED — checking Before State field:'
            if ($deltaContent -notmatch '## Before State' -or $deltaContent -match '\[Describe the current') {
                Write-Err "'Before State' section is required and must be filled for MODIFIED/RENAMED changes"
                $e++
            } else {
                Write-Ok "'Before State' section is present and filled"
            }
        }
        if ($deltaContent -match '(?i)REMOVED') {
            Write-Info 'Change type REMOVED — checking Justification field:'
            if ($deltaContent -notmatch '## Justification' -or $deltaContent -match '\[Rationale for') {
                Write-Err "'Justification' section is required and must be filled for REMOVED changes"
                $e++
            } else {
                Write-Ok "'Justification' section is present and filled"
            }
        }

        # Impact assessment is always required
        Write-Info 'Impact assessment:'
        if ($deltaContent -notmatch '## Impact Assessment') {
            Write-Err "'Impact Assessment' section is missing"
            $e++
        } else {
            Write-Ok "'Impact Assessment' section is present"
        }
        Write-Host ''
        return $e
    }

    Write-Host 'Checking: Do we all share the same understanding?'; Write-Host ''
    Write-Info 'Required artifacts:'
    if (-not (Test-FileExists (Join-Path $Dir 'business-context.md') 'business-context.md')) { $e++ }
    if (-not (Test-FileNotTemplate (Join-Path $Dir 'business-context.md') 'business-context.md')) { $e++ }
    if (-not (Test-FileExists (Join-Path $Dir 'spec.md') 'spec.md')) { $e++ }
    if (-not (Test-FileNotTemplate (Join-Path $Dir 'spec.md') 'spec.md')) { $e++ }
    if (-not (Test-UserStories (Join-Path $Dir 'spec.md'))) { $e++ }
    if (-not (Test-AcceptanceCriteria (Join-Path $Dir 'spec.md'))) { $e++ }
    if (-not (Test-FileExists (Join-Path $Dir 'clarifications.md') 'clarifications.md')) { $e++ }
    Write-Info 'Clarification markers:'
    if (-not (Test-NeedsClarificationMarkers $Dir)) { $e++ }
    Write-Host ''
    return $e
}

function Invoke-Gate2 {
    param([string]$Dir)
    $e = 0
    Write-Host ''
    Write-Host '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
    Write-Host '  🚪 Gate 2: Technical Alignment Review'
    Write-Host '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
    Write-Host ''; Write-Host 'Checking: Does the design fulfill the spec?'; Write-Host ''
    Write-Info 'Required artifacts:'
    if (-not (Test-FileExists (Join-Path $Dir 'plan.md') 'plan.md')) { $e++ }
    if (-not (Test-FileNotTemplate (Join-Path $Dir 'plan.md') 'plan.md')) { $e++ }
    Write-Info 'Cross-reference checks:'
    if (-not (Test-USInPlan (Join-Path $Dir 'spec.md') (Join-Path $Dir 'plan.md'))) { $e++ }
    # Wave 23 §C.4: Hidden Requirement Candidates section must be present in clarifications.md
    Write-Info 'Hidden requirement scan:'
    $clarFile = Join-Path $Dir 'clarifications.md'
    if (Test-Path $clarFile) {
        $clarContent = Get-Content $clarFile -Raw
        if ($clarContent -match '(?i)## Hidden Requirement Candidates') {
            Write-Ok 'Hidden Requirement Candidates section present in clarifications.md'
        } else {
            Write-Err 'clarifications.md missing "## Hidden Requirement Candidates" section'
            Write-Check 'Run the hidden-requirement-scan skill or add the section manually before Gate 2'
            $e++
        }
    } else {
        Write-Warn 'clarifications.md not found — cannot verify hidden-requirement scan'
    }
    Write-Info 'Clarification markers:'
    if (-not (Test-NeedsClarificationMarkers $Dir)) { $e++ }
    Write-Host ''
    return $e
}

function Invoke-Gate3 {
    param([string]$Dir)
    $e = 0
    Write-Host ''
    Write-Host '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
    Write-Host '  🚪 Gate 3: Implementation Gate'
    Write-Host '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
    Write-Host ''; Write-Host 'Checking: Are spec, design, and tests aligned?'; Write-Host ''
    Write-Info 'Required artifacts:'
    if (-not (Test-FileExists (Join-Path $Dir 'test-cases.md') 'test-cases.md')) { $e++ }
    if (-not (Test-FileNotTemplate (Join-Path $Dir 'test-cases.md') 'test-cases.md')) { $e++ }
    if (-not (Test-TestCoverage (Join-Path $Dir 'test-cases.md') (Join-Path $Dir 'spec.md'))) { $e++ }
    if (-not (Test-FileExists (Join-Path $Dir 'tasks.md') 'tasks.md')) { $e++ }
    if (-not (Test-FileNotTemplate (Join-Path $Dir 'tasks.md') 'tasks.md')) { $e++ }
    if (-not (Test-TasksCoverage (Join-Path $Dir 'tasks.md'))) { $e++ }
    if (-not (Test-FileExists (Join-Path $Dir 'analysis-report.md') 'analysis-report.md')) { $e++ }
    if (-not (Test-AnalysisStatus (Join-Path $Dir 'analysis-report.md'))) { $e++ }
    Write-Info 'Clarification markers:'
    if (-not (Test-NeedsClarificationMarkers $Dir)) { $e++ }
    Write-Host ''
    return $e
}

function Invoke-Gate4 {
    param([string]$Dir)
    $e = 0
    Write-Host ''
    Write-Host '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
    Write-Host '  🚪 Gate 4: Ship Gate'
    Write-Host '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
    Write-Host ''; Write-Host 'Checking: Is this ready for production?'; Write-Host ''
    Write-Info 'Validating previous gates...'
    $e += Invoke-Gate1 $Dir
    $e += Invoke-Gate2 $Dir
    $e += Invoke-Gate3 $Dir
    Write-Info 'Ship checklist:'
    if (-not (Test-FileExists (Join-Path $Dir 'ship-checklist.md') 'ship-checklist.md')) { $e++ }
    if (-not (Test-ShipChecklist (Join-Path $Dir 'ship-checklist.md'))) { $e++ }
    # Wave 8: Goal-backward verification
    Write-Info 'Goal-backward verification:'
    if (-not (Test-GoalBackward $Dir)) { $e++ }
    Write-Host ''
    return $e
}

# ── Main ──────────────────────────────────────────────────────────────

$FeatureDir = Join-Path $SpecsDir $FeatureId
if (-not (Test-Path $FeatureDir)) {
    Write-Err "Feature directory not found: $FeatureDir"
    exit 1
}

# Ceremony level detection
$CeremonyLevel = 'standard'
$metaFile = Join-Path $FeatureDir '.feature-meta.json'
if (Test-Path $metaFile) {
    try { $CeremonyLevel = (Get-Content $metaFile -Raw | ConvertFrom-Json).ceremonyLevel } catch {}
    if (-not $CeremonyLevel) { $CeremonyLevel = 'standard' }
}

# Ultra‑light: skip gates 1‑3
if ($CeremonyLevel -eq 'ultra-light' -and $GateNumber -ne 4) {
    Write-Host ''
    Write-Warn "Ceremony level is 'ultra-light' — Gates 1-3 are skipped."
    Write-Warn "Run Gate 4 for minimal validation: .\validate-gate.ps1 $FeatureId 4"
    Write-Host ''
    exit 0
}

Write-Info "Ceremony level: $CeremonyLevel"

# Lock file management
if (-not (Test-Path $CheckpointsDir)) { New-Item -ItemType Directory -Path $CheckpointsDir -Force | Out-Null }
$lockFile = Join-Path $CheckpointsDir "$FeatureId.lock"
if (Test-Path $lockFile) {
    try {
        $lockData = Get-Content $lockFile -Raw | ConvertFrom-Json
        $lockPid  = $lockData.pid
        try { $proc = Get-Process -Id $lockPid -ErrorAction Stop; $alive = $true } catch { $alive = $false }
        if ($alive) {
            Write-Err "Feature $FeatureId is locked by another process (PID: $lockPid)"
            Write-Err "Use .\resume-feature.ps1 -Unlock $FeatureId to force-remove."
            exit 1
        } else {
            Write-Warn "Removing stale lock (PID $lockPid no longer running)"
            Remove-Item $lockFile -Force
        }
    } catch {
        Remove-Item $lockFile -Force
    }
}
$lockJson = @{ pid = $PID; agent = 'validate-gate'; timestamp = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ') } | ConvertTo-Json
Set-Content -Path $lockFile -Value $lockJson -Encoding UTF8

# Cleanup lock on exit
$cleanup = { param($lf) if (Test-Path $lf) { Remove-Item $lf -Force -ErrorAction SilentlyContinue } }
Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action { if (Test-Path $lockFile) { Remove-Item $lockFile -Force -ErrorAction SilentlyContinue } } | Out-Null

try {
    # Wave 8: Stuck detection — compare artifact checksums to previous run
    Test-StuckDetection $FeatureDir $GateNumber

    Invoke-ExtensionHooks -HookName 'before-gate-validate' -HookArgs @($FeatureId, $GateNumber)

    # Wave 11 Phase J: Run autonomy provenance checks for non-standard modes
    $autonomyResult = Test-AutonomyProvenance $FeatureDir $GateNumber

    # Run validation
    $result = switch ($GateNumber) {
        1 { Invoke-Gate1 $FeatureDir }
        2 { Invoke-Gate2 $FeatureDir }
        3 { Invoke-Gate3 $FeatureDir }
        4 {
            if ($CeremonyLevel -eq 'ultra-light') {
                Write-Host ''
                Write-Host '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
                Write-Host '  🚪 Gate 4: Ship Gate (ultra-light)'
                Write-Host '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
                Write-Host ''
                $e = 0
                if (-not (Test-FileExists (Join-Path $FeatureDir 'spec.md') 'spec.md')) { $e++ }
                if (-not (Test-FileExists (Join-Path $FeatureDir 'tasks.md') 'tasks.md')) { $e++ }
                if (-not (Test-FileExists (Join-Path $FeatureDir 'ship-checklist.md') 'ship-checklist.md')) { $e++ }
                if (-not (Test-NeedsClarificationMarkers $FeatureDir)) { $e++ }
                $e
            } else {
                Invoke-Gate4 $FeatureDir
            }
        }
    }

    # Full ceremony: zero tolerance
    if ($CeremonyLevel -eq 'full' -and $result -gt 0) {
        Write-Warn 'Full ceremony: ALL issues must be resolved (zero tolerance)'
    }

    # Combine gate result with autonomy provenance result
    $result = $result + $autonomyResult

    # Write checkpoint on success
    if ($result -eq 0) {
        $cpFile = Join-Path $CheckpointsDir "$FeatureId.checkpoint"
        $cpJson = @{
            featureId = $FeatureId
            gate      = $GateNumber
            ceremony  = $CeremonyLevel
            timestamp = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')
        } | ConvertTo-Json
        Set-Content -Path $cpFile -Value $cpJson -Encoding UTF8
    }

    # Append to metrics log (Wave 8: structured memory)
    $metricsLog = Join-Path $MemoryDir 'metrics-log.md'
    if (Test-Path $metricsLog) {
        $ts = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
        $resultText = if ($result -eq 0) { 'PASS' } else { 'FAIL' }
        Add-Content -Path $metricsLog -Value "| $ts | $FeatureId | Gate $GateNumber | $CeremonyLevel | $resultText | $result | - | - | - |" -Encoding UTF8
    }

    # Update session state (Wave 8: structured memory)
    $sessionState = Join-Path $MemoryDir 'session-state.md'
    if ((Test-Path $sessionState) -and $result -eq 0) {
        $nextPhase = $GateNumber + 1
        $ssContent = Get-Content $sessionState -Raw
        $ssContent = $ssContent -replace '(?m)^- \*\*Feature ID:\*\* .*', "- **Feature ID:** $FeatureId"
        $ssContent = $ssContent -replace '(?m)^- \*\*Current Phase:\*\* .*', "- **Current Phase:** Phase $nextPhase"
        $ssContent = $ssContent -replace '(?m)^- \*\*Last Gate Passed:\*\* .*', "- **Last Gate Passed:** Gate $GateNumber"
        $ssContent = $ssContent -replace '(?m)^- \*\*Last Gate Timestamp:\*\* .*', "- **Last Gate Timestamp:** $ts"
        $ssContent = $ssContent -replace '(?m)^- \*\*Ceremony Level:\*\* .*', "- **Ceremony Level:** $CeremonyLevel"
        $phaseMap = @{ 1 = 'Phase 1: Requirements'; 2 = 'Phase 2: Design'; 3 = 'Phase 3: Preparation'; 4 = 'Phase 5: Quality Assurance' }
        for ($i = 1; $i -le $GateNumber; $i++) {
            if ($phaseMap.ContainsKey($i)) {
                $ssContent = $ssContent -replace ("(?m)^- \[ \] " + [regex]::Escape($phaseMap[$i])), ("- [x] " + $phaseMap[$i])
            }
        }
        Set-Content -Path $sessionState -Value $ssContent -Encoding UTF8 -NoNewline
    }

    # Auto-regenerate context bridge for next phase (Wave 8: context isolation)
    if ($result -eq 0) {
        $nextPhase = $GateNumber + 1
        if ($nextPhase -le 5) {
            Write-Info "Regenerating context bridge for Phase $nextPhase..."
            try {
                & (Join-Path $ScriptDir 'context-bridge.ps1') $FeatureId $nextPhase
            } catch {
                Write-Warn 'Context bridge generation failed (non-blocking)'
            }
        }
    }

    # Final verdict
    Write-Host '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
    if ($result -eq 0) {
        Write-Ok "GATE ${GateNumber}: PASSED ✅"
        Write-Host ''; Write-Host '  Ready to proceed to the next phase!'
        Invoke-ExtensionHooks -HookName 'after-gate-pass' -HookArgs @($FeatureId, $GateNumber)
    } else {
        Write-Err "GATE ${GateNumber}: FAILED ($result issues)"
        Write-Host ''

        # ── Explain-mode diagnostics (OpenSpec MVP — Evolution §12 item #8) ──
        Write-Host '📋 EXPLAIN:' -ForegroundColor Cyan
        switch ($GateNumber) {
            1 {
                Write-Host '   What failed:  Gate 1 (Three Amigos Review) requires business-context.md, spec.md'
                Write-Host '                 (with user stories and acceptance criteria), and clarifications.md.'
                Write-Host '   Why it matters: Without a shared understanding of requirements, design and'
                Write-Host '                   implementation will diverge from business intent.'
                Write-Host '   What to do next:'
                Write-Host '     1. Ensure business-context.md exists with real content (not template)'
                Write-Host '     2. Ensure spec.md contains US-xxx user stories and AC-xxx acceptance criteria'
                Write-Host '     3. Create clarifications.md to resolve ambiguities'
                Write-Host '     4. Resolve any [NEEDS CLARIFICATION] markers (max 3 per artifact)'
                Write-Host "     5. Re-run: .\validate-gate.ps1 $FeatureId 1"
                Write-Host '   Related commands: sdd spell challenge <feature-id>'
            }
            2 {
                Write-Host '   What failed:  Gate 2 (Technical Alignment) requires plan.md (design) with'
                Write-Host '                 coverage of all user stories from spec.md.'
                Write-Host '   Why it matters: Without design coverage, implementation will drift from'
                Write-Host '                   requirements. Every US-xxx in spec.md must appear in plan.md.'
                Write-Host '   What to do next:'
                Write-Host "     1. Run: sdd spell plan-implementation $FeatureId"
                Write-Host '     2. Ensure every US-xxx in spec.md is referenced in plan.md'
                Write-Host '     3. Validate contracts (openapi.yaml, asyncapi.yaml) if present'
                Write-Host "     4. Re-run: .\validate-gate.ps1 $FeatureId 2"
                Write-Host "   Related commands: sdd skill run sdd-challenge $FeatureId"
            }
            3 {
                Write-Host '   What failed:  Gate 3 (Implementation Gate) requires test-cases.md, tasks.md,'
                Write-Host '                 and analysis-report.md with passing verdict.'
                Write-Host '   Why it matters: Implementation must be traceable. Each user story needs test'
                Write-Host '                   coverage, each test case should reference a test file, and the'
                Write-Host '                   analysis report must show PASS or PASS WITH WARNINGS.'
                Write-Host '   What to do next:'
                Write-Host "     1. Run: sdd spell assert-quality $FeatureId"
                Write-Host '     2. Ensure test-cases.md covers all US-xxx from spec.md'
                Write-Host '     3. Ensure tasks.md has at least one task per design section'
                Write-Host "     4. Run: .\generate-report.ps1 $FeatureId"
                Write-Host "     5. Re-run: .\validate-gate.ps1 $FeatureId 3"
                Write-Host "   Related commands: sdd spell review-code $FeatureId"
            }
            4 {
                Write-Host '   What failed:  Gate 4 (Ship Gate) requires all previous gates to pass plus'
                Write-Host '                 ship-checklist.md with all items checked and goal-backward'
                Write-Host '                 verification without GOAL DRIFT.'
                Write-Host '   Why it matters: Shipping without full gate compliance risks production issues'
                Write-Host '                   and breaks the traceability chain.'
                Write-Host '   What to do next:'
                Write-Host '     1. Fix any failing earlier gates (run validate-gate.ps1 for gates 1-3)'
                Write-Host '     2. Create/complete ship-checklist.md with all items checked'
                Write-Host '     3. Ensure analysis-report.md contains Goal-Backward Verification section'
                Write-Host "     4. Re-run: .\validate-gate.ps1 $FeatureId 4"
                Write-Host "   Related commands: sdd spell review-functional $FeatureId"
            }
        }
        Write-Host ''

        Write-Host '  Please address the issues above before proceeding.'
    }
    Write-Host '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'

    exit $result
} finally {
    # Remove lock
    if (Test-Path $lockFile) { Remove-Item $lockFile -Force -ErrorAction SilentlyContinue }
}
