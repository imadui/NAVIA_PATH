[CmdletBinding()]
param(
    [string]$Browser = "",
    [string]$Provider = "",
    [string]$InstallRoot = "",
    [string]$SourcePath = "",
    [switch]$Json
)
$ErrorActionPreference = "Stop"
$Bootstrap = Join-Path $PSScriptRoot "NAVIA_BOOTSTRAP.ps1"
if (Test-Path -LiteralPath $Bootstrap) {
    & $Bootstrap @PSBoundParameters
    exit $LASTEXITCODE
} else {
    throw "NAVIA_BOOTSTRAP.ps1 not found in $PSScriptRoot"
}
