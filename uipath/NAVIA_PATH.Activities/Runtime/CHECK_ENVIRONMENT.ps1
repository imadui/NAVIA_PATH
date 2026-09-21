<#
.SYNOPSIS
    Authoritative NAVIA PATH environment installer, synchronizer, and health validator.
.DESCRIPTION
    Consolidated public entry point for NAVIA PATH.
    1. Prepares/installs the local runtime under %LOCALAPPDATA%\NAVIA_PATH.
    2. Synchronizes the versioned binary and verifies its real SHA256 against CURRENT_VERSION.txt.
    3. Configures the selected LLM provider and securely installs credentials into Secrets.
    4. Executes the canonical NAVIA_PATH.exe --check.
    5. On success, writes %LOCALAPPDATA%\NAVIA_PATH\NAVIA_READY.json readiness marker.
    Compatible with Windows PowerShell ConstrainedLanguageMode.
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

function Write-Info([string]$Message) {
    if (-not $Json) {
        Write-Host "[*] $Message" -ForegroundColor Cyan
    }
}

function Write-Success([string]$Message) {
    if (-not $Json) {
        Write-Host "[OK] $Message" -ForegroundColor Green
    }
}

function Write-Fail([string]$Message) {
    if (-not $Json) {
        Write-Host "[ERROR] $Message" -ForegroundColor Red
    }
}

# 1. Determine local runtime installation root
if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
    $InstallRoot = Join-Path $env:LOCALAPPDATA "NAVIA_PATH"
}

New-Item -ItemType Directory -Path $InstallRoot -Force | Out-Null
foreach ($dir in @("Runs", "Logs", "Cache", "EdgeProfile", "ChromeProfile", "Secrets", "config", "config\providers", "Bootstrap")) {
    New-Item -ItemType Directory -Path (Join-Path $InstallRoot $dir) -Force | Out-Null
}

# Test write access to runtime
$WriteTestFile = Join-Path (Join-Path $InstallRoot "Runs") ".write_test_${PID}_$(Get-Random).tmp"
try {
    Set-Content -LiteralPath $WriteTestFile -Value "ok" -Encoding ascii
    Remove-Item -LiteralPath $WriteTestFile -Force -ErrorAction SilentlyContinue
}
catch {
    Write-Fail "Runtime directory is not writable: $InstallRoot"
    exit 1
}

# 2. Determine distribution source directory ($SourcePath)
$ActiveSource = ""
if (-not [string]::IsNullOrWhiteSpace($SourcePath) -and (Test-Path -LiteralPath $SourcePath)) {
    $ActiveSource = (Resolve-Path -LiteralPath $SourcePath).Path
}

if ([string]::IsNullOrWhiteSpace($ActiveSource)) {
    # Check current script directory
    if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot) -and (Test-Path -LiteralPath (Join-Path $PSScriptRoot "CURRENT_VERSION.txt"))) {
        $ActiveSource = $PSScriptRoot
    }
}

if ([string]::IsNullOrWhiteSpace($ActiveSource)) {
    # Check NAVIA_SHARE_PATH environment variable if explicitly configured
    $ShareEnv = $env:NAVIA_SHARE_PATH
    if (-not [string]::IsNullOrWhiteSpace($ShareEnv) -and (Test-Path -LiteralPath $ShareEnv)) {
        if (Test-Path -LiteralPath (Join-Path $ShareEnv "CURRENT_VERSION.txt")) {
            $ActiveSource = $ShareEnv
        }
    }
}

if ([string]::IsNullOrWhiteSpace($ActiveSource)) {
    # Check bundled Runtime candidates
    $CandidateDirs = @(
        (Join-Path $PSScriptRoot "Runtime"),
        (Join-Path $PSScriptRoot "..\Runtime"),
        (Join-Path $PSScriptRoot "..\..\Runtime"),
        (Join-Path (Get-Location) "Runtime"),
        (Join-Path (Get-Location) "uipath\NAVIA_PATH.Activities\Runtime"),
        (Join-Path (Get-Location) "NAVIA_PATH.Activities\Runtime"),
        (Get-Location).Path
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

if ([string]::IsNullOrWhiteSpace($ActiveSource)) {
    # If no source found, check if local runtime already has CURRENT_VERSION.txt
    $localManifest = Join-Path $InstallRoot "CURRENT_VERSION.txt"
    if (Test-Path -LiteralPath $localManifest) {
        $ActiveSource = $InstallRoot
    } else {
        Write-Fail "Source distribution directory could not be located (CURRENT_VERSION.txt missing)."
        exit 1
    }
}

function Read-ManifestMap([string]$FilePath) {
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

# 3. Read manifest and verify source binary integrity
$SourceManifest = Join-Path $ActiveSource "CURRENT_VERSION.txt"
$Meta = Read-ManifestMap $SourceManifest
$Version = $Meta["VERSION"]
$ExeName = $Meta["EXE"]
$ExpectedHash = $Meta["SHA256"]

if ([string]::IsNullOrWhiteSpace($ExeName)) {
    Write-Fail "Invalid manifest in ${SourceManifest}: EXE property missing."
    exit 1
}

$SourceExe = Join-Path $ActiveSource $ExeName
if (-not (Test-Path -LiteralPath $SourceExe)) {
    # Check if generic NAVIA_PATH.exe exists in source
    $altSourceExe = Join-Path $ActiveSource "NAVIA_PATH.exe"
    if (Test-Path -LiteralPath $altSourceExe) {
        $SourceExe = $altSourceExe
    } else {
        Write-Fail "Source executable not found: $SourceExe"
        exit 1
    }
}

Write-Info "Verifying binary integrity of source $ExeName..."
$ActualSourceHash = (Get-FileHash -LiteralPath $SourceExe -Algorithm SHA256).Hash.ToUpper()
if (-not [string]::IsNullOrWhiteSpace($ExpectedHash)) {
    if ($ActualSourceHash -ne $ExpectedHash.ToUpper()) {
        Write-Fail "SHA256 integrity check failed for source binary!`n  Expected: $ExpectedHash`n  Actual:   $ActualSourceHash"
        exit 1
    }
    Write-Success "Binary integrity verified ($ActualSourceHash)."
}

# 4. Synchronize binary to local runtime
$LocalVersionedExe = Join-Path $InstallRoot $ExeName
$StableExe = Join-Path $InstallRoot "NAVIA_PATH.exe"
$LocalVersionFile = Join-Path $InstallRoot "CURRENT_VERSION.txt"

$NeedCopyExe = $true
if (Test-Path -LiteralPath $LocalVersionedExe) {
    $curLocalHash = (Get-FileHash -LiteralPath $LocalVersionedExe -Algorithm SHA256).Hash.ToUpper()
    if ($curLocalHash -eq $ActualSourceHash) {
        $NeedCopyExe = $false
    }
}

if ($NeedCopyExe) {
    Write-Info "Installing $ExeName to $InstallRoot..."
    $tempExe = "$LocalVersionedExe.download"
    Remove-Item -LiteralPath $tempExe -Force -ErrorAction SilentlyContinue
    Copy-Item -LiteralPath $SourceExe -Destination $tempExe -Force

    $dlHash = (Get-FileHash -LiteralPath $tempExe -Algorithm SHA256).Hash.ToUpper()
    if ($dlHash -ne $ActualSourceHash) {
        Remove-Item -LiteralPath $tempExe -Force -ErrorAction SilentlyContinue
        Write-Fail "Downloaded file corrupted during local copy."
        exit 1
    }
    Move-Item -LiteralPath $tempExe -Destination $LocalVersionedExe -Force
}

# Update stable NAVIA_PATH.exe copy
Copy-Item -LiteralPath $LocalVersionedExe -Destination $StableExe -Force
Unblock-File -LiteralPath $LocalVersionedExe -ErrorAction SilentlyContinue
Unblock-File -LiteralPath $StableExe -ErrorAction SilentlyContinue

# Prune obsolete versioned EXEs
Get-ChildItem -LiteralPath $InstallRoot -Filter "NAVIA_PATH_v*.exe" -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -ne $ExeName } |
    ForEach-Object { Remove-Item -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue }

Copy-Item -LiteralPath $SourceManifest -Destination $LocalVersionFile -Force

# 5. Synchronize Configuration & Providers
$SourceConfig = Join-Path $ActiveSource "config"
$LocalConfig = Join-Path $InstallRoot "config"
if (Test-Path -LiteralPath $SourceConfig) {
    if (-not (Test-Path -LiteralPath $LocalConfig)) {
        New-Item -ItemType Directory -Path $LocalConfig -Force | Out-Null
    }
    # Copy configuration files without overwriting existing customized local .env files if source doesn't provide them
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

# Also copy Bootstrap scripts locally
$LocalBootstrapDir = Join-Path $InstallRoot "Bootstrap"
New-Item -ItemType Directory -Path $LocalBootstrapDir -Force | Out-Null
$ThisScript = $MyInvocation.MyCommand.Path
if (-not [string]::IsNullOrWhiteSpace($ThisScript) -and (Test-Path -LiteralPath $ThisScript)) {
    Copy-Item -LiteralPath $ThisScript -Destination (Join-Path $LocalBootstrapDir "CHECK_ENVIRONMENT.ps1") -Force
}
$SourceBootstrap = Join-Path $ActiveSource "NAVIA_BOOTSTRAP.ps1"
if (Test-Path -LiteralPath $SourceBootstrap) {
    Copy-Item -LiteralPath $SourceBootstrap -Destination (Join-Path $LocalBootstrapDir "NAVIA_BOOTSTRAP.ps1") -Force
}

# 6. Detect Active Provider
$ActiveProvider = ""
if (-not [string]::IsNullOrWhiteSpace($Provider)) {
    $ActiveProvider = $Provider.Trim().ToLower()
}
elseif (-not [string]::IsNullOrWhiteSpace($env:NAVIA_PROVIDER)) {
    $ActiveProvider = $env:NAVIA_PROVIDER.Trim().ToLower()
}
else {
    # Check configured .env files in local config or source
    foreach ($p in @("vertex", "openai", "gemini", "anthropic", "azure_openai")) {
        $candidateEnv = Join-Path $LocalConfig "providers\.env.$p"
        if (Test-Path -LiteralPath $candidateEnv) {
            $ActiveProvider = $p
            break
        }
    }
    if ([string]::IsNullOrWhiteSpace($ActiveProvider)) {
        $ActiveProvider = "vertex"
    }
}

# 7. Provider Credentials Resolution & Installation (Vertex portable experience)
if ($ActiveProvider -eq "vertex") {
    $LocalProvidersDir = Join-Path $LocalConfig "providers"
    $LocalEnvVertex = Join-Path $LocalProvidersDir ".env.vertex"
    $SourceEnvVertex = Join-Path $ActiveSource "config\providers\.env.vertex"

    # Precedence:
    # 1. explicit GOOGLE_APPLICATION_CREDENTIALS from selected .env.vertex
    # 2. existing process/user GOOGLE_APPLICATION_CREDENTIALS
    # 3. standard Google ADC location: %APPDATA%\gcloud\application_default_credentials.json
    # 4. extracted credentials\vertex_credentials.json

    $ResolvedCredPath = ""
    $CredSourceType = ""

    # Check 1: explicit in .env.vertex
    $explicitGacInEnv = ""
    $targetEnv = if (Test-Path -LiteralPath $LocalEnvVertex) { $LocalEnvVertex } elseif (Test-Path -LiteralPath $SourceEnvVertex) { $SourceEnvVertex } else { "" }
    if ($targetEnv) {
        Get-Content -LiteralPath $targetEnv | ForEach-Object {
            $line = $_.Trim()
            if ($line -match '^GOOGLE_APPLICATION_CREDENTIALS=(.*)$') {
                $explicitGacInEnv = $matches[1].Trim().Trim('"').Trim("'")
            }
        }
    }

    if (-not [string]::IsNullOrWhiteSpace($explicitGacInEnv)) {
        if ($explicitGacInEnv -match '^[A-Za-z]:\\|^\\\\') {
            if (Test-Path -LiteralPath $explicitGacInEnv) {
                $ResolvedCredPath = $explicitGacInEnv
                $CredSourceType = "explicit .env path"
            }
        } else {
            # Relative to extracted distribution root ($ActiveSource)
            $candRel = Join-Path $ActiveSource $explicitGacInEnv
            if (Test-Path -LiteralPath $candRel) {
                $ResolvedCredPath = (Resolve-Path -LiteralPath $candRel).Path
                $CredSourceType = "relative .env path"
            }
        }
    }

    # Check 2: existing process/user GOOGLE_APPLICATION_CREDENTIALS
    if ([string]::IsNullOrWhiteSpace($ResolvedCredPath)) {
        if (-not [string]::IsNullOrWhiteSpace($env:GOOGLE_APPLICATION_CREDENTIALS) -and (Test-Path -LiteralPath $env:GOOGLE_APPLICATION_CREDENTIALS)) {
            $ResolvedCredPath = (Resolve-Path -LiteralPath $env:GOOGLE_APPLICATION_CREDENTIALS).Path
            $CredSourceType = "environment variable"
        }
    }

    # Check 3: standard Google ADC location
    if ([string]::IsNullOrWhiteSpace($ResolvedCredPath)) {
        $gcloudAdc = Join-Path $env:APPDATA "gcloud\application_default_credentials.json"
        if (Test-Path -LiteralPath $gcloudAdc) {
            $ResolvedCredPath = $gcloudAdc
            $CredSourceType = "gcloud standard ADC"
        }
    }

    # Check 4: extracted credentials\vertex_credentials.json
    if ([string]::IsNullOrWhiteSpace($ResolvedCredPath)) {
        $sourceCredJson = Join-Path $ActiveSource "credentials\vertex_credentials.json"
        if (Test-Path -LiteralPath $sourceCredJson) {
            $ResolvedCredPath = (Resolve-Path -LiteralPath $sourceCredJson).Path
            $CredSourceType = "extracted credentials\vertex_credentials.json"
        }
    }

    # If credential was located, validate JSON syntax and install into local runtime Secrets
    if (-not [string]::IsNullOrWhiteSpace($ResolvedCredPath)) {
        # Validate JSON syntax
        try {
            $rawJson = Get-Content -LiteralPath $ResolvedCredPath -Raw
            $parsedJson = $rawJson | ConvertFrom-Json
            if ($null -eq $parsedJson) {
                throw "Parsed JSON is null"
            }
        }
        catch {
            Write-Fail "Credential file is not valid JSON ($ResolvedCredPath): $_"
            exit 1
        }

        # Install into %LOCALAPPDATA%\NAVIA_PATH\Secrets\application_default_credentials.json
        $LocalSecretsDir = Join-Path $InstallRoot "Secrets"
        New-Item -ItemType Directory -Path $LocalSecretsDir -Force | Out-Null
        $LocalSecretsFile = Join-Path $LocalSecretsDir "application_default_credentials.json"

        Copy-Item -LiteralPath $ResolvedCredPath -Destination $LocalSecretsFile -Force
        $env:GOOGLE_APPLICATION_CREDENTIALS = $LocalSecretsFile
        Write-Info "Credentials installed locally to Secrets ($CredSourceType)."

        # Ensure local .env.vertex references the installed Secrets file
        if (Test-Path -LiteralPath $LocalEnvVertex) {
            $envLines = Get-Content -LiteralPath $LocalEnvVertex
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
            $newLines | Set-Content -LiteralPath $LocalEnvVertex -Encoding utf8
        }
    }
}

# 8. Canonical NAVIA_PATH.exe --check execution
$env:NAVIA_PATH_HOME = $InstallRoot
$env:NAVIA_PATH_EXE = $StableExe
$env:NAVIA_DISTRIBUTION_ROOT = $ActiveSource

$CheckArgs = @("--check")
if (-not [string]::IsNullOrWhiteSpace($Browser)) {
    $CheckArgs += @("--browser", $Browser)
}
if (-not [string]::IsNullOrWhiteSpace($ActiveProvider)) {
    $CheckArgs += @("--provider", $ActiveProvider)
}
if ($Json) {
    $CheckArgs += "--json"
}

Write-Info "Running canonical environment check via NAVIA_PATH.exe..."
& $StableExe @CheckArgs
$CheckExitCode = $LASTEXITCODE

if ($CheckExitCode -ne 0) {
    # Invalidate readiness marker on failure
    Remove-Item -LiteralPath (Join-Path $InstallRoot "NAVIA_READY.json") -Force -ErrorAction SilentlyContinue
    Write-Fail "NAVIA_PATH environment check reported failure (exit code $CheckExitCode)."
    exit $CheckExitCode
}

# 9. Mark Local Runtime as READY (NAVIA_READY.json)
Write-Info "Environment check passed. Marking runtime as READY..."
$ReadyArgs = @("--mark-ready", "--provider", $ActiveProvider)
if ($Json) { $ReadyArgs += "--json" }

& $StableExe @ReadyArgs
$MarkExitCode = $LASTEXITCODE

if ($MarkExitCode -ne 0) {
    Write-Fail "Could not create readiness marker NAVIA_READY.json."
    exit $MarkExitCode
}

$ReadyMarkerFile = Join-Path $InstallRoot "NAVIA_READY.json"
if (-not (Test-Path -LiteralPath $ReadyMarkerFile)) {
    Write-Fail "NAVIA_READY.json not created in $InstallRoot."
    exit 1
}

Write-Success "NAVIA PATH v$Version is READY and operational."
Write-Success "Local Runtime Root: $InstallRoot"
Write-Success "Executable: $StableExe"
exit 0
