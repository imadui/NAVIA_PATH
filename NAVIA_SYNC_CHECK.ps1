[CmdletBinding()]
param(
    [string]$Browser = "",
    [string]$Provider = "",
    [string]$InstallRoot = "",
    [string]$SourcePath = "",
    [switch]$Json
)
$ErrorActionPreference = "Stop"
$CheckEnv = Join-Path $PSScriptRoot "CHECK_ENVIRONMENT.ps1"
if (Test-Path -LiteralPath $CheckEnv) {
    & $CheckEnv @PSBoundParameters
    exit $LASTEXITCODE
}
$Bootstrap = Join-Path $PSScriptRoot "NAVIA_BOOTSTRAP.ps1"
if (Test-Path -LiteralPath $Bootstrap) {
    & $Bootstrap @PSBoundParameters
    exit $LASTEXITCODE
} else {
    throw "Neither CHECK_ENVIRONMENT.ps1 nor NAVIA_BOOTSTRAP.ps1 found in $PSScriptRoot"
}
