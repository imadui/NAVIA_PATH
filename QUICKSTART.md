# Quickstart Guide — NAVIA_PATH

Get started with NAVIA_PATH in 5 minutes.

---

## Step 1: Download & Extract

Extract the archive `NAVIA_PATH-v1.0.0-windows-x64.zip` into your directory of choice, for example:
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
  ```cmd
  copy config\providers\.env.vertex.example config\providers\.env.vertex
  ```
  Open `.env.vertex` and set your `NAVIA_VERTEX_PROJECT`. Authenticate once with Google Cloud CLI:
  ```powershell
  gcloud auth application-default login
  ```

- **For OpenAI**:
  ```cmd
  copy config\providers\.env.openai.example config\providers\.env.openai
  ```
  Open `.env.openai` and paste your `OPENAI_API_KEY`.

*(For other providers, consult `PREPARE_LLM_ENVIRONMENTS.txt`).*

---

## Step 4: Run the Environment Health Check

Execute the built-in diagnostic command:

```powershell
.\NAVIA_PATH.exe --check
```

The report should confirm your setup:
```text
============================================================
 NAVIA_PATH v1.0.0 - Runtime Environment Check
============================================================
Executable     : C:\NAVIA_PATH\NAVIA_PATH.exe
Runtime Root   : C:\Users\...\AppData\Local\NAVIA_PATH
Write Access   : OK
Provider       : vertex
Config File    : config\providers\.env.vertex (Present)
Configuration  : OK
Authentication : OK
Model          : gemini-3.8-flash
Edge Browser   : OK
Chrome Browser : OK
CDP Profiles   : EdgeProfile, ChromeProfile (Ready)
============================================================
RESULT : OK - NAVIA_PATH is ready for execution.
```

---

## Step 5: Execute Your First Mission

### Command Line:
```powershell
.\NAVIA_PATH.exe --prompt "Navigate to https://example.com and extract page details"
```

### From UiPath Studio:
Open the `uipath\NAVIA_PATH.Activities` project in UiPath Studio or reference the activity in your workflows. Drop the `NAVIA PATH - Edge` or `NAVIA PATH - Chrome` activity into your sequence, set your prompt, and retrieve the result from `out_ExecutionResult`.
