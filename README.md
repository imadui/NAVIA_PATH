# NAVIA

[![Python Version](https://img.shields.io/badge/python-3.12%2B-blue.svg)](https://www.python.org/)
[![Playwright](https://img.shields.io/badge/playwright-1.40%2B-green.svg)](https://playwright.dev/)
[![LLM Multi-Provider](https://img.shields.io/badge/LLM-Vertex%20%7C%20OpenAI%20%7C%20Anthropic%20%7C%20Gemini-orange.svg)]()
[![UiPath Ready](https://img.shields.io/badge/UiPath-Library%20Activities-blueviolet.svg)]()
[![Runtime](https://img.shields.io/badge/NAVIA_PATH-1.1.12-brightgreen.svg)]()
[![License](https://img.shields.io/badge/license-MIT-lightgrey.svg)](LICENSE)

**Python-based AI browser agent that turns a single prompt into multi-step web automation.**

NAVIA receives a natural-language objective, observes the browser, decides the next action with an LLM, executes that action, observes the new state, and repeats until the objective is complete.

Example:

~~~text
Open https://example.com, inspect the page and return its title.
~~~

A business-oriented example can be as simple as:

~~~text
Open the customer portal, search for order 12345,
open its details and return the current status.
~~~

> The badges describe the technology used to build NAVIA. Public Windows users run the compiled executable and do **not** need to install Python, pip, Playwright, a virtual environment, or PyInstaller.

---

## Current release

| Component | Version |
|---|---:|
| NAVIA PATH Runtime | 1.1.12 |
| UiPath Library | 4.1.1 |
| Platform | Windows x64 |
| Public executable | NAVIA_PATH_v1.1.12.exe |

Current executable SHA256:

~~~text
8CDA87CBDB5CB8EF89E46D698EE481271141DADD0B7ABC311B5E98A01D8B55A9
~~~

The UiPath Library version and NAVIA runtime version are intentionally independent.

---

## What NAVIA does

NAVIA combines LLM reasoning with deterministic browser control. It can:

- navigate across pages and tabs;
- click, type, select, hover and submit;
- inspect dynamic browser state;
- work with modern web applications and authenticated sessions;
- extract structured information;
- return a machine-readable JSON result;
- execute from PowerShell/CMD or as the entry point of a UiPath Library.

NAVIA supports Microsoft Edge and Google Chrome.

Supported LLM provider families include:

- Google Vertex AI;
- Google Gemini Direct API;
- OpenAI;
- Anthropic;
- Azure OpenAI.

---

## How it works

~~~text
Natural-language prompt
        |
        v
Targeted browser observation
        |
        v
LLM decides the next action
        |
        v
Playwright / browser control executes it
        |
        v
Browser state is observed again
        |
        v
Repeat until the objective is complete
        |
        v
Structured result
~~~

For a deeper technical view, see [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

---

# Installation and first use

This README is the single source of truth for installation and first use. The old QUICKSTART documentation has been removed to avoid duplicated instructions drifting apart.

## 1. Requirements

You need:

- Windows x64;
- Microsoft Edge or Google Chrome;
- network access to your selected LLM provider;
- valid credentials for that provider;
- UiPath Studio/Robot only if you intend to use the UiPath Library.

The operational runtime is installed under:

~~~text
%LOCALAPPDATA%\NAVIA_PATH
~~~

For example:

~~~text
C:\Users\<YOUR_USER>\AppData\Local\NAVIA_PATH
~~~

---

## 2. Download the repository

Download the repository ZIP from GitHub or clone the repository, then extract it to a user-writable directory.

Example:

~~~text
C:\Users\<YOUR_USER>\projects\NAVIA PATH
~~~

Paths containing spaces are supported.

The distribution contains the versioned executable, manifest, environment preparation scripts, provider templates and UiPath Library.

---

## 3. Windows security / Mark of the Web

Files downloaded from GitHub can inherit Windows **Mark of the Web** metadata.

On machines using PowerShell RemoteSigned, this can cause an error such as:

~~~text
CHECK_ENVIRONMENT.ps1 cannot be loaded.
The file is not digitally signed.
~~~

### Recommended: unblock the ZIP before extraction

1. Right-click the downloaded ZIP.
2. Select **Properties**.
3. Enable **Unblock** if Windows shows the option.
4. Click **Apply**.
5. Extract the archive.

### If you already extracted the repository

Unblock the environment script:

~~~powershell
Unblock-File -LiteralPath "C:\path\to\NAVIA PATH\CHECK_ENVIRONMENT.ps1"
~~~

If Windows marked the whole extracted tree, you can unblock all files in that extracted copy:

~~~powershell
Get-ChildItem -LiteralPath "C:\path\to\NAVIA PATH" -Recurse -File | Unblock-File
~~~

NAVIA does **not** require ExecutionPolicy Bypass. The public CMD launcher invokes PowerShell with process-local RemoteSigned behavior and does not change the user or machine execution policy.

### Enterprise application-control note

The current public executable is not Authenticode-signed. Enterprise EDR/ASR/application-control products can therefore audit or block it because it is a newly compiled or low-prevalence executable.

Do not disable security controls. Verify the SHA256 against CURRENT_VERSION.txt and coordinate with your security team when required. See [SECURITY.md](SECURITY.md).

---

# Provider configuration

Provider templates are stored under:

~~~text
config\providers\
~~~

Available templates:

~~~text
.env.vertex.example
.env.gemini.example
.env.openai.example
.env.anthropic.example
.env.azure_openai.example
~~~

Copy the template for the provider you want to use and remove only the final .example suffix.

Example for Vertex:

~~~powershell
Copy-Item ".\config\providers\.env.vertex.example" ".\config\providers\.env.vertex"
~~~

Keep the original .example file. It is public documentation; the active .env file is your local configuration and is ignored by Git.

### Important when several active provider files exist

CHECK_ENVIRONMENT can auto-detect an active provider file, but if you maintain more than one active .env file, select the provider explicitly:

~~~cmd
CHECK_ENVIRONMENT.cmd -Provider vertex
~~~

or:

~~~cmd
CHECK_ENVIRONMENT.cmd -Provider openai
~~~

This makes the selected provider unambiguous.

---

# Google Vertex AI setup

Vertex is the most complete portable example because it can use a local credential JSON or standard Google ADC.

## 1. Create the active configuration

~~~powershell
Copy-Item ".\config\providers\.env.vertex.example" ".\config\providers\.env.vertex"
~~~

Edit:

~~~text
config\providers\.env.vertex
~~~

Example:

~~~dotenv
NAVIA_PROVIDER=vertex
NAVIA_VERTEX_PROJECT=<YOUR_GCP_PROJECT_ID>
NAVIA_VERTEX_LOCATION=global
NAVIA_VERTEX_MODEL=gemini-3.8-flash
NAVIA_VERTEX_TIMEOUT_SECONDS=60
GOOGLE_APPLICATION_CREDENTIALS=credentials\vertex_credentials.json
~~~

Replace <YOUR_GCP_PROJECT_ID> with your own Google Cloud project.

## 2. Add credentials

For the portable file-based setup, place your credential JSON at:

~~~text
credentials\vertex_credentials.json
~~~

Keep this path relative in the extracted distribution:

~~~dotenv
GOOGLE_APPLICATION_CREDENTIALS=credentials\vertex_credentials.json
~~~

Do not manually rewrite it to an AppData path. CHECK_ENVIRONMENT installs the credential into the local runtime and updates the local runtime configuration.

### Alternative: existing Google ADC

If the machine already has Application Default Credentials, NAVIA can discover:

~~~text
%APPDATA%\gcloud\application_default_credentials.json
~~~

Vertex credential discovery follows the runtime implementation:

1. explicit GOOGLE_APPLICATION_CREDENTIALS configured in .env.vertex;
2. an existing GOOGLE_APPLICATION_CREDENTIALS environment variable;
3. standard Google ADC under %APPDATA%\gcloud;
4. extracted credentials\vertex_credentials.json when available.

For a portable distribution, the recommended option remains the relative credentials\vertex_credentials.json path.

---

# Other providers

Use the matching template and supply the values required by your account.

| Provider | Active file | Main credentials/settings |
|---|---|---|
| Gemini Direct | config\providers\.env.gemini | GEMINI_API_KEY, GEMINI_MODEL |
| OpenAI | config\providers\.env.openai | OPENAI_API_KEY, OPENAI_MODEL |
| Anthropic | config\providers\.env.anthropic | ANTHROPIC_API_KEY, ANTHROPIC_MODEL |
| Azure OpenAI | config\providers\.env.azure_openai | AZURE_OPENAI_ENDPOINT, AZURE_OPENAI_API_KEY, AZURE_OPENAI_DEPLOYMENT_NAME |

The shipped .example files contain the supported variable names and defaults. A provider-specific reference is also available in [PREPARE_LLM_ENVIRONMENTS.txt](PREPARE_LLM_ENVIRONMENTS.txt).

---

# Run CHECK_ENVIRONMENT

Once the provider configuration and credentials are ready, run:

~~~cmd
CHECK_ENVIRONMENT.cmd
~~~

For an explicit provider:

~~~cmd
CHECK_ENVIRONMENT.cmd -Provider vertex
~~~

From PowerShell:

~~~powershell
cmd /c CHECK_ENVIRONMENT.cmd -Provider vertex
~~~

You can also invoke the PowerShell script directly when allowed by your execution policy:

~~~powershell
.\CHECK_ENVIRONMENT.ps1 -Provider vertex
~~~

## What CHECK_ENVIRONMENT actually does

The current 1.1.12 workflow:

1. chooses %LOCALAPPDATA%\NAVIA_PATH as the default runtime root;
2. creates Runs, Logs, Cache, EdgeProfile, ChromeProfile, Secrets, config and Bootstrap directories;
3. verifies that the local runtime is writable;
4. locates the NAVIA distribution and CURRENT_VERSION.txt;
5. reads the release manifest;
6. calculates the source executable SHA256;
7. refuses installation if the executable hash does not match the manifest;
8. installs the versioned executable locally;
9. creates/refreshes the stable %LOCALAPPDATA%\NAVIA_PATH\NAVIA_PATH.exe entry point;
10. removes obsolete versioned NAVIA executables from the local runtime;
11. copies the public configuration into the local runtime;
12. installs provider credentials when required;
13. for Vertex, copies the resolved credential JSON to the local Secrets directory and rewrites the installed local .env.vertex to reference it;
14. sets the NAVIA runtime environment for the current process;
15. runs the canonical NAVIA_PATH.exe --check for provider and browser readiness;
16. removes any stale readiness marker if the check fails;
17. runs NAVIA_PATH.exe --mark-ready after a successful check;
18. verifies that NAVIA_READY.json was actually created.

A successful run ends with output similar to:

~~~text
[OK] NAVIA PATH v1.1.12 is READY and operational.
[OK] Local Runtime Root: C:\Users\<USER>\AppData\Local\NAVIA_PATH
[OK] Executable: C:\Users\<USER>\AppData\Local\NAVIA_PATH\NAVIA_PATH.exe
~~~

---

# Local runtime after preparation

A prepared runtime looks similar to:

~~~text
%LOCALAPPDATA%\NAVIA_PATH\
|
|-- NAVIA_PATH.exe
|-- NAVIA_PATH_v1.1.12.exe
|-- CURRENT_VERSION.txt
|-- NAVIA_READY.json
|
|-- config\
|   \-- providers\
|       \-- .env.<provider>
|
|-- Secrets\
|   \-- application_default_credentials.json
|
|-- Runs\
|-- Logs\
|-- Cache\
|-- EdgeProfile\
|-- ChromeProfile\
\-- Bootstrap\
~~~

For Vertex file-based credentials, the installed local runtime is isolated from the downloaded credentials directory after successful preparation.

---

# Verify the installed runtime

Check the version:

~~~powershell
& "$env:LOCALAPPDATA\NAVIA_PATH\NAVIA_PATH.exe" --version
~~~

Expected:

~~~text
NAVIA_PATH v1.1.12
~~~

Run the fast local-only runtime check:

~~~powershell
& "$env:LOCALAPPDATA\NAVIA_PATH\NAVIA_PATH.exe" --check-runtime --json
~~~

The fast runtime check is designed to validate local consistency without performing an LLM mission.

For a full provider/environment check:

~~~powershell
& "$env:LOCALAPPDATA\NAVIA_PATH\NAVIA_PATH.exe" --check --provider vertex --json
~~~

Use your provider name instead of vertex when applicable.

---

# Execute your first NAVIA mission

Microsoft Edge:

~~~powershell
$NavIA = "$env:LOCALAPPDATA\NAVIA_PATH\NAVIA_PATH.exe"
& $NavIA run --browser msedge --prompt "Open https://example.com and tell me the page title" --max-iterations 10 --close-browser false
~~~

Google Chrome:

~~~powershell
$NavIA = "$env:LOCALAPPDATA\NAVIA_PATH\NAVIA_PATH.exe"
& $NavIA run --browser chrome --prompt "Open https://example.com and tell me the page title" --max-iterations 10 --close-browser false
~~~

The CLI also supports a base64 prompt and an explicit result-file path, which is how the UiPath activities integrate with the runtime.

---

# UiPath integration

The repository includes:

~~~text
uipath\NAVIA_PATH.Activities
~~~

Current UiPath Library version:

~~~text
4.1.1
~~~

Embedded/current NAVIA runtime:

~~~text
1.1.12
~~~

The two public activities are:

- NAVIA PATH - Edge;
- NAVIA PATH - Chrome.

## Public activity contract

Inputs:

~~~text
in_UserPrompt
in_MaxIterations
in_CloseBrowserAfterExecution
~~~

Outputs:

~~~text
out_ExecutionResult
out_NavIA_Window
~~~

The executable path is resolved internally. There is no public in_NavIAPathExe argument.

The recommended operational model is:

~~~text
CHECK_ENVIRONMENT once
        |
        v
%LOCALAPPDATA%\NAVIA_PATH is READY
        |
        v
UiPath activity resolves local NAVIA_PATH.exe
        |
        v
Activity prepares/attaches the debug browser session
        |
        v
NAVIA runs synchronously
        |
        v
result.json is read into out_ExecutionResult
~~~

Binding out_ExecutionResult in the calling workflow is optional. Bind it when the parent workflow needs to consume the returned JSON.

For UiPath-specific details see [uipath/NAVIA_PATH.Activities/README.md](uipath/NAVIA_PATH.Activities/README.md).

---

# Runtime readiness

After a successful full environment check, NAVIA writes:

~~~text
%LOCALAPPDATA%\NAVIA_PATH\NAVIA_READY.json
~~~

The readiness marker contains non-secret runtime metadata such as version, provider, executable integrity metadata, configuration fingerprint and credential fingerprint.

It must never contain credential contents.

If the provider configuration, credential file or runtime changes materially, rerun:

~~~cmd
CHECK_ENVIRONMENT.cmd
~~~

---

# Upgrade from an older runtime

When moving from an older NAVIA runtime, extract/configure the new distribution and rerun CHECK_ENVIRONMENT.

Verify afterward:

~~~powershell
& "$env:LOCALAPPDATA\NAVIA_PATH\NAVIA_PATH.exe" --version
& "$env:LOCALAPPDATA\NAVIA_PATH\NAVIA_PATH.exe" --check-runtime --json
~~~

If an old local runtime is interfering with a test, preserve it as a backup rather than deleting it immediately:

~~~powershell
$Runtime = "$env:LOCALAPPDATA\NAVIA_PATH"
if (Test-Path $Runtime) { Rename-Item -LiteralPath $Runtime -NewName "NAVIA_PATH_BACKUP_OLD" }
~~~

Then rerun CHECK_ENVIRONMENT from the new extracted distribution.

---

# Troubleshooting

## CHECK_ENVIRONMENT.ps1 is not digitally signed

Unblock the downloaded script or the ZIP as described in the Windows security section, then rerun CHECK_ENVIRONMENT.cmd.

## NAVIA_READY.json is missing

The complete environment preparation did not finish successfully. Do not create the file manually. Rerun CHECK_ENVIRONMENT and resolve the reported validation error.

## --check-runtime is not recognized

Check the installed version:

~~~powershell
& "$env:LOCALAPPDATA\NAVIA_PATH\NAVIA_PATH.exe" --version
~~~

If the runtime is older than 1.1.12, prepare the current distribution again.

## Vertex credentials are not detected

Verify that:

~~~text
credentials\vertex_credentials.json
~~~

exists and that your active .env.vertex points to:

~~~dotenv
GOOGLE_APPLICATION_CREDENTIALS=credentials\vertex_credentials.json
~~~

Then rerun CHECK_ENVIRONMENT.

## Google ADC quota-project warning

Google can warn when end-user ADC credentials do not contain a quota project. If NAVIA reports successful configuration and authentication, the local authentication check succeeded; API enablement and quota behavior can still depend on the selected Google Cloud project and organization.

## Enterprise security blocks the executable

Do not disable ASR, EDR or application-control policies. Compare the executable SHA256 with CURRENT_VERSION.txt and provide the repository, version and hash to your security team if an allow-list or review is required.

---

# Security

Never commit:

- active .env provider files;
- Google ADC JSON files;
- API keys;
- access or refresh tokens;
- client secrets;
- private keys;
- anything from %LOCALAPPDATA%\NAVIA_PATH\Secrets.

The repository ships only provider examples. Real credentials are user-supplied and local.

See [SECURITY.md](SECURITY.md) for the full policy.

---

# Repository layout

~~~text
NAVIA_PATH\
|
|-- README.md
|-- RELEASE_NOTES.md
|-- SECURITY.md
|-- CONTRIBUTING.md
|-- LICENSE
|
|-- CURRENT_VERSION.txt
|-- NAVIA_PATH_v1.1.12.exe
|-- CHECK_ENVIRONMENT.cmd
|-- CHECK_ENVIRONMENT.ps1
|-- NAVIA_BOOTSTRAP.ps1
|-- NAVIA_SYNC_CHECK.ps1
|-- INSTALL_LOCAL.ps1
|
|-- config\
|   \-- providers\
|
|-- credentials\
|
|-- docs\
|   |-- ARCHITECTURE.md
|   \-- NAVIA_DEMO.mp4
|
\-- uipath\
    \-- NAVIA_PATH.Activities\
~~~

---

# Documentation

- [Release notes](RELEASE_NOTES.md)
- [Security policy](SECURITY.md)
- [Contributing](CONTRIBUTING.md)
- [Architecture](docs/ARCHITECTURE.md)
- [UiPath Library](uipath/NAVIA_PATH.Activities/README.md)
- [Provider reference](PREPARE_LLM_ENVIRONMENTS.txt)

---

# License

NAVIA is distributed under the MIT License. See [LICENSE](LICENSE).
