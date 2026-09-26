NAVIA PATH - Provider Credentials
=================================

IMPORTANT SECURITY NOTICE
-------------------------
Never commit real credentials, access keys, private keys, token files, active
provider .env files, or files from %LOCALAPPDATA%\NAVIA_PATH\Secrets.

This directory is protected by the repository .gitignore.

GOOGLE VERTEX AI - PORTABLE FILE SETUP
--------------------------------------
1. Place your credential JSON here:

   credentials\vertex_credentials.json

2. Create config\providers\.env.vertex from the shipped .example file.

3. Configure:

   GOOGLE_APPLICATION_CREDENTIALS=credentials\vertex_credentials.json
   NAVIA_VERTEX_PROJECT=<your-gcp-project-id>
   NAVIA_VERTEX_LOCATION=global
   NAVIA_VERTEX_MODEL=gemini-3.8-flash

4. Run from the distribution root:

   CHECK_ENVIRONMENT.cmd -Provider vertex

RELATIVE PATH RESOLUTION
------------------------
A relative GOOGLE_APPLICATION_CREDENTIALS value such as:

   credentials\vertex_credentials.json

is resolved relative to the extracted NAVIA PATH distribution root.

Absolute paths are also supported when allowed by your environment.

LOCAL RUNTIME ISOLATION
-----------------------
When CHECK_ENVIRONMENT succeeds, the credential JSON is copied to:

   %LOCALAPPDATA%\NAVIA_PATH\Secrets\application_default_credentials.json

and the installed local .env.vertex is rewritten to reference that isolated
local credential file.

After successful preparation, normal runtime execution does not depend on the
credential copy inside the extracted distribution.

ALTERNATIVE: STANDARD GOOGLE ADC
--------------------------------
If Google Application Default Credentials already exist at:

   %APPDATA%\gcloud\application_default_credentials.json

NAVIA can use them without placing a JSON file in this directory.

CURRENT DISCOVERY ORDER
-----------------------
1. Explicit GOOGLE_APPLICATION_CREDENTIALS in .env.vertex
2. Existing GOOGLE_APPLICATION_CREDENTIALS environment variable
3. Standard Google ADC under %APPDATA%\gcloud
4. Extracted credentials\vertex_credentials.json when available

For the complete operating procedure and Windows security notes, see the
repository README.md and SECURITY.md.
