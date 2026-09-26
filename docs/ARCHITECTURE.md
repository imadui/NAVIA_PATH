# NAVIA Architecture

## Overview

NAVIA is a compiled Windows browser-agent runtime with optional UiPath integration.

~~~text
User / UiPath workflow
        |
        v
NAVIA_PATH.exe
        |
        +--------------------+
        |                    |
        v                    v
Provider layer         Browser control
Vertex / Gemini        Edge / Chrome
OpenAI / Anthropic     persistent debug profile
Azure OpenAI           Playwright / CDP
        |                    |
        +---------+----------+
                  |
                  v
             Web application
~~~

## Distribution vs local runtime

The downloaded repository is a distribution source. CHECK_ENVIRONMENT installs the operational runtime into:

~~~text
%LOCALAPPDATA%\NAVIA_PATH
~~~

The distribution contains the versioned executable, CURRENT_VERSION.txt, environment scripts, public configuration, provider examples, credentials instructions and UiPath activities.

The local runtime contains the stable NAVIA_PATH.exe, current versioned executable, local manifest, NAVIA_READY.json, active local configuration, local Secrets, browser profiles and run/log/cache directories.

## Environment preparation flow

~~~text
CHECK_ENVIRONMENT.cmd
        |
        v
CHECK_ENVIRONMENT.ps1
        |
        +--> locate distribution
        +--> read CURRENT_VERSION.txt
        +--> SHA256 source executable
        |       |
        |       +--> mismatch => stop
        +--> install under %LOCALAPPDATA%\NAVIA_PATH
        +--> refresh stable NAVIA_PATH.exe
        +--> copy configuration
        +--> resolve/install credentials
        +--> NAVIA_PATH.exe --check
        |       |
        |       +--> failure => remove stale READY marker
        +--> NAVIA_PATH.exe --mark-ready
        |
        v
NAVIA_READY.json
~~~

CHECK_ENVIRONMENT is the authoritative full preparation path.

## Provider layer

Provider selection is external to the executable. Provider templates live under config\providers.

Current provider families:

- Vertex AI;
- Gemini Direct;
- OpenAI;
- Anthropic;
- Azure OpenAI.

### Vertex credential isolation

A portable distribution can reference credentials\vertex_credentials.json.

CHECK_ENVIRONMENT resolves that file, validates JSON syntax, copies it to the local Secrets directory and rewrites the installed local .env.vertex to point to the isolated local copy.

## Agent execution flow

~~~text
Prompt
  |
  v
Observe relevant browser state
  |
  v
Build model context
  |
  v
LLM selects next action
  |
  v
Validate / execute browser action
  |
  v
Observe new state
  |
  +------> repeat
  |
  v
Finish
  |
  v
Structured JSON result
~~~

The runtime supports max-iteration limits and explicit result-file output.

## Browser model

NAVIA uses the installed system browser rather than downloading a separate browser.

Supported channels:

~~~text
msedge
edge
chrome
~~~

Persistent runtime profile directories:

~~~text
%LOCALAPPDATA%\NAVIA_PATH\EdgeProfile
%LOCALAPPDATA%\NAVIA_PATH\ChromeProfile
~~~

UiPath activities prepare a browser/debug session and then run NAVIA against that session.

## UiPath integration

Current Library version: 4.1.1  
Current NAVIA runtime: 1.1.12

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

The executable path is internal.

High-level execution:

~~~text
UiPath activity
      |
      v
Resolve local runtime / readiness
      |
      v
Attach current browser session
      |
      v
Open/prepare dedicated debug browser
      |
      v
Detect debug connectivity
      |
      v
Build prompt/result arguments
      |
      v
Start NAVIA synchronously
      |
      v
Read result.json
      |
      v
out_ExecutionResult
~~~

When a prepared local runtime is available, the activity uses the local fast path instead of repeating full provider preparation.

## Readiness model

NAVIA_READY.json is a local trust/readiness marker created only after the full environment check succeeds.

It captures non-secret metadata about runtime version, executable integrity, provider, configuration state and credential state/fingerprint.

## Trust boundaries

1. **Downloaded distribution** — verify executable integrity before local installation.
2. **Local Secrets** — never commit or publish.
3. **LLM provider** — prompts/observations leave the workstation according to provider configuration and organizational policy.
4. **Authenticated browser session** — NAVIA can act with the permissions of that browser session.
5. **UiPath caller** — the workflow decides the prompt, iteration limit and whether it consumes the result.

See [../SECURITY.md](../SECURITY.md) for operational security guidance.
