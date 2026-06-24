#Requires -Version 5.1
param(
    [Parameter(Position = 0)]
    [string]$Command = 'help',

    [Parameter(ValueFromRemainingArguments)]
    [string[]]$Arguments
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = (Resolve-Path (Join-Path $ScriptDir '..\..')).Path
$CliRoot = Join-Path $RepoRoot '.specify\cli'

function Show-Help {
    Write-Host @'

Enterprise SDD Workflow

Usage: .\sdd.ps1 <command> [arguments]

Commands:
    init
    new <name> [--template <name>] [-l <ultra-light|standard|full>]
    gate <feature-id> <N>
    status [feature-id]
    analyze <feature-id>
    report <feature-id>
    resume <feature-id>
    bridge <feature-id> <phase>
    module <install|remove|list|update> [name]
    spell <prompt-name> [--guide <name>]
    adapters generate [--target <vscode|cursor|claude|windsurf|codex|all>] [--feature-id <id>]
    preset apply <name>
    sync <push|pull> <feature-id>
    route <feature-id>
    ship <feature-id> [--base <branch>]
    extension <validate|doctor> <path>
    memory <status|sync|doctor> <feature-id>
    skill <list|validate|run|validate-mapping> [name] [feature-id]
    help                       Show this help

Legacy aliases:
    validate <feature-id> <N>  -> gate
'@
}

if ($Command -in @('help', '--help', '-h')) {
    Show-Help
    exit 0
}

if ($Command -eq 'validate') {
    $Command = 'gate'
}

$pythonCmd = Get-Command python -ErrorAction SilentlyContinue
if (-not $pythonCmd) {
    $pythonCmd = Get-Command py -ErrorAction SilentlyContinue
}
if (-not $pythonCmd) {
    Write-Error 'Python is required to run sdd CLI'
    exit 2
}

if ($env:PYTHONPATH) {
    $env:PYTHONPATH = "$CliRoot;$env:PYTHONPATH"
} else {
    $env:PYTHONPATH = $CliRoot
}

& $pythonCmd.Path -m sdd $Command @Arguments
$exitCode = $LASTEXITCODE
if ($null -eq $exitCode) { $exitCode = 0 }
exit $exitCode
