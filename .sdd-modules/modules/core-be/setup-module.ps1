<# 
.SYNOPSIS
    Replace placeholders in core-be module files.
.DESCRIPTION
    Replaces {project-name}, {gitlab-project-id}, and {tenant-domain} 
    in all module-contributed files after installation.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$RepoRoot = (Resolve-Path "$PSScriptRoot\..\..").Path

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "  Core-BE — Placeholder Setup"     -ForegroundColor White
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

# ── Collect inputs ──────────────────────────────────────────────
$ProjectName = Read-Host "Project name (e.g., order-api)"
if ([string]::IsNullOrWhiteSpace($ProjectName)) {
    Write-Host "[ERR]  Project name is required" -ForegroundColor Red
    exit 1
}

$GitLabProjectId = Read-Host "GitLab Project ID (numeric, or leave empty)"
$TenantDomain    = Read-Host "Tenant domain prefix (e.g., cph, or leave empty)"

# ── Replacement targets ────────────────────────────────────────
$SearchDirs = @(
    "$RepoRoot\.github\instructions",
    "$RepoRoot\.github\guidances",
    "$RepoRoot\.github\prompts",
    "$RepoRoot\.specify\templates\setup"
)

$Replaced = 0

foreach ($Dir in $SearchDirs) {
    if (-not (Test-Path $Dir)) { continue }

    $Files = Get-ChildItem -Path $Dir -Recurse -Filter "*.md" -File

    foreach ($File in $Files) {
        $Content = Get-Content -Path $File.FullName -Raw -ErrorAction SilentlyContinue
        if (-not $Content) { continue }

        $Changed = $false
        $NewContent = $Content

        if ($NewContent -match '\{project-name\}') {
            $NewContent = $NewContent -replace '\{project-name\}', $ProjectName
            $Changed = $true
        }

        if (-not [string]::IsNullOrWhiteSpace($GitLabProjectId) -and $NewContent -match '\{gitlab-project-id\}') {
            $NewContent = $NewContent -replace '\{gitlab-project-id\}', $GitLabProjectId
            $Changed = $true
        }

        if (-not [string]::IsNullOrWhiteSpace($TenantDomain) -and $NewContent -match '\{tenant-domain\}') {
            $NewContent = $NewContent -replace '\{tenant-domain\}', $TenantDomain
            $Changed = $true
        }

        if ($Changed) {
            Set-Content -Path $File.FullName -Value $NewContent -NoNewline -Encoding UTF8
            $RelPath = $File.FullName.Substring($RepoRoot.Length + 1)
            Write-Host "[OK]   Updated: $RelPath" -ForegroundColor Green
            $Replaced++
        }
    }
}

# Also replace in copilot-instructions.md supplement block
$CopilotFile = "$RepoRoot\.github\copilot-instructions.md"
if (Test-Path $CopilotFile) {
    $Content = Get-Content -Path $CopilotFile -Raw
    $Changed = $false
    $NewContent = $Content

    if ($NewContent -match '\{project-name\}') {
        $NewContent = $NewContent -replace '\{project-name\}', $ProjectName
        $Changed = $true
    }

    if (-not [string]::IsNullOrWhiteSpace($GitLabProjectId) -and $NewContent -match '\{gitlab-project-id\}') {
        $NewContent = $NewContent -replace '\{gitlab-project-id\}', $GitLabProjectId
        $Changed = $true
    }

    if ($Changed) {
        Set-Content -Path $CopilotFile -Value $NewContent -NoNewline -Encoding UTF8
        Write-Host "[OK]   Updated: .github\copilot-instructions.md" -ForegroundColor Green
        $Replaced++
    }
}

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "[OK]   Placeholder replacement complete — $Replaced files updated" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
