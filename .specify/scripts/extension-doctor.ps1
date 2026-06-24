#Requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$ExtensionPath
)

$ErrorActionPreference = 'Stop'

$ManifestPath = Join-Path $ExtensionPath 'sdd-extension.json'
if (-not (Test-Path $ManifestPath -PathType Leaf)) {
    Write-Error "Missing manifest: $ManifestPath"
    exit 1
}

$manifest = Get-Content $ManifestPath -Raw | ConvertFrom-Json
$issues = New-Object System.Collections.Generic.List[string]
$warnings = New-Object System.Collections.Generic.List[string]

$promptNames = @()
foreach ($rel in @($manifest.prompts)) {
    $promptNames += [System.IO.Path]::GetFileName([string]$rel)
}

$duplicates = $promptNames | Group-Object | Where-Object { $_.Count -gt 1 } | ForEach-Object { $_.Name }
if ($duplicates) {
    $issues.Add("duplicate prompt filenames in manifest: $($duplicates -join ', ')")
}

$applyMap = @{}
foreach ($rel in @($manifest.instructions)) {
    $path = Join-Path $ExtensionPath ([string]$rel)
    if (-not (Test-Path $path)) { continue }
    $content = Get-Content $path -Raw
    $match = [regex]::Match($content, '(?m)^applyTo:\s*"?([^"\n]+)"?')
    if (-not $match.Success) {
        $warnings.Add("instruction has no applyTo: $rel")
        continue
    }
    $glob = $match.Groups[1].Value.Trim()
    if (-not $applyMap.ContainsKey($glob)) {
        $applyMap[$glob] = New-Object System.Collections.Generic.List[string]
    }
    $applyMap[$glob].Add([string]$rel)
}

foreach ($glob in $applyMap.Keys) {
    if ($applyMap[$glob].Count -gt 1) {
        $issues.Add("applyTo overlap '$glob' across: $($applyMap[$glob] -join ', ')")
    }
}

Write-Host 'Doctor report:'
Write-Host " - manifest: $ManifestPath"
Write-Host " - extension: $($manifest.name)"

foreach ($warning in $warnings) {
    Write-Host "WARNING: $warning"
}

if ($issues.Count -gt 0) {
    Write-Host 'Issues:'
    foreach ($issue in $issues) {
        Write-Host " - $issue"
    }
    exit 1
}

Write-Host 'No doctor issues detected'
& (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'extension-resolve-conflicts.ps1') $ExtensionPath -DryRun
exit $LASTEXITCODE
