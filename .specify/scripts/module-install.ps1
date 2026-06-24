#Requires -Version 5.1
<#
.SYNOPSIS
    Install an SDD user module.
.DESCRIPTION
    Reads a module from .sdd-modules/modules/<name>/, copies its files
    into the project, and registers it in registry.json.
.PARAMETER ModuleName
    Name of the module directory under .sdd-modules/modules/.
.EXAMPLE
    .\module-install.ps1 core-be
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory, Position = 0)]
    [string]$ModuleName
)

$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot  = (Resolve-Path (Join-Path $ScriptDir '..\..\')).Path

function Write-Info  { param([string]$Msg) Write-Host "ℹ️  $Msg" -ForegroundColor Blue }
function Write-Ok    { param([string]$Msg) Write-Host "✅ $Msg" -ForegroundColor Green }
function Write-Err   { param([string]$Msg) Write-Host "❌ $Msg" -ForegroundColor Red }
function Write-Warn  { param([string]$Msg) Write-Host "⚠️  $Msg" -ForegroundColor Yellow }

Write-Host ''
Write-Host '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
Write-Host "  📦 Installing SDD Module: $ModuleName"
Write-Host '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
Write-Host ''

$ModuleDir = Join-Path $RepoRoot ".sdd-modules\modules\$ModuleName"
$Registry  = Join-Path $RepoRoot '.sdd-modules\registry.json'

function Copy-ModuleTree {
    param(
        [string]$SourceDir,
        [string]$TargetRoot,
        [string]$RegistryPrefix
    )

    if (-not (Test-Path $SourceDir)) {
        return
    }

    Get-ChildItem $SourceDir -File -Recurse | ForEach-Object {
        $relativePath = $_.FullName.Substring($SourceDir.Length + 1).Replace('\', '/')
        $targetFile = Join-Path $TargetRoot $relativePath
        $targetParent = Split-Path -Parent $targetFile
        if (-not (Test-Path $targetParent)) {
            New-Item -ItemType Directory -Path $targetParent -Force | Out-Null
        }
        Copy-Item $_.FullName -Destination $targetFile -Force
        $InstalledFiles.Add("$RegistryPrefix/$relativePath")
    }
}

function Copy-ManifestImports {
    param(
        [string]$Category,
        [string]$TargetRoot,
        [string]$RegistryPrefix,
        [object]$Manifest
    )

    $imports = @($Manifest.importFrom.$Category)
    if (-not $imports -or $imports.Count -eq 0) {
        return
    }

    foreach ($entry in $imports) {
        $sourcePath = Join-Path $RepoRoot $entry.from
        $destinationRoot = $TargetRoot
        $targetSubdir = if ($entry.to) { [string]$entry.to } else { '' }
        $targetName = if ($entry.as) { [string]$entry.as } else { '' }
        if ($targetSubdir) {
            $destinationRoot = Join-Path $destinationRoot $targetSubdir
        }

        if (Test-Path $sourcePath -PathType Container) {
            Get-ChildItem $sourcePath -File -Recurse | ForEach-Object {
                $relativePath = $_.FullName.Substring($sourcePath.Length + 1).Replace('\', '/')
                $targetFile = Join-Path $destinationRoot $relativePath
                $targetParent = Split-Path -Parent $targetFile
                if (-not (Test-Path $targetParent)) {
                    New-Item -ItemType Directory -Path $targetParent -Force | Out-Null
                }
                Copy-Item $_.FullName -Destination $targetFile -Force
                $registryPath = $RegistryPrefix
                if ($targetSubdir) {
                    $registryPath = "$registryPath/$($targetSubdir.Replace('\', '/'))"
                }
                $InstalledFiles.Add("$registryPath/$relativePath")
            }
            continue
        }

        if (-not (Test-Path $sourcePath -PathType Leaf)) {
            Write-Warn "Manifest source path not found: $($entry.from)"
            continue
        }

        if (-not $targetName) {
            $targetName = Split-Path -Leaf $sourcePath
        }
        if (-not (Test-Path $destinationRoot)) {
            New-Item -ItemType Directory -Path $destinationRoot -Force | Out-Null
        }
        Copy-Item $sourcePath -Destination (Join-Path $destinationRoot $targetName) -Force
        $registryPath = $RegistryPrefix
        if ($targetSubdir) {
            $registryPath = "$registryPath/$($targetSubdir.Replace('\', '/'))"
        }
        $InstalledFiles.Add("$registryPath/$targetName")
    }
}

# Verify module exists
if (-not (Test-Path $ModuleDir)) {
    Write-Err "Module '$ModuleName' not found in .sdd-modules/modules/"
    exit 1
}

# Read module.json
$ManifestPath = Join-Path $ModuleDir 'module.json'
if (-not (Test-Path $ManifestPath)) {
    Write-Err "Module '$ModuleName' has no module.json manifest"
    exit 1
}
$Manifest = Get-Content $ManifestPath -Raw | ConvertFrom-Json

# Check if already installed
if (Test-Path $Registry) {
    $RegistryData = Get-Content $Registry -Raw | ConvertFrom-Json
    $existing = $RegistryData.installedModules | Where-Object { $_.name -eq $ModuleName }
    if ($existing) {
        Write-Err "Module '$ModuleName' is already installed. Run 'sdd module remove $ModuleName' first."
        exit 1
    }
} else {
    $RegistryData = [PSCustomObject]@{
        version          = '1.0.0'
        installedModules = @()
    }
}

$ModuleVersion = if ($Manifest.version) { $Manifest.version } else { '0.0.0' }
Write-Info "Module version: $ModuleVersion"

# Track installed files for registry
$InstalledFiles = [System.Collections.Generic.List[string]]::new()

# Copy instruction files
$InstructionsDir = Join-Path $ModuleDir 'instructions'
$TargetDir = Join-Path $RepoRoot '.github\instructions'
if (-not (Test-Path $TargetDir)) { New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null }
Copy-ModuleTree -SourceDir $InstructionsDir -TargetRoot $TargetDir -RegistryPrefix '.github/instructions'
Copy-ManifestImports -Category 'instructions' -TargetRoot $TargetDir -RegistryPrefix '.github/instructions' -Manifest $Manifest
if ((Test-Path $InstructionsDir) -or (@($Manifest.importFrom.instructions).Count -gt 0)) {
    Write-Ok 'Copied instruction files'
}

# Copy guidance files
$GuidancesDir = Join-Path $ModuleDir 'guidances'
$TargetDir = Join-Path $RepoRoot '.github\guidances'
if (-not (Test-Path $TargetDir)) { New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null }
Copy-ModuleTree -SourceDir $GuidancesDir -TargetRoot $TargetDir -RegistryPrefix '.github/guidances'
Copy-ManifestImports -Category 'guidances' -TargetRoot $TargetDir -RegistryPrefix '.github/guidances' -Manifest $Manifest
if ((Test-Path $GuidancesDir) -or (@($Manifest.importFrom.guidances).Count -gt 0)) {
    Write-Ok 'Copied guidance files'
}

# Copy prompts
$PromptsDir = Join-Path $ModuleDir 'prompts'
$TargetDir = Join-Path $RepoRoot '.github\prompts'
if (-not (Test-Path $TargetDir)) { New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null }
Copy-ModuleTree -SourceDir $PromptsDir -TargetRoot $TargetDir -RegistryPrefix '.github/prompts'
Copy-ManifestImports -Category 'prompts' -TargetRoot $TargetDir -RegistryPrefix '.github/prompts' -Manifest $Manifest
if ((Test-Path $PromptsDir) -or (@($Manifest.importFrom.prompts).Count -gt 0)) {
    Write-Ok 'Copied prompt files'
}

# Copy setup templates
$SetupDir = Join-Path $ModuleDir 'setup'
$TargetDir = Join-Path $RepoRoot '.specify\templates\setup'
if (-not (Test-Path $TargetDir)) { New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null }
Copy-ModuleTree -SourceDir $SetupDir -TargetRoot $TargetDir -RegistryPrefix '.specify/templates/setup'
Copy-ManifestImports -Category 'setup' -TargetRoot $TargetDir -RegistryPrefix '.specify/templates/setup' -Manifest $Manifest
if ((Test-Path $SetupDir) -or (@($Manifest.importFrom.setup).Count -gt 0)) {
    Write-Ok 'Copied setup templates'
}

# Append copilot-instructions supplement (if exists)
$SupplementPath = Join-Path $ModuleDir 'copilot-instructions-supplement.md'
if (Test-Path $SupplementPath) {
    $CopilotInstructions = Join-Path $RepoRoot '.github\copilot-instructions.md'
    if (-not (Test-Path $CopilotInstructions)) {
        New-Item -ItemType File -Path $CopilotInstructions -Force | Out-Null
    }
    $Supplement = Get-Content $SupplementPath -Raw
    $Block = "`n<!-- BEGIN MODULE: $ModuleName -->`n$Supplement`n<!-- END MODULE: $ModuleName -->"
    Add-Content -Path $CopilotInstructions -Value $Block -Encoding UTF8
    Write-Ok 'Appended copilot-instructions supplement'
}

# Notify about agent patches (manual merge required)
$AgentPatchesDir = Join-Path $ModuleDir 'agent-patches'
if ((Test-Path $AgentPatchesDir) -and (Get-ChildItem $AgentPatchesDir -File | Select-Object -First 1)) {
    Write-Host ''
    Write-Warn "Agent patches available in $AgentPatchesDir"
    Write-Warn 'Review and manually merge into agent files as needed:'
    Get-ChildItem $AgentPatchesDir -File | ForEach-Object { Write-Host "  $($_.Name)" }
}

# Present constitution articles (manual merge required)
$ConstitutionDir = Join-Path $ModuleDir 'constitution-articles'
if ((Test-Path $ConstitutionDir) -and (Get-ChildItem $ConstitutionDir -File | Select-Object -First 1)) {
    Write-Host ''
    Write-Warn 'Constitution articles available:'
    Get-ChildItem $ConstitutionDir -File | ForEach-Object { Write-Host "  $($_.Name)" }
    Write-Warn 'Merge relevant articles into .specify/memory/constitution.md'
}

# Notify about placeholders
if ($Manifest.placeholders -and ($Manifest.placeholders.PSObject.Properties | Measure-Object).Count -gt 0) {
    Write-Host ''
    Write-Warn 'Module defines placeholders that need configuration:'
    foreach ($prop in $Manifest.placeholders.PSObject.Properties) {
        Write-Host "  - $($prop.Name): $($prop.Value)"
    }
}

# Update registry
Write-Info 'Updating registry...'

# Wave 20 §20.C.5 — compute per-file sha256 and aggregate manifestSha256.
$FileHashes = [ordered]@{}
$AggInput = New-Object System.Text.StringBuilder
foreach ($rel in $InstalledFiles) {
    $abs = Join-Path $RepoRoot $rel
    if (Test-Path $abs -PathType Leaf) {
        $h = (Get-FileHash -Path $abs -Algorithm SHA256).Hash.ToLower()
        $FileHashes[$rel] = $h
        [void]$AggInput.Append("$rel`:$h`n")
    }
}
$aggBytes = [System.Text.Encoding]::UTF8.GetBytes($AggInput.ToString())
$sha256 = [System.Security.Cryptography.SHA256]::Create()
$ManifestSha256 = -join ($sha256.ComputeHash($aggBytes) | ForEach-Object { $_.ToString('x2') })

$NewEntry = [PSCustomObject]@{
    name           = $ModuleName
    version        = $ModuleVersion
    installedAt    = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
    files          = @($InstalledFiles)
    fileHashes     = $FileHashes
    manifestSha256 = $ManifestSha256
}

# Replace prior entry for this module (Wave 20 §20.C.7 supports --reset).
$RegistryData.installedModules = @(
    @($RegistryData.installedModules) | Where-Object { $_.name -ne $ModuleName }
) + @($NewEntry)
$RegistryData | ConvertTo-Json -Depth 10 | Set-Content -Path $Registry -Encoding UTF8
Write-Ok "Registry updated (manifest sha256: $($ManifestSha256.Substring(0,12))…)"

Write-Host ''
Write-Host '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
Write-Ok "Module '$ModuleName' v$ModuleVersion installed successfully ($($InstalledFiles.Count) files)"
Write-Host '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
Write-Host ''
