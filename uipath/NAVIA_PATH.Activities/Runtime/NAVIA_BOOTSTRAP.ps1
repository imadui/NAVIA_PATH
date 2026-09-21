<#
.SYNOPSIS
    Canonical NAVIA PATH runtime bootstrap and environment verifier.
.DESCRIPTION
    Single source of truth for runtime synchronization and pre-flight validation.
    Compatible with Windows PowerShell ConstrainedLanguage / RemoteSigned mode.
    Delegates to CHECK_ENVIRONMENT.ps1 when available, or provides self-contained fallback.
#>
[CmdletBinding()]
param(
    [string]$Browser = "",
    [string]$Provider = "",
    [string]$InstallRoot = "",
    [string]$SourcePath = "",
    [switch]$Json
)

$ErrorActionPreference = "Stop"

# If CHECK_ENVIRONMENT.ps1 is available, delegate to it as the canonical preparation script
$CheckEnvScript = Join-Path $PSScriptRoot "CHECK_ENVIRONMENT.ps1"
if (Test-Path -LiteralPath $CheckEnvScript) {
    & $CheckEnvScript @PSBoundParameters
    exit $LASTEXITCODE
}

# Fallback: check if CHECK_ENVIRONMENT.ps1 exists in current directory or source directory
if (-not [string]::IsNullOrWhiteSpace($SourcePath) -and (Test-Path -LiteralPath (Join-Path $SourcePath "CHECK_ENVIRONMENT.ps1"))) {
    & (Join-Path $SourcePath "CHECK_ENVIRONMENT.ps1") @PSBoundParameters
    exit $LASTEXITCODE
}

if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
    $InstallRoot = Join-Path $env:LOCALAPPDATA "NAVIA_PATH"
}

# 1. Standard local folders
New-Item -ItemType Directory -Path $InstallRoot -Force | Out-Null
foreach ($dir in @("Runs", "Logs", "Cache", "EdgeProfile", "ChromeProfile", "Secrets", "config", "config\providers", "Bootstrap")) {
    New-Item -ItemType Directory -Path (Join-Path $InstallRoot $dir) -Force | Out-Null
}

# 2. Context Determination: Generic explicit source or environment
$ActiveSource = ""

# Check if an explicit source was supplied
if (-not [string]::IsNullOrWhiteSpace($SourcePath) -and (Test-Path -LiteralPath $SourcePath)) {
    $ActiveSource = (Resolve-Path -LiteralPath $SourcePath).Path
}

# Generic network share via NAVIA_SHARE_PATH
if ([string]::IsNullOrWhiteSpace($ActiveSource)) {
    $ShareEnv = $env:NAVIA_SHARE_PATH
    if (-not [string]::IsNullOrWhiteSpace($ShareEnv) -and (Test-Path -LiteralPath $ShareEnv)) {
        try {
            if (Test-Path -LiteralPath (Join-Path $ShareEnv "CURRENT_VERSION.txt")) {
                $ActiveSource = (Resolve-Path -LiteralPath $ShareEnv).Path
            }
        }
        catch {}
    }
}

# External / Public fallback: search bundled Runtime candidates
if ([string]::IsNullOrWhiteSpace($ActiveSource)) {
    $CandidateDirs = @(
        $PSScriptRoot,
        (Join-Path $PSScriptRoot "Runtime"),
        (Join-Path $PSScriptRoot "..\Runtime"),
        (Join-Path $PSScriptRoot "..\..\Runtime"),
        (Join-Path (Get-Location) "Runtime"),
        (Join-Path (Get-Location) "uipath\NAVIA_PATH.Activities\Runtime"),
        (Join-Path (Get-Location) "NAVIA_PATH.Activities\Runtime")
    )

    $PackagesRoot = $env:NUGET_PACKAGES
    if ([string]::IsNullOrWhiteSpace($PackagesRoot)) {
        $PackagesRoot = Join-Path $env:USERPROFILE ".nuget\packages"
    }
    $NugetPath = Join-Path $PackagesRoot "navia_path.activities"
    if (Test-Path -LiteralPath $NugetPath) {
        try {
            $CandidateDirs += (Get-ChildItem -LiteralPath $NugetPath -Filter "Runtime" -Directory -Recurse -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName)
        }
        catch {}
    }
    $NugetNavia = Join-Path $PackagesRoot "navia"
    if (Test-Path -LiteralPath $NugetNavia) {
        try {
            $CandidateDirs += (Get-ChildItem -LiteralPath $NugetNavia -Filter "Runtime" -Directory -Recurse -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName)
        }
        catch {}
    }

    foreach ($cand in $CandidateDirs) {
        if (-not [string]::IsNullOrWhiteSpace($cand) -and (Test-Path -LiteralPath $cand)) {
            $manifest = Join-Path $cand "CURRENT_VERSION.txt"
            if (Test-Path -LiteralPath $manifest) {
                $ActiveSource = (Resolve-Path -LiteralPath $cand).Path
                break
            }
        }
    }
}

function Read-ManifestData([string]$FilePath) {
    $data = @{}
    if (Test-Path -LiteralPath $FilePath) {
        Get-Content -LiteralPath $FilePath | ForEach-Object {
            $line = $_.Trim()
            if ($line -and -not $line.StartsWith("#") -and $line -match '^([^=]+)=(.*)$') {
                $data[$matches[1].Trim().ToUpper()] = $matches[2].Trim()
            }
        }
    }
    return $data
}

# 3. Synchronize Runtime binary
$LocalVersionFile = Join-Path $InstallRoot "CURRENT_VERSION.txt"
$StableExe = Join-Path $InstallRoot "NAVIA_PATH.exe"
$LocalVersionedExe = ""

if (-not [string]::IsNullOrWhiteSpace($ActiveSource)) {
    $SourceManifest = Join-Path $ActiveSource "CURRENT_VERSION.txt"
    $Meta = Read-ManifestData $SourceManifest
    $Version = $Meta["VERSION"]
    $ExeName = $Meta["EXE"]
    $ExpectedHash = $Meta["SHA256"]

    if (-not [string]::IsNullOrWhiteSpace($ExeName)) {
        $SourceExe = Join-Path $ActiveSource $ExeName
        $LocalVersionedExe = Join-Path $InstallRoot $ExeName

        $NeedCopy = $true
        if ((Test-Path -LiteralPath $LocalVersionedExe) -and -not [string]::IsNullOrWhiteSpace($ExpectedHash)) {
            $curHash = (Get-FileHash -LiteralPath $LocalVersionedExe -Algorithm SHA256).Hash.ToUpper()
            if ($curHash -eq $ExpectedHash.ToUpper()) {
                $NeedCopy = $false
            }
        }

        if ($NeedCopy -and (Test-Path -LiteralPath $SourceExe)) {
            $tempExe = "$LocalVersionedExe.download"
            Remove-Item -LiteralPath $tempExe -Force -ErrorAction SilentlyContinue
            Copy-Item -LiteralPath $SourceExe -Destination $tempExe -Force

            if (-not [string]::IsNullOrWhiteSpace($ExpectedHash)) {
                $dlHash = (Get-FileHash -LiteralPath $tempExe -Algorithm SHA256).Hash.ToUpper()
                if ($dlHash -ne $ExpectedHash.ToUpper()) {
                    Remove-Item -LiteralPath $tempExe -Force -ErrorAction SilentlyContinue
                    throw "SHA256 mismatch for downloaded binary from $SourceExe"
                }
            }

            Move-Item -LiteralPath $tempExe -Destination $LocalVersionedExe -Force
        }

        # Update stable NAVIA_PATH.exe
        if (Test-Path -LiteralPath $LocalVersionedExe) {
            Copy-Item -LiteralPath $LocalVersionedExe -Destination $StableExe -Force
            Unblock-File -LiteralPath $LocalVersionedExe -ErrorAction SilentlyContinue
            Unblock-File -LiteralPath $StableExe -ErrorAction SilentlyContinue

            # Prune obsolete versioned EXEs
            Get-ChildItem -LiteralPath $InstallRoot -Filter "NAVIA_PATH_v*.exe" -File -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -ne $ExeName } |
                ForEach-Object { Remove-Item -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue }
        }

        Copy-Item -LiteralPath $SourceManifest -Destination $LocalVersionFile -Force
    }

    # 4. Synchronize Configuration
    $SourceConfig = Join-Path $ActiveSource "config"
    $LocalConfig = Join-Path $InstallRoot "config"
    if (Test-Path -LiteralPath $SourceConfig) {
        if (-not (Test-Path -LiteralPath $LocalConfig)) {
            New-Item -ItemType Directory -Path $LocalConfig -Force | Out-Null
        }
        Get-ChildItem -LiteralPath $SourceConfig -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
            $relPath = $_.FullName.Substring($SourceConfig.Length).TrimStart('\', '/')
            $destFile = Join-Path $LocalConfig $relPath
            $destDir = Split-Path -Parent $destFile
            if (-not (Test-Path -LiteralPath $destDir)) {
                New-Item -ItemType Directory -Path $destDir -Force | Out-Null
            }
            Copy-Item -LiteralPath $_.FullName -Destination $destFile -Force
        }
    }

    # 5. Local credentials preparation if Secrets folder exists in source
    $SourceSecrets = Join-Path $ActiveSource "Secrets\application_default_credentials.json"
    $LocalSecretsDir = Join-Path $InstallRoot "Secrets"
    $LocalSecretsFile = Join-Path $LocalSecretsDir "application_default_credentials.json"

    if (Test-Path -LiteralPath $SourceSecrets) {
        New-Item -ItemType Directory -Path $LocalSecretsDir -Force | Out-Null
        Copy-Item -LiteralPath $SourceSecrets -Destination $LocalSecretsFile -Force
        $env:GOOGLE_APPLICATION_CREDENTIALS = $LocalSecretsFile
    }
}

# 6. Verify executable presence
if (-not (Test-Path -LiteralPath $StableExe)) {
    throw "NAVIA_PATH.exe not found in $InstallRoot and no bootstrap source could provide it. Run CHECK_ENVIRONMENT.ps1."
}

# 7. Execute ONLY the local binary for canonical environment check
$env:NAVIA_PATH_HOME = $InstallRoot
$env:NAVIA_PATH_EXE = $StableExe

$CheckArgs = @("--check")
if (-not [string]::IsNullOrWhiteSpace($Browser)) {
    $CheckArgs += @("--browser", $Browser)
}
if (-not [string]::IsNullOrWhiteSpace($Provider)) {
    $CheckArgs += @("--provider", $Provider)
}
if ($Json) {
    $CheckArgs += "--json"
}

& $StableExe @CheckArgs
$Code = $LASTEXITCODE

if ($Code -ne 0) {
    Remove-Item -LiteralPath (Join-Path $InstallRoot "NAVIA_READY.json") -Force -ErrorAction SilentlyContinue
    exit $Code
}

# 8. Mark Ready
$ReadyArgs = @("--mark-ready")
if (-not [string]::IsNullOrWhiteSpace($Provider)) {
    $ReadyArgs += @("--provider", $Provider)
}
if ($Json) {
    $ReadyArgs += "--json"
}
& $StableExe @ReadyArgs

exit 0
