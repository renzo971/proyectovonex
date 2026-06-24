#Requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$ExtensionPath,

    [Parameter(Mandatory = $false)]
    [ValidateSet('generic', 'tailored')]
    [string]$Format = 'generic'
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $ExtensionPath -PathType Container)) {
    Write-Error "Extension path not found: $ExtensionPath"
    exit 2
}

$ManifestPath = Join-Path $ExtensionPath 'sdd-extension.json'
if (-not (Test-Path $ManifestPath -PathType Leaf)) {
    Write-Error "Missing manifest: $ManifestPath"
    exit 1
}

$manifest = Get-Content $ManifestPath -Raw | ConvertFrom-Json
$errors = New-Object System.Collections.Generic.List[string]

if (-not $manifest.name) { $errors.Add('missing required field: name') }
if (-not $manifest.version) { $errors.Add('missing required field: version') }
if ($manifest.name -and -not ($manifest.name -like 'sdd-extension-*')) {
    $errors.Add("name must start with 'sdd-extension-'")
}

if ($Format -eq 'tailored') {
    if ($manifest.type -ne 'tailored-frontend') {
        $errors.Add("tailored format requires type='tailored-frontend'")
    }
    if (@('stratos', 'search', 'review') -notcontains $manifest.domainCategory) {
        $errors.Add('tailored format requires domainCategory in {stratos, search, review}')
    }
    if (@('fe', 'aws-fe') -notcontains $manifest.namespacePrefix) {
        $errors.Add('tailored format requires namespacePrefix in {fe, aws-fe}')
    }
}

foreach ($section in @('hooks', 'commands', 'templates')) {
    if ($manifest.$section -is [System.Management.Automation.PSCustomObject]) {
        foreach ($prop in $manifest.$section.PSObject.Properties) {
            $target = Join-Path $ExtensionPath ([string]$prop.Value)
            if (-not (Test-Path $target)) {
                $errors.Add("$section path not found: $($prop.Value)")
            }
        }
    }
}

foreach ($section in @('instructions', 'prompts')) {
    $items = @($manifest.$section)
    foreach ($item in $items) {
        $target = Join-Path $ExtensionPath ([string]$item)
        if (-not (Test-Path $target)) {
            $errors.Add("$section file not found: $item")
        }
    }
}

if ($manifest.setupTemplate) {
    $setupPath = Join-Path $ExtensionPath ([string]$manifest.setupTemplate)
    if (-not (Test-Path $setupPath)) {
        $errors.Add("setupTemplate not found: $($manifest.setupTemplate)")
    }
}

if ($errors.Count -gt 0) {
    Write-Host 'VALIDATION FAILED'
    foreach ($err in $errors) {
        Write-Host " - $err"
    }
    exit 1
}

Write-Host 'VALIDATION PASSED'
Write-Host " - manifest: $ManifestPath"
Write-Host " - format: $Format"
exit 0
