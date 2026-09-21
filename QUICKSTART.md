# Quickstart Guide — NAVIA_PATH

Get started with NAVIA_PATH in 5 minutes.

---

## Step 1: Download & Extract

Extract the archive `NAVIA_PATH-v1.1.12-windows-x64.zip` into your directory of choice, for example:
```text
C:\NAVIA_PATH
```

---

## Step 2: Choose Your LLM Provider

NAVIA_PATH supports 5 leading AI providers:
- **Google Vertex AI** *(Default, recommended)*
- **Google Gemini Direct API**
- **OpenAI** (GPT-4o)
- **Anthropic Claude** (Claude 3.5 Sonnet)
- **Azure OpenAI Service**

---

## Step 3: Prepare Your Configuration

In the `config\providers\` subfolder, copy the example template for your chosen provider:

- **For Vertex AI**:
  ```powershell
  copy config\providers\.env.vertex.example config\providers\.env.vertex
  ```
  Open `.env.vertex` and set your `NAVIA_VERTEX_PROJECT`, `NAVIA_VERTEX_LOCATION`, and `NAVIA_VERTEX_MODEL`.

  Next, provide your credentials using either of two methods:

  **Method A (Portable JSON file - recommended for robots and offline distributions):**
  Place your Google service account / ADC credential JSON file at:
  ```text
  credentials\vertex_credentials.json
  ```
  Keep the default line in `.env.vertex`:
  ```env
  GOOGLE_APPLICATION_CREDENTIALS=credentials\vertex_credentials.json
  ```
  Relative paths are resolved automatically relative to the extracted distribution root.

  **Method B (Standard Google ADC):**
  If you have already authenticated using Google Cloud CLI on this machine:
  ```powershell
  gcloud auth application-default login
  ```
  NAVIA automatically discovers standard ADC at `%APPDATA%\gcloud\application_default_credentials.json`.

- **For OpenAI**:
  ```powershell
  copy config\providers\.env.openai.example config\providers\.env.openai
  ```
  Open `.env.openai` and paste your `OPENAI_API_KEY`.

*(For other providers, consult `PREPARE_LLM_ENVIRONMENTS.txt`).*

---

## Step 4: Run Environment Preparation & Check

Double-click the public launcher:
```cmd
CHECK_ENVIRONMENT.cmd
```
*(Or from CMD / terminal: `CHECK_ENVIRONMENT.cmd`)*

This launcher automatically configures a process-local `RemoteSigned` policy without modifying your system or user execution policy (no `Bypass` required).

Advanced users in PowerShell can also run:
```powershell
.\CHECK_ENVIRONMENT.ps1
```

This script:
1. Verifies the SHA256 integrity of the executable.
2. Prepares the isolated local runtime under `%LOCALAPPDATA%\NAVIA_PATH`.
3. Securely copies credentials into `%LOCALAPPDATA%\NAVIA_PATH\Secrets`.
4. Runs the canonical `NAVIA_PATH.exe --check` to validate provider authentication and browser prerequisites.
5. On success, creates `%LOCALAPPDATA%\NAVIA_PATH\NAVIA_READY.json`.

Wait for the final line:
```text
[OK] NAVIA PATH v1.1.12 is READY and operational.
```

---

## Step 5: Execute Your First Mission

### Command Line / PowerShell:
```powershell
%LOCALAPPDATA%\NAVIA_PATH\NAVIA_PATH.exe --prompt "Navigate to https://example.com and extract page details"
```

### From UiPath Studio:
Open the `uipath\NAVIA_PATH.Activities` project in UiPath Studio or reference the activity package in your workflows. Drop the `NAVIA PATH - Edge` or `NAVIA PATH - Chrome` activity into your sequence, set `in_UserPrompt`, and retrieve structured output from `out_ExecutionResult`.

Because `CHECK_ENVIRONMENT.ps1` marked the local installation READY, UiPath executes via the instant fast path without bootstrap delays or repeated provider checks!
