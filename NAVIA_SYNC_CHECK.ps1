[CmdletBinding()]
param(
    [string]$SourcePath = $PSScriptRoot,
    [string]$InstallRoot = "",
    [string]$Provider = ""
)

$ErrorActionPreference = "Stop"

if (-not $InstallRoot) {
    $InstallRoot = Join-Path $env:LOCALAPPDATA "NAVIA_PATH"
}

$SourceVersionFile = Join-Path $SourcePath "CURRENT_VERSION.txt"
if (-not (Test-Path -LiteralPath $SourceVersionFile)) {
    Write-Error "CURRENT_VERSION.txt not found in release source: $SourcePath"
    exit 1
}

$SourceMeta = Get-Content -LiteralPath $SourceVersionFile -Raw | ConvertFrom-StringData
$Version = $SourceMeta["VERSION"]
$ExeName = $SourceMeta["EXE"]
$ExpectedHash = $SourceMeta["SHA256"]

if (-not $Version -or -not $ExeName) {
    Write-Error "Invalid CURRENT_VERSION.txt in source."
    exit 1
}

$SourceExe = Join-Path $SourcePath $ExeName
if (-not (Test-Path -LiteralPath $SourceExe)) {
    Write-Error "Release executable missing: $SourceExe"
    exit 1
}

if (-not $ExpectedHash) {
    $ExpectedHash = (Get-FileHash -LiteralPath $SourceExe -Algorithm SHA256).Hash
}

New-Item -ItemType Directory -Path $InstallRoot -Force | Out-Null
$LocalVersionFile = Join-Path $InstallRoot "CURRENT_VERSION.txt"
$LocalExe = Join-Path $InstallRoot $ExeName
$NeedSync = $true

if ((Test-Path -LiteralPath $LocalVersionFile) -and (Test-Path -LiteralPath $LocalExe)) {
    $LocalMeta = Get-Content -LiteralPath $LocalVersionFile -Raw | ConvertFrom-StringData
    $LocalHash = (Get-FileHash -LiteralPath $LocalExe -Algorithm SHA256).Hash
    if (($LocalMeta["VERSION"] -eq $Version) -and ($LocalMeta["EXE"] -eq $ExeName) -and ($LocalHash -eq $ExpectedHash)) {
        $NeedSync = $false
    }
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " NAVIA_PATH - SYNC + CHECK" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Release source : $SourcePath"
Write-Host "Target version : $Version"
Write-Host "Target EXE     : $ExeName"
Write-Host "Local root     : $InstallRoot"

if ($NeedSync) {
    Write-Host ""
    Write-Host "[SYNC] Local runtime missing, outdated or hash mismatch." -ForegroundColor Yellow
    & robocopy.exe $SourcePath $InstallRoot /E /COPY:DAT /R:2 /W:2 /XD Secrets .git .venv Runs Logs Cache EdgeProfile ChromeProfile
    if ($LASTEXITCODE -ge 8) {
        Write-Error "Local synchronization failed with robocopy code $LASTEXITCODE"
        exit 1
    }

    $LocalExe = Join-Path $InstallRoot $ExeName
    if (-not (Test-Path -LiteralPath $LocalExe)) {
        Write-Error "Local executable missing after synchronization: $LocalExe"
        exit 1
    }

    $LocalHash = (Get-FileHash -LiteralPath $LocalExe -Algorithm SHA256).Hash
    if ($LocalHash -ne $ExpectedHash) {
        Write-Error "Local executable SHA256 mismatch after synchronization."
        exit 1
    }

    Get-ChildItem -LiteralPath $InstallRoot -Filter "NAVIA_PATH_v*.exe" -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -ne $ExeName } |
        Remove-Item -Force -ErrorAction SilentlyContinue

    Write-Host "[OK] Local runtime synchronized to v$Version." -ForegroundColor Green
}
else {
    Write-Host ""
    Write-Host "[OK] Local runtime already matches v$Version." -ForegroundColor Green
}

# Provider config is mutable independently of the binary version.
$SourceConfig = Join-Path $SourcePath "config"
$LocalConfig = Join-Path $InstallRoot "config"
if (Test-Path -LiteralPath $SourceConfig) {
    & robocopy.exe $SourceConfig $LocalConfig /E /COPY:DAT /R:2 /W:2
    if ($LASTEXITCODE -ge 8) {
        Write-Error "Provider/config synchronization failed with robocopy code $LASTEXITCODE"
        exit 1
    }
}

foreach ($DirName in "Runs","Logs","Cache","EdgeProfile","ChromeProfile") {
    New-Item -ItemType Directory -Path (Join-Path $InstallRoot $DirName) -Force | Out-Null
}

Unblock-File -LiteralPath $LocalExe -ErrorAction SilentlyContinue
$env:NAVIA_PATH_HOME = $InstallRoot
$env:NAVIA_PATH_EXE = $LocalExe

Write-Host ""
Write-Host "[CHECK] Executing LOCAL binary only:" -ForegroundColor Cyan
Write-Host $LocalExe
Write-Host ""

if ($Provider) {
    & $LocalExe check --provider $Provider
}
else {
    & $LocalExe --check
}

if ($LASTEXITCODE -ne 0) {
    Write-Error "NAVIA_PATH local check failed with exit code $LASTEXITCODE"
    exit 1
}

Write-Host ""
Write-Host "[OK] NAVIA_PATH v$Version is installed locally and ready." -ForegroundColor Green
