<#
.SYNOPSIS
    Canonical NAVIA PATH runtime bootstrap and environment verifier.
.DESCRIPTION
    Single source of truth for runtime synchronization and pre-flight validation.
    Compatible with Windows PowerShell ConstrainedLanguage / RemoteSigned mode.
    Works for:
      - machine Bouygues Telecom (synchronization from RPA_SHARE when reachable)
      - external/public machines (bundled NuGet Runtime or local runtime fallback)
      - UiPath Edge / Chrome activities
      - standalone PowerShell execution
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

if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
    $InstallRoot = Join-Path $env:LOCALAPPDATA "NAVIA_PATH"
}

# 1. Standard local folders
New-Item -ItemType Directory -Path $InstallRoot -Force | Out-Null
foreach ($dir in @("Runs", "Logs", "Cache", "EdgeProfile", "ChromeProfile", "Secrets", "config", "config\providers", "Bootstrap")) {
    New-Item -ItemType Directory -Path (Join-Path $InstallRoot $dir) -Force | Out-Null
}

# 2. Context Determination: machine Bouygues Telecom vs external/public machine
$RpaShareDefault = "\\svm-prod1.rsi.prd.mlb.nbyt.fr\RPA_SHARE\Imad\NavIA Pass"
$IsBouyguesTelecom = $false
$ActiveSource = ""

# Check if an explicit source was supplied
if (-not [string]::IsNullOrWhiteSpace($SourcePath) -and (Test-Path -LiteralPath $SourcePath)) {
    $ActiveSource = $SourcePath
    if ($SourcePath -like "*svm-prod1*" -or $SourcePath -like "*RPA_SHARE*") {
        $IsBouyguesTelecom = $true
    }
}

# Detect RPA_SHARE (preferred on machine Bouygues Telecom)
if ([string]::IsNullOrWhiteSpace($ActiveSource)) {
    $ShareEnv = $env:NAVIA_SHARE_PATH
    $CandidateShares = @()
    if (-not [string]::IsNullOrWhiteSpace($ShareEnv)) { $CandidateShares += $ShareEnv }
    $CandidateShares += $RpaShareDefault

    foreach ($cand in $CandidateShares) {
        try {
            if ((Test-Path -LiteralPath $cand) -and (Test-Path -LiteralPath (Join-Path $cand "CURRENT_VERSION.txt"))) {
                $ActiveSource = $cand
                $IsBouyguesTelecom = $true
                break
            }
        }
        catch {
            # Network share inaccessible or DNS unresolvable
        }
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
                $ActiveSource = $cand
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
            if ($line -match '^([^=]+)=(.*)$') {
                $data[$matches[1].Trim()] = $matches[2].Trim()
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
            $curHash = (Get-FileHash -LiteralPath $LocalVersionedExe -Algorithm SHA256).Hash
            if ($curHash -eq $ExpectedHash) {
                $NeedCopy = $false
            }
        }

        if ($NeedCopy -and (Test-Path -LiteralPath $SourceExe)) {
            $tempExe = "$LocalVersionedExe.download"
            Remove-Item -LiteralPath $tempExe -Force -ErrorAction SilentlyContinue
            Copy-Item -LiteralPath $SourceExe -Destination $tempExe -Force

            if (-not [string]::IsNullOrWhiteSpace($ExpectedHash)) {
                $dlHash = (Get-FileHash -LiteralPath $tempExe -Algorithm SHA256).Hash
                if ($dlHash -ne $ExpectedHash) {
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
        & robocopy.exe $SourceConfig $LocalConfig /E /COPY:DAT /R:2 /W:2 /NP | Out-Null
    }

    # 5. Machine Bouygues Telecom context: prepare approved local ADC
    if ($IsBouyguesTelecom) {
        $SourceSecrets = Join-Path $ActiveSource "Secrets\application_default_credentials.json"
        $LocalSecretsDir = Join-Path $InstallRoot "Secrets"
        $LocalSecretsFile = Join-Path $LocalSecretsDir "application_default_credentials.json"

        if (Test-Path -LiteralPath $SourceSecrets) {
            New-Item -ItemType Directory -Path $LocalSecretsDir -Force | Out-Null
            $copyCreds = $true
            if (Test-Path -LiteralPath $LocalSecretsFile) {
                $sItem = Get-Item -LiteralPath $SourceSecrets
                $lItem = Get-Item -LiteralPath $LocalSecretsFile
                if ($sItem.Length -eq $lItem.Length -and $sItem.LastWriteTimeUtc -le $lItem.LastWriteTimeUtc) {
                    $copyCreds = $false
                }
            }
            if ($copyCreds) {
                Copy-Item -LiteralPath $SourceSecrets -Destination $LocalSecretsFile -Force
            }
            $env:GOOGLE_APPLICATION_CREDENTIALS = $LocalSecretsFile

            # Ensure local .env.vertex references the local ADC file
            $localEnvVertex = Join-Path $LocalConfig "providers\.env.vertex"
            if (Test-Path -LiteralPath $localEnvVertex) {
                $envLines = Get-Content -LiteralPath $localEnvVertex
                $newLines = @()
                $foundGAC = $false
                foreach ($el in $envLines) {
                    if ($el -match '^GOOGLE_APPLICATION_CREDENTIALS=') {
                        $newLines += "GOOGLE_APPLICATION_CREDENTIALS=$LocalSecretsFile"
                        $foundGAC = $true
                    } else {
                        $newLines += $el
                    }
                }
                if (-not $foundGAC) {
                    $newLines += "GOOGLE_APPLICATION_CREDENTIALS=$LocalSecretsFile"
                }
                $newLines | Set-Content -LiteralPath $localEnvVertex -Encoding utf8
            }
        }
    }
}

# 6. Verify executable presence
if (-not (Test-Path -LiteralPath $StableExe)) {
    throw "NAVIA_PATH.exe not found in $InstallRoot and no bootstrap source could provide it."
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
    exit $Code
}

exit 0
