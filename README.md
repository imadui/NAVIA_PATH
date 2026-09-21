# NAVIA_PATH

**Autonomous multi-provider intelligent Web automation agent for RPA robots and Windows workstations.**

---

## Overview

NAVIA_PATH is an autonomous, compiled runtime designed to allow automation platforms (UiPath, background scripts, enterprise schedulers) to interact intelligently with complex Web applications through large language models.

It pairs deterministic browser control with multimodal context reasoning to:
- Execute multi-step business journeys across pages and tabs.
- Extract structured data from complex tables, dashboards, and dynamic views.
- Interact seamlessly with enterprise browsers (**Microsoft Edge** and **Google Chrome**).
- Maintain persistent, authenticated browser sessions to eliminate repetitive logins.

---

## Key Highlights

- **Standalone & Autonomous**: Packaged as a single Windows x64 executable (`NAVIA_PATH.exe`). No external Python runtime, pip dependencies, or virtual environment required on user machines.
- **Ready-to-Use UiPath Integration**: Ships with the `NAVIA_PATH.Activities` library (`NAVIA PATH - Edge`, `NAVIA PATH - Chrome`) for native UiPath Studio workflows.
- **Multi-Provider Architecture**: Native support for **Google Vertex AI**, **Google Gemini Direct API**, **OpenAI**, **Anthropic Claude**, and **Azure OpenAI Service**.
- **External Configuration**: Credentials, endpoints, models, and timeouts are fully configured outside the binary via isolated `.env.<provider>` files.
- **Persistent Sessions**: User session cookies and profiles are maintained automatically in `%LOCALAPPDATA%\NAVIA_PATH`.
- **Integrated Health Diagnostics**: Instant environment and credentials validation via `NAVIA_PATH.exe --check`.

---

## Quick Start

### 1. Extract
Extract the release archive (`NAVIA_PATH-v1.1.12-windows-x64.zip`) into your target folder (e.g., `C:\NAVIA_PATH`).

### 2. Configure Your Provider
In `config\providers\`, copy the example file for your provider:
```powershell
copy config\providers\.env.vertex.example config\providers\.env.vertex
```
Edit `.env.vertex` with your project ID:
```env
NAVIA_PROVIDER=vertex
NAVIA_VERTEX_PROJECT=my-gcp-project
NAVIA_VERTEX_LOCATION=global
NAVIA_VERTEX_MODEL=gemini-3.8-flash
NAVIA_VERTEX_TIMEOUT_SECONDS=60
GOOGLE_APPLICATION_CREDENTIALS=credentials\vertex_credentials.json
```

### 3. Place Credentials (if required)
Place your Google service account / ADC credential JSON file at:
```text
credentials\vertex_credentials.json
```
*(Alternatively, if you already authenticated via `gcloud auth application-default login`, standard ADC at `%APPDATA%\gcloud\application_default_credentials.json` is automatically discovered).*

### 4. Run Environment Check
Double-click `CHECK_ENVIRONMENT.cmd` (or from cmd/terminal: `CHECK_ENVIRONMENT.cmd`).
Advanced users in PowerShell can also run:
```powershell
.\CHECK_ENVIRONMENT.ps1
```
This prepares and validates the local runtime under `%LOCALAPPDATA%\NAVIA_PATH`.

### 5. Start Using NAVIA
Once `status = OK` is reported, NAVIA is immediately usable from:
- **Command Line / PowerShell**:
  ```powershell
  %LOCALAPPDATA%\NAVIA_PATH\NAVIA_PATH.exe --prompt "Open portal and check status"
  ```
- **UiPath Studio**: Use the activities `NAVIA PATH - Edge` or `NAVIA PATH - Chrome`.

For a detailed step-by-step walkthrough, see **[QUICKSTART.md](QUICKSTART.md)**.  
For provider-specific configuration guides, see **[PREPARE_LLM_ENVIRONMENTS.txt](PREPARE_LLM_ENVIRONMENTS.txt)**.
For credentials guide and relative path resolution, see **[credentials\README.txt](credentials/README.txt)**.

---

## Supported Providers

| Provider | Default Model | Authentication Mechanism |
| :--- | :--- | :--- |
| **Google Vertex AI** *(Default)* | Gemini 3.8 Flash | Application Default Credentials (`gcloud auth application-default login`) |
| **Google Gemini Direct** | Gemini 2.5 Flash | API Key (`GEMINI_API_KEY`) |
| **OpenAI** | GPT-4o | API Key (`OPENAI_API_KEY`) |
| **Anthropic Claude** | Claude 3.5 Sonnet | API Key (`ANTHROPIC_API_KEY`) |
| **Azure OpenAI** | GPT-4o *(deployment)* | Endpoint & API Key (`AZURE_OPENAI_API_KEY`) |

---

## UiPath Integration

The distribution includes the ready-to-import activity project in `uipath\NAVIA_PATH.Activities`:
- **`NAVIA PATH - Edge`**: Automates a persistent Microsoft Edge session.
- **`NAVIA PATH - Chrome`**: Automates a persistent Google Chrome session.

The activities dynamically discover `NAVIA_PATH.exe`, ensure debugging prerequisites, run synchronously without background console windows, and populate `out_ExecutionResult` with structured JSON data.

---

## CLI Reference

```text
NAVIA_PATH.exe [--check] [--check-runtime] [--version] [run] [OPTIONS]

Commands:
  check                     Verify configuration, provider authentication and browser
  check-runtime             Fast local-only check of runtime consistency
  mark-ready                Write local NAVIA_READY.json marker
  run                       Execute the agent on a user prompt

Options:
  --prompt TEXT             Task objective in plain text
  --prompt-base64 B64       Task objective encoded in base64
  --max-iterations INT      Maximum iteration limit (default: 20)
  --result-file PATH        Path to JSON result output file
  --close-browser BOOL      Close browser upon completion (true/false)
  --require-attached-browser BOOL
                            Require strict attachment to existing debug browser
  --browser CHANNEL         Target browser channel: msedge or chrome
  --check                   Comprehensive health and configuration check
  --check-runtime           Fast local-only runtime integrity check
  --version, -v             Display version information
```

---

## License

This project is licensed under the MIT License - see the **[LICENSE](LICENSE)** file for details.
