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

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Sandbox = Join-Path $ScriptDir '.sandbox-ps'
$InstallRoot = Join-Path $Sandbox 'install-root'
$HookLog = Join-Path $Sandbox 'hook-order.log'
$Tracker = Join-Path $Sandbox 'installed-files.txt'

if (Test-Path $Sandbox) { Remove-Item $Sandbox -Recurse -Force }
New-Item -ItemType Directory -Path $InstallRoot | Out-Null

$manifest = Get-Content $ManifestPath -Raw | ConvertFrom-Json
$installed = New-Object System.Collections.Generic.List[string]

function Copy-Rel([string]$RelPath) {
    $src = Join-Path $ExtensionPath $RelPath
    if (-not (Test-Path $src)) { return }
    $dst = Join-Path $InstallRoot $RelPath
    $dstDir = Split-Path -Parent $dst
    if (-not (Test-Path $dstDir)) {
        New-Item -ItemType Directory -Path $dstDir -Force | Out-Null
    }
    Copy-Item $src $dst -Force
    $installed.Add($dst)
}

foreach ($section in @('instructions', 'prompts')) {
    foreach ($item in @($manifest.$section)) {
        Copy-Rel ([string]$item)
    }
}

foreach ($section in @('hooks', 'commands', 'templates')) {
    if ($manifest.$section -is [System.Management.Automation.PSCustomObject]) {
        foreach ($prop in $manifest.$section.PSObject.Properties) {
            Copy-Rel ([string]$prop.Value)
        }
    }
}

if ($manifest.setupTemplate) {
    Copy-Rel ([string]$manifest.setupTemplate)
}

$hooks = @()
if ($manifest.hooks -is [System.Management.Automation.PSCustomObject]) {
    $hooks = $manifest.hooks.PSObject.Properties | Sort-Object Name
}

foreach ($hook in $hooks) {
    Add-Content -Path $HookLog -Value ("{0}:0" -f $hook.Name)
}

$installed | Set-Content -Path $Tracker

$afterInstall = Get-ChildItem $InstallRoot -File -Recurse
if ($afterInstall.Count -eq 0) {
    Write-Error 'Snapshot test failed: install produced no files'
    exit 1
}

foreach ($file in Get-Content $Tracker) {
    if (Test-Path $file) {
        Remove-Item $file -Force
    }
}

$afterUninstall = Get-ChildItem $InstallRoot -File -Recurse
if ($afterUninstall.Count -gt 0) {
    Write-Error 'Snapshot test failed: orphan files remain after uninstall'
    $afterUninstall | ForEach-Object { Write-Host $_.FullName }
    exit 1
}

if (-not (Test-Path $HookLog)) {
    Write-Error 'Snapshot test failed: hook order log not generated'
    exit 1
}

Write-Host 'SNAPSHOT TEST PASSED'
Write-Host " - extension: $ExtensionPath"
Write-Host " - hook-log: $HookLog"
exit 0
