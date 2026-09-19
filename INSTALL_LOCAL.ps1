[CmdletBinding()]
param(
    [string]$SourcePath = $PSScriptRoot,
    [string]$InstallRoot = ""
)
$ErrorActionPreference = "Stop"
if (-not $InstallRoot) { $InstallRoot = Join-Path $env:LOCALAPPDATA "NAVIA_PATH" }
$VersionFile = Join-Path $SourcePath "CURRENT_VERSION.txt"
if (-not (Test-Path -LiteralPath $VersionFile)) { Write-Error "CURRENT_VERSION.txt not found"; exit 1 }
$Meta = Get-Content -LiteralPath $VersionFile -Raw | ConvertFrom-StringData
$ExeName = $Meta["EXE"]
if (-not $ExeName) { Write-Error "Invalid CURRENT_VERSION.txt"; exit 1 }
New-Item -ItemType Directory -Path $InstallRoot -Force | Out-Null
& robocopy.exe $SourcePath $InstallRoot /E /COPY:DAT /R:2 /W:2 /XD Secrets .git .venv Runs Logs Cache EdgeProfile ChromeProfile
if ($LASTEXITCODE -ge 8) { Write-Error "Robocopy failed: $LASTEXITCODE"; exit 1 }
$LocalExe = Join-Path $InstallRoot $ExeName
if (-not (Test-Path -LiteralPath $LocalExe)) { Write-Error "Local EXE missing: $LocalExe"; exit 1 }
foreach ($DirName in "Runs","Logs","Cache","EdgeProfile","ChromeProfile") { New-Item -ItemType Directory -Path (Join-Path $InstallRoot $DirName) -Force | Out-Null }
Unblock-File -LiteralPath $LocalExe -ErrorAction SilentlyContinue
$env:NAVIA_PATH_HOME = $InstallRoot
$env:NAVIA_PATH_EXE = $LocalExe
& $LocalExe --version
& $LocalExe --check
