@echo off
REM Installation script for Copy GIF Native Messaging Host (Windows)

echo ========================================
echo Copy GIF - Native Host Installer
echo ========================================
echo.

REM Get the directory where this script is located
set SCRIPT_DIR=%~dp0
set HOST_SCRIPT=%SCRIPT_DIR%copy-gif-host.py
set HOST_MANIFEST=%SCRIPT_DIR%com.copygif.host.json

REM Check if files exist
if not exist "%HOST_SCRIPT%" (
    echo Error: copy-gif-host.py not found!
    pause
    exit /b 1
)

if not exist "%HOST_MANIFEST%" (
    echo Error: com.copygif.host.json not found!
    pause
    exit /b 1
)

echo Detected OS: Windows
echo.

REM Create registry entries for different browsers
echo Which browsers would you like to install the native host for?
echo.

set /p INSTALL_CHROME="Install for Chrome? (y/n): "
set /p INSTALL_EDGE="Install for Edge? (y/n): "
set /p INSTALL_BRAVE="Install for Brave? (y/n): "

echo.
echo Installing native messaging host...
echo.

REM Function to install for Chrome
if /i "%INSTALL_CHROME%"=="y" (
    echo Installing for Chrome...
    reg add "HKCU\Software\Google\Chrome\NativeMessagingHosts\com.copygif.host" /ve /t REG_SZ /d "%SCRIPT_DIR%com.copygif.host.json" /f >nul 2>&1
    if errorlevel 1 (
        echo   X Failed to install for Chrome
    ) else (
        echo   * Installed for Chrome
    )
)

REM Function to install for Edge
if /i "%INSTALL_EDGE%"=="y" (
    echo Installing for Edge...
    reg add "HKCU\Software\Microsoft\Edge\NativeMessagingHosts\com.copygif.host" /ve /t REG_SZ /d "%SCRIPT_DIR%com.copygif.host.json" /f >nul 2>&1
    if errorlevel 1 (
        echo   X Failed to install for Edge
    ) else (
        echo   * Installed for Edge
    )
)

REM Function to install for Brave
if /i "%INSTALL_BRAVE%"=="y" (
    echo Installing for Brave...
    reg add "HKCU\Software\BraveSoftware\Brave-Browser\NativeMessagingHosts\com.copygif.host" /ve /t REG_SZ /d "%SCRIPT_DIR%com.copygif.host.json" /f >nul 2>&1
    if errorlevel 1 (
        echo   X Failed to install for Brave
    ) else (
        echo   * Installed for Brave
    )
)

REM Update the manifest with the correct path (Windows style)
powershell -Command "(Get-Content '%HOST_MANIFEST%') -replace 'PLACEHOLDER_PATH', '%SCRIPT_DIR:\=/%' | Set-Content '%HOST_MANIFEST%.temp'"
move /y "%HOST_MANIFEST%.temp" "%HOST_MANIFEST%" >nul

echo.
echo ========================================
echo Installation Complete!
echo ========================================
echo.
echo IMPORTANT: You need to update the manifest with your extension ID!
echo.
echo Steps:
echo 1. Load your extension in Chrome (chrome://extensions/)
echo 2. Enable "Developer mode" and click "Load unpacked"
echo 3. Copy the Extension ID (it looks like: abcdefghijklmnopqrstuvwxyz123456)
echo 4. Edit this file and replace PLACEHOLDER_EXTENSION_ID:
echo    %HOST_MANIFEST%
echo.
echo After updating the extension ID, restart your browser for changes to take effect.
echo.
echo Note: Make sure Python 3 is installed and available in your PATH
echo.

pause
