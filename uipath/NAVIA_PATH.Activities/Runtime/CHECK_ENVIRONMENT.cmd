@echo off
setlocal
set "SCRIPT_DIR=%~dp0"
set "TARGET_PS1=%SCRIPT_DIR%CHECK_ENVIRONMENT.ps1"

if not exist "%TARGET_PS1%" (
    echo [ERROR] Sibling script not found: "%TARGET_PS1%"
    exit /b 1
)

powershell.exe -NoProfile -NonInteractive -ExecutionPolicy RemoteSigned -File "%TARGET_PS1%" %*
set "EXIT_CODE=%ERRORLEVEL%"

exit /b %EXIT_CODE%
