<#
.SYNOPSIS
    Post-merge integration verification gate (Wave 20 §20.B.8/B.9).

.DESCRIPTION
    Runs the configured build_command and test_command from
    .specify/config.yaml against the post-merge tree, writes POST-MERGE.md, and
    on failure writes INCIDENT.md. Never auto-reverts.
#>

param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$FeatureId
)

$ErrorActionPreference = "Continue"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$RepoRoot = Resolve-Path (Join-Path $ScriptDir "..\..")
$SpecsDir = Join-Path $RepoRoot ".specify\specs"
$ConfigFile = Join-Path $RepoRoot ".specify\config.yaml"

$FeatureDir = Join-Path $SpecsDir $FeatureId
if (-not (Test-Path $FeatureDir)) {
    Write-Error "Feature workspace not found: $FeatureDir"
    exit 2
}

$BuildCmd = ""
$TestCmd = ""
if (Test-Path $ConfigFile) {
    $py = "import yaml,sys;cfg=yaml.safe_load(open(r'$ConfigFile', encoding='utf-8'))or{};print(cfg.get('build_command','') or '')"
    $BuildCmd = (& python -c $py) -join ""
    $py2 = "import yaml,sys;cfg=yaml.safe_load(open(r'$ConfigFile', encoding='utf-8'))or{};print(cfg.get('test_command','') or '')"
    $TestCmd = (& python -c $py2) -join ""
}

if (-not $BuildCmd -and -not $TestCmd) {
    Write-Error "Neither build_command nor test_command is set in $ConfigFile."
    exit 2
}

$PostMergeFile = Join-Path $FeatureDir "POST-MERGE.md"
$IncidentFile = Join-Path $FeatureDir "INCIDENT.md"
$Timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss") + " UTC"

$BuildLog = New-TemporaryFile
$TestLog = New-TemporaryFile
$BuildRc = 0
$TestRc = 0

if ($BuildCmd) {
    & cmd /c $BuildCmd 2>&1 | Out-File -FilePath $BuildLog.FullName -Encoding utf8
    $BuildRc = $LASTEXITCODE
}
if ($TestCmd) {
    & cmd /c $TestCmd 2>&1 | Out-File -FilePath $TestLog.FullName -Encoding utf8
    $TestRc = $LASTEXITCODE
}

$Verdict = if ($BuildRc -ne 0 -or $TestRc -ne 0) { "FAIL" } else { "PASS" }

$buildOut = if (Test-Path $BuildLog.FullName) { Get-Content $BuildLog.FullName -Tail 200 -Raw } else { "" }
$testOut  = if (Test-Path $TestLog.FullName)  { Get-Content $TestLog.FullName -Tail 200 -Raw } else { "" }

@"
# Post-Merge Verification — $FeatureId

> **Generated:** $Timestamp
> **Verdict:** $Verdict

## Configuration
- ``build_command``: ``$BuildCmd``
- ``test_command``:  ``$TestCmd``

## Build Output (exit $BuildRc)

``````
$buildOut
``````

## Test Output (exit $TestRc)

``````
$testOut
``````
"@ | Out-File -FilePath $PostMergeFile -Encoding utf8

if ($Verdict -eq "FAIL") {
    @"
# Incident — Post-Merge Verification Failed for $FeatureId

> **Generated:** $Timestamp
> **Status:** OPEN
> **Owner:** <assign>

## Failing Commands

$(if ($BuildRc -ne 0) { "- ``build_command`` (``$BuildCmd``) exited with $BuildRc" })
$(if ($TestRc -ne 0)  { "- ``test_command`` (``$TestCmd``) exited with $TestRc"  })

## Captured Output

``````
$buildOut

$testOut
``````

## Resolution

> Investigate the failing command(s) above. This artifact does NOT auto-revert the merge.
> Use ``sdd ship --rollback`` (when available) or your VCS tooling to revert if required.
"@ | Out-File -FilePath $IncidentFile -Encoding utf8
}

Remove-Item -Force $BuildLog.FullName, $TestLog.FullName -ErrorAction SilentlyContinue

if ($Verdict -eq "PASS") {
    Write-Host "Post-merge verification PASSED for $FeatureId"
    exit 0
}
Write-Host "Post-merge verification FAILED for $FeatureId"
exit 1
