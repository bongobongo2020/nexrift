@echo off
echo NexRift Electron Debug Script
echo ================================
echo.

echo 1. Checking Node.js installation...
node --version
if errorlevel 1 (
    echo ❌ Node.js not found
    goto :end
) else (
    echo ✓ Node.js found
)

echo.
echo 2. Checking project structure...
if exist "package.json" (
    echo ✓ package.json found
) else (
    echo ❌ package.json not found
    echo You need to run this from the nexrift directory
    goto :end
)

if exist "dashboard\dashboard.html" (
    echo ✓ dashboard.html found
) else (
    echo ❌ dashboard/dashboard.html not found
    echo This is likely the problem!
    goto :end
)

if exist "src\main.js" (
    echo ✓ main.js found
) else (
    echo ❌ src/main.js not found
    goto :end
)

echo.
echo 3. Checking if dependencies are installed...
if exist "node_modules" (
    echo ✓ node_modules exists
) else (
    echo ❌ node_modules not found, installing...
    npm install
    if errorlevel 1 (
        echo ❌ npm install failed
        goto :end
    )
)

echo.
echo 4. Checking Python backend...
echo Trying to connect to backend servers...

curl -s http://127.0.0.1:8000/api/health >nul 2>&1
if not errorlevel 1 (
    echo ✓ Backend running on 127.0.0.1:8000
    goto :start_electron
)

curl -s http://192.168.1.227:8000/api/health >nul 2>&1
if not errorlevel 1 (
    echo ✓ Backend running on 192.168.1.227:8000
    goto :start_electron
)

echo ❌ No backend found on either port
echo.
echo To fix this, start your Python backend:
echo   1. Open new command prompt
echo   2. Navigate to this folder
echo   3. Run: python app_manager.py
echo   4. Wait for "Running on http://0.0.0.0:8000"
echo   5. Then retry this script
echo.
echo Starting Electron anyway for debugging...

:start_electron
echo.
echo 5. Starting Electron with verbose logging...
echo Look for error messages in the console!
echo.
set DEBUG=*
npm run dev

:end
echo.
pause