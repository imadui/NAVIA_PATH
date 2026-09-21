[CmdletBinding()]
param(
    [string]$Browser = "",
    [string]$Provider = "",
    [string]$InstallRoot = ""
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
    throw "CHECK_ENVIRONMENT.ps1 not found in $PSScriptRoot"
}
