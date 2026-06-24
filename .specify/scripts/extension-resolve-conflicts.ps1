#Requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$ExtensionPath,

    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

$ManifestPath = Join-Path $ExtensionPath 'sdd-extension.json'
if (-not (Test-Path $ManifestPath -PathType Leaf)) {
    Write-Error "Missing manifest: $ManifestPath"
    exit 1
}

$manifest = Get-Content $ManifestPath -Raw | ConvertFrom-Json
$conflicts = New-Object System.Collections.Generic.List[string]

$coreAgents = @('architect', 'analysis', 'requirement-analyst', 'software-engineer', 'test-engineer', 'review', 'constitution')
$namespace = [string]$manifest.namespacePrefix

Write-Host 'Layering order: module -> extension -> preset (immutable order)'
Write-Host 'Install plan:'

foreach ($section in @('hooks', 'commands', 'templates')) {
    if ($manifest.$section -is [System.Management.Automation.PSCustomObject]) {
        foreach ($prop in $manifest.$section.PSObject.Properties) {
            $target = Join-Path $ExtensionPath ([string]$prop.Value)
            Write-Host " - $target"
        }
    }
}

foreach ($section in @('instructions', 'prompts')) {
    foreach ($item in @($manifest.$section)) {
        $target = Join-Path $ExtensionPath ([string]$item)
        Write-Host " - $target"
    }
}

if ($manifest.setupTemplate) {
    Write-Host (" - " + (Join-Path $ExtensionPath ([string]$manifest.setupTemplate)))
}

if ($manifest.agentPatches -is [System.Management.Automation.PSCustomObject]) {
    foreach ($prop in $manifest.agentPatches.PSObject.Properties) {
        if ($coreAgents -contains $prop.Name) {
            $conflicts.Add("core immutability violation: agentPatches overrides core agent '$($prop.Name)'")
        }
    }
}

foreach ($instructionRel in @($manifest.instructions)) {
    $name = [System.IO.Path]::GetFileName([string]$instructionRel)
    if ($namespace -eq 'fe') {
        if (-not $name.StartsWith('fe-')) {
            $conflicts.Add("namespace isolation violation: instruction '$instructionRel' must start with 'fe-'")
        }
        if ($name.StartsWith('aws-fe-')) {
            $conflicts.Add("namespace isolation violation: instruction '$instructionRel' crosses namespace boundary")
        }
    }
    if ($namespace -eq 'aws-fe') {
        if (-not $name.StartsWith('aws-fe-')) {
            $conflicts.Add("namespace isolation violation: instruction '$instructionRel' must start with 'aws-fe-'")
        }
        if ($name.StartsWith('fe-')) {
            $conflicts.Add("namespace isolation violation: instruction '$instructionRel' crosses namespace boundary")
        }
    }
}

foreach ($promptRel in @($manifest.prompts)) {
    $p = ([string]$promptRel).Replace('\\', '/')
    if ($namespace -eq 'fe' -and -not $p.Contains('/fe/')) {
        $conflicts.Add("namespace isolation violation: prompt '$promptRel' must be under '/fe/'")
    }
    if ($namespace -eq 'aws-fe' -and -not $p.Contains('/aws-fe/')) {
        $conflicts.Add("namespace isolation violation: prompt '$promptRel' must be under '/aws-fe/'")
    }
    if ($namespace -eq 'fe' -and $p.Contains('/aws-fe/')) {
        $conflicts.Add("namespace isolation violation: prompt '$promptRel' crosses namespace boundary")
    }
    if ($namespace -eq 'aws-fe' -and $p.Contains('/fe/')) {
        $conflicts.Add("namespace isolation violation: prompt '$promptRel' crosses namespace boundary")
    }
}

if ($conflicts.Count -gt 0) {
    Write-Host 'Conflicts:'
    foreach ($item in $conflicts) {
        Write-Host " - $item"
    }
    exit 1
}

if ($DryRun) {
    Write-Host 'Dry-run: no files changed'
} else {
    Write-Host 'No conflicts detected'
}

exit 0
