# NAVIA_PATH.Activities

UiPath activity library for **NAVIA PATH**.

Current versions:

~~~text
UiPath Library : 4.1.1
NAVIA Runtime  : 1.1.12
Target         : Windows
~~~

The Library exposes:

- NAVIA PATH - Edge
- NAVIA PATH - Chrome

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

There is no public executable-path argument. The Library resolves NAVIA_PATH.exe internally.

Binding out_ExecutionResult is optional. Leave it unbound when the calling workflow does not need the returned JSON.

## Recommended preparation

Before normal UiPath execution, prepare the local runtime once from the extracted NAVIA distribution:

~~~cmd
CHECK_ENVIRONMENT.cmd
~~~

or with an explicit provider:

~~~cmd
CHECK_ENVIRONMENT.cmd -Provider vertex
~~~

This installs and validates the operational runtime under %LOCALAPPDATA%\NAVIA_PATH.

## Fast path

When the local runtime is already prepared and readiness/version metadata is coherent, the activity resolves:

~~~text
%LOCALAPPDATA%\NAVIA_PATH\NAVIA_PATH.exe
~~~

directly.

The prepared-runtime path does not need to repeat the full public CHECK_ENVIRONMENT workflow before each mission.

If the expected local runtime cannot be resolved, the activity contains bootstrap fallback logic that searches its local/bundled package context and prepares the runtime locally before continuing.

## Browser session flow

The activity:

1. resolves the NAVIA executable;
2. attaches the current Edge/Chrome browser context;
3. opens/prepares the NAVIA debug browser profile;
4. verifies the remote-debugging connection;
5. builds a Base64 prompt and unique run directory;
6. launches NAVIA synchronously;
7. reads the generated result.json;
8. maps the JSON string to out_ExecutionResult when the caller binds it.

Browser profile directories:

~~~text
%LOCALAPPDATA%\NAVIA_PATH\EdgeProfile
%LOCALAPPDATA%\NAVIA_PATH\ChromeProfile
~~~

Run artifacts:

~~~text
%LOCALAPPDATA%\NAVIA_PATH\Runs\<run-id>
~~~

## Runtime package safety

The public distribution and UiPath package must never include active provider .env files, Google ADC files, API keys/tokens, a populated Secrets directory or organization-specific deployment credentials.

Provider .example files are safe templates only.

## Troubleshooting

~~~powershell
& "$env:LOCALAPPDATA\NAVIA_PATH\NAVIA_PATH.exe" --version
& "$env:LOCALAPPDATA\NAVIA_PATH\NAVIA_PATH.exe" --check-runtime --json
~~~

Expected:

~~~text
NAVIA_PATH v1.1.12
~~~

If the runtime/configuration/credentials changed materially, rerun CHECK_ENVIRONMENT from the current distribution.

For the full operating procedure see the repository [README.md](../../README.md).
