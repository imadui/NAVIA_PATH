NAVIA PATH - Provider Credentials
=================================

IMPORTANT SECURITY NOTICE:
--------------------------
NEVER commit real credentials, access keys, private keys, or token files to Git.
This directory is protected by .gitignore.

GOOGLE VERTEX AI CREDENTIALS:
-----------------------------
To use Google Vertex AI with a service account or user credentials file:

1. Place your credentials JSON file in this directory with the name:
   vertex_credentials.json
   (e.g., credentials\vertex_credentials.json)

2. In config\providers\.env.vertex, configure:
   GOOGLE_APPLICATION_CREDENTIALS=credentials\vertex_credentials.json
   NAVIA_VERTEX_PROJECT=<your-gcp-project-id>
   NAVIA_VERTEX_LOCATION=global
   NAVIA_VERTEX_MODEL=gemini-3.8-flash

3. Run CHECK_ENVIRONMENT.ps1 in the distribution root.

HOW RELATIVE CREDENTIAL PATHS WORK:
-----------------------------------
When GOOGLE_APPLICATION_CREDENTIALS contains a relative path such as:
   credentials\vertex_credentials.json
it is resolved deterministically relative to the extracted NAVIA_PATH root directory.
Absolute paths (e.g. C:\Users\user\credentials.json) are also supported.

LOCAL RUNTIME ISOLATION:
------------------------
When CHECK_ENVIRONMENT.ps1 executes, it securely validates and copies your credentials to:
   %LOCALAPPDATA%\NAVIA_PATH\Secrets\application_default_credentials.json
and configures the local runtime to point to this isolated copy.

After successful installation, your local NAVIA_PATH runtime does NOT depend
on this extracted folder or this credentials directory. You can move, archive,
or delete the original extracted folder without breaking normal execution.

ALTERNATIVE: STANDARD GOOGLE ADC
--------------------------------
If you already use the Google Cloud CLI and have authenticated via:
   gcloud auth application-default login
your credentials are automatically discovered at:
   %APPDATA%\gcloud\application_default_credentials.json
You do not need to place a JSON file in this folder if standard ADC is present.

DISCOVERY PRECEDENCE:
---------------------
1. Explicit GOOGLE_APPLICATION_CREDENTIALS in .env.vertex (relative path resolved)
2. Process/System GOOGLE_APPLICATION_CREDENTIALS environment variable
3. Standard Google ADC (%APPDATA%\gcloud\application_default_credentials.json)
4. Otherwise fail with a clear diagnostic message
