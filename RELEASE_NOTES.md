# Release Notes — NAVIA_PATH v1.1.11

Initial public release of **NAVIA_PATH**, the autonomous intelligent browser automation solution for enterprise workflows and RPA robots.

---

## What's New in v1.1.11

### Intelligent Multi-Step Web Navigation
- Autonomous problem solving across complex web portals, multi-tab workflows, and dynamic single-page applications.
- Natural interaction with modern Web controls: forms, dynamic dropdowns, buttons, modals, and input fields.
- Resilient to network delays, asynchronous page loading, and DOM transitions.

### Comprehensive Table Understanding & Data Extraction
- Targeted tabular data extraction from data-dense enterprise dashboards.
- Detection and semantic comprehension of table columns, headers, and rows.
- Structured, reliable JSON output formatted for immediate downstream workflow consumption.

### First-Class Edge and Chrome Support
- Symmetrical support for both enterprise reference browsers: **Microsoft Edge** and **Google Chrome**.
- Attaches directly to existing system browser installations without downloading custom browser binaries.

### Persistent Browser Sessions
- Dedicated persistent profiles preserved under `%LOCALAPPDATA%\NAVIA_PATH`.
- Preserves cookies and session states across executions to eliminate repeated login sequences.

### Native UiPath Integration
- Dedicated activity library (`NAVIA_PATH.Activities`) for UiPath Studio.
- Activities: **`NAVIA PATH - Edge`** and **`NAVIA PATH - Chrome`**.
- Dynamic executable resolution, synchronous background execution without console clutter, and direct output mapping into workflow variables.

### Interchangeable Multi-Provider LLM Engine
- Switch seamlessly between 5 major AI providers:
  - **Google Vertex AI**
  - **Google Gemini Direct API**
  - **OpenAI** (GPT-4o)
  - **Anthropic Claude** (Claude 3.5 Sonnet)
  - **Azure OpenAI Service**
- Dedicated, clean `.env.<provider>` templates with zero hardcoded credentials.

### Autonomous Standalone Windows Distribution
- Single x64 binary (`NAVIA_PATH.exe`).
- Zero Python installation or package management needed on target workstations.
- Built-in diagnostic CLI command (`NAVIA_PATH.exe --check`) for pre-flight readiness checks.
