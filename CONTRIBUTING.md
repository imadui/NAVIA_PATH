# Contributing to NAVIA

Thanks for helping improve NAVIA.

This repository is the public NAVIA PATH distribution: runtime artifacts, provider templates, installation scripts, UiPath activities and documentation.

## Good contributions

Contributions are welcome for documentation corrections/examples, provider-template improvements without real credentials, UiPath activity improvements, runtime installation/bootstrap robustness, reproducible bug reports and security hardening that preserves normal enterprise controls.

## Before opening a pull request

1. Work from the current main branch.
2. Keep changes focused.
3. Do not commit active .env files, credentials, tokens or private URLs.
4. Do not add organization-specific paths, account names or infrastructure defaults.
5. Update README.md when the end-user operating procedure changes.
6. Update RELEASE_NOTES.md for release-visible behavior changes.
7. Update docs/ARCHITECTURE.md when the execution architecture changes.
8. If you change the UiPath Library contract, update uipath/NAVIA_PATH.Activities/README.md.

## Runtime binary changes

NAVIA_PATH_vX.Y.Z.exe is a generated release artifact.

A runtime binary update must be accompanied by a matching CURRENT_VERSION.txt update, correct SHA256, intended runtime version, matching embedded/bundled UiPath runtime assets when applicable, release-note updates and validation of CHECK_ENVIRONMENT and --check-runtime.

## UiPath Library

Current public Library contract:

~~~text
Inputs
  in_UserPrompt
  in_MaxIterations
  in_CloseBrowserAfterExecution

Outputs
  out_ExecutionResult
  out_NavIA_Window
~~~

Do not expose machine-specific executable paths as public activity arguments.

The current Library version is 4.1.1 and the current runtime is 1.1.12.

## Documentation source of truth

README.md is the installation and operating source of truth.

Do not recreate a separate Quickstart containing a second copy of the same setup steps. Provider-specific files may supplement the README but must not contradict it.

## Security reports

Follow [SECURITY.md](SECURITY.md). Never paste credentials or sensitive customer data into an issue or pull request.
