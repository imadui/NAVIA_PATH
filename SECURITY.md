# Security Policy

NAVIA is a browser automation runtime that can use external LLM providers, authenticated browser sessions and local credential material. Treat provider configuration and runtime secrets as sensitive.

## Credentials and secrets

Never commit or publish:

- active config/providers/.env.* files;
- credentials/vertex_credentials.json;
- Google ADC files;
- API keys;
- access tokens;
- refresh tokens;
- client secrets;
- private keys or certificates;
- files from %LOCALAPPDATA%\NAVIA_PATH\Secrets.

The repository intentionally contains only .example provider files.

## Local credential storage

For file-based Vertex credentials, CHECK_ENVIRONMENT installs the resolved JSON credential into:

~~~text
%LOCALAPPDATA%\NAVIA_PATH\Secrets\application_default_credentials.json
~~~

The local runtime then uses that isolated copy. The downloaded distribution should not be treated as a secret store.

## Executable integrity

CURRENT_VERSION.txt contains the expected runtime version, executable name and SHA256.

For NAVIA_PATH 1.1.12:

~~~text
NAVIA_PATH_v1.1.12.exe
SHA256: 8CDA87CBDB5CB8EF89E46D698EE481271141DADD0B7ABC311B5E98A01D8B55A9
~~~

CHECK_ENVIRONMENT verifies this SHA256 before installing the executable into %LOCALAPPDATA%\NAVIA_PATH.

Manual verification:

~~~powershell
Get-FileHash ".\NAVIA_PATH_v1.1.12.exe" -Algorithm SHA256
~~~

## Windows / enterprise security controls

The current public executable is not Authenticode-signed. Windows or enterprise ASR/EDR/application-control products can therefore audit or block it because it is unsigned or has low prevalence.

Do not disable ASR/EDR controls, antivirus, or use ExecutionPolicy Bypass to work around organizational policy.

Instead, provide your security team with the repository, release version, executable SHA256 and the fact that CHECK_ENVIRONMENT copies the validated runtime into %LOCALAPPDATA%\NAVIA_PATH.

## Browser sessions

NAVIA can operate against authenticated Edge/Chrome sessions. Prompts should be treated as automation instructions with the same care as conventional RPA logic.

Before running a mission that can modify data, send messages, submit forms, delete records or perform other consequential actions, confirm that the prompt accurately describes the intended scope.

## Logs and run artifacts

Runtime data may be written below:

~~~text
%LOCALAPPDATA%\NAVIA_PATH\Runs
%LOCALAPPDATA%\NAVIA_PATH\Logs
~~~

Do not publish run artifacts without reviewing them for business data, URLs, account identifiers or other sensitive content.

## Reporting a vulnerability

Do not post secrets, credentials, private URLs, exploit payloads or sensitive customer information in a public GitHub issue.

If GitHub private vulnerability reporting is available for this repository, use that channel. Otherwise, open a minimal public issue stating that you need to report a security concern privately, without including sensitive details.
