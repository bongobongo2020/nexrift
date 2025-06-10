@echo off
echo Building NexRift Electron App for Windows
echo.

rem Check if Node.js is installed
node --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Node.js is not installed or not in PATH
    echo Please install Node.js from https://nodejs.org/
    pause
    exit /b 1
)

rem Install dependencies if needed
if not exist "node_modules" (
    echo Installing dependencies...
    npm install
    if errorlevel 1 (
        echo ERROR: Failed to install dependencies
        pause
        exit /b 1
    )
)

echo.
echo Building Windows installer...
echo This may take a few minutes...
echo.

npm run build-win

if errorlevel 1 (
    echo.
    echo ERROR: Build failed
    pause
    exit /b 1
) else (
    echo.
    echo SUCCESS: Build completed!
    echo.
    echo Installer created in: dist/
    echo Look for: NexRift-1.0.0-Setup.exe
    echo.
    pause
)