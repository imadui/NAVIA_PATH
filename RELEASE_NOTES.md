# NAVIA PATH — Release Notes

## 1.1.12

**Runtime:** NAVIA_PATH 1.1.12  
**UiPath Library:** 4.1.1  
**Platform:** Windows x64

NAVIA PATH 1.1.12 focuses on public distribution, portable runtime preparation, deterministic readiness checks, provider credential handling and reliable UiPath integration.

### Highlights

- Added CHECK_ENVIRONMENT.cmd as the public Windows launcher.
- Added the authoritative CHECK_ENVIRONMENT.ps1 preparation and validation workflow.
- Added local runtime installation under %LOCALAPPDATA%\NAVIA_PATH.
- Added NAVIA_READY.json readiness metadata.
- Added --check-runtime --json for fast local consistency validation.
- Added portable Vertex credential handling with relative paths.
- Added local credential isolation under %LOCALAPPDATA%\NAVIA_PATH\Secrets.
- Added provider configuration and credential fingerprinting to readiness.
- Added/standardized the UiPath fast path for a prepared local runtime.
- Decoupled UiPath Library versioning from NAVIA runtime versioning.
- Removed public dependency on organization-specific infrastructure paths.
- Consolidated end-user installation and operating instructions into README.md.

---

## Public environment preparation

CHECK_ENVIRONMENT now acts as the public installer and authoritative full environment validator.

~~~text
Downloaded distribution
        |
        v
Manifest / SHA256 verification
        |
        v
Local installation under %LOCALAPPDATA%\NAVIA_PATH
        |
        v
Provider configuration + credentials
        |
        v
NAVIA_PATH.exe --check
        |
        v
NAVIA_PATH.exe --mark-ready
        |
        v
NAVIA_READY.json
~~~

The CMD launcher uses process-local RemoteSigned behavior and does not require ExecutionPolicy Bypass.

---

## Binary integrity

Release executable:

~~~text
NAVIA_PATH_v1.1.12.exe
~~~

Size:

~~~text
54,636,023 bytes
~~~

SHA256:

~~~text
8CDA87CBDB5CB8EF89E46D698EE481271141DADD0B7ABC311B5E98A01D8B55A9
~~~

CHECK_ENVIRONMENT calculates the source executable SHA256 and refuses installation when it does not match CURRENT_VERSION.txt.

---

## Runtime readiness

A successful full preparation creates:

~~~text
%LOCALAPPDATA%\NAVIA_PATH\NAVIA_READY.json
~~~

The marker contains non-secret runtime metadata such as product/runtime version, readiness status, executable integrity metadata, selected provider, provider configuration fingerprint, credential source classification, credential fingerprint and validation timestamp.

Credential contents are never stored in the readiness marker.

---

## Fast local validation

~~~powershell
NAVIA_PATH.exe --check-runtime --json
~~~

This is intended as a local consistency/readiness check. It does not execute a user mission.

Use the full check when provider/environment authentication needs to be validated:

~~~powershell
NAVIA_PATH.exe --check --provider vertex --json
~~~

---

## Vertex portability

Vertex configuration can use a relative credential path:

~~~dotenv
GOOGLE_APPLICATION_CREDENTIALS=credentials\vertex_credentials.json
~~~

During CHECK_ENVIRONMENT, the resolved JSON credential is validated and copied to:

~~~text
%LOCALAPPDATA%\NAVIA_PATH\Secrets\application_default_credentials.json
~~~

The installed local .env.vertex is rewritten to reference the isolated local copy.

Credential discovery follows the runtime implementation:

1. explicit GOOGLE_APPLICATION_CREDENTIALS in .env.vertex;
2. an existing GOOGLE_APPLICATION_CREDENTIALS environment variable;
3. standard Google ADC under %APPDATA%\gcloud;
4. extracted credentials\vertex_credentials.json when available.

---

## UiPath Library 4.1.1

The UiPath Library version is independent from the NAVIA runtime version.

Public activity contract:

~~~text
Inputs
  in_UserPrompt
  in_MaxIterations
  in_CloseBrowserAfterExecution

Outputs
  out_ExecutionResult
  out_NavIA_Window
~~~

The executable path is internal to the Library. The obsolete public executable-path argument is not part of the activity contract.

The local fast path resolves %LOCALAPPDATA%\NAVIA_PATH\NAVIA_PATH.exe when the prepared runtime is available.

The library contains Edge and Chrome activities and runs the NAVIA executable synchronously. out_ExecutionResult can be left unbound by callers that do not need to consume the returned JSON.

---

## Public distribution hardening

The public distribution was hardened to avoid embedding active provider .env files, provider credentials/ADC files, secrets directories, organization-specific UNC paths, private deployment paths or internal provider credentials.

---

## Windows security behavior

Downloaded PowerShell files can carry Mark of the Web. On RemoteSigned systems, users may need to unblock the downloaded ZIP before extraction or unblock CHECK_ENVIRONMENT.ps1 after extraction.

The public launcher does not use ExecutionPolicy Bypass.

The current executable is not Authenticode-signed. Enterprise ASR/EDR/application-control systems may therefore audit or block it as a low-prevalence/unsigned executable. Users should verify the published SHA256 and coordinate with their security team instead of disabling security controls.

---

## Documentation changes

README.md is now the single detailed end-user installation and operating guide.

Added or refreshed:

- README.md;
- SECURITY.md;
- CONTRIBUTING.md;
- docs/ARCHITECTURE.md;
- uipath/NAVIA_PATH.Activities/README.md;
- provider and credential reference text files.

The old QUICKSTART.md and generated Quickstart/README PDFs were removed to avoid duplicated, stale installation instructions.

---

## Upgrade from 1.1.11

Users upgrading an existing local runtime should prepare 1.1.12 again:

~~~cmd
CHECK_ENVIRONMENT.cmd
~~~

Then verify:

~~~powershell
& "$env:LOCALAPPDATA\NAVIA_PATH\NAVIA_PATH.exe" --version
& "$env:LOCALAPPDATA\NAVIA_PATH\NAVIA_PATH.exe" --check-runtime --json
~~~

Expected:

~~~text
NAVIA_PATH v1.1.12
~~~

---

## Validation

The 1.1.12 hardening/build regression suite completed with:

~~~text
28 passed
~~~

The public installation flow was also validated on a clean local runtime using the compiled executable, Vertex configuration, local Secrets installation, provider authentication and a real browser mission.

---

## Known environment notes

Google may warn that end-user ADC credentials have no quota project. A successful NAVIA configuration/authentication check confirms local credential usability; quota and API enablement can still depend on the selected Google Cloud project and organization.

Enterprise security products may separately require review/allow-listing of the unsigned executable.
