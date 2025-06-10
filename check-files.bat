@echo off
echo 📁 NexRift File Structure Check
echo ================================
echo.

echo Current directory: %CD%
echo.

echo Checking required files:
echo.

if exist "package.json" (
    echo ✓ package.json
) else (
    echo ❌ package.json NOT FOUND
    echo You need to run this from the nexrift project folder!
    goto :end
)

if exist "src\main.js" (
    echo ✓ src\main.js
) else (
    echo ❌ src\main.js NOT FOUND
)

if exist "src\preload.js" (
    echo ✓ src\preload.js
) else (
    echo ❌ src\preload.js NOT FOUND
)

if exist "dashboard" (
    echo ✓ dashboard folder exists
    if exist "dashboard\dashboard.html" (
        echo ✓ dashboard\dashboard.html
        echo   File size: 
        for %%I in ("dashboard\dashboard.html") do echo   %%~zI bytes
    ) else (
        echo ❌ dashboard\dashboard.html NOT FOUND
        echo Contents of dashboard folder:
        dir dashboard
    )
) else (
    echo ❌ dashboard folder NOT FOUND
    echo Available folders:
    dir /AD
)

if exist "app_manager.py" (
    echo ✓ app_manager.py
) else (
    echo ❌ app_manager.py NOT FOUND
)

if exist "node_modules" (
    echo ✓ node_modules folder exists
) else (
    echo ❌ node_modules NOT FOUND - run 'npm install'
)

echo.
echo File paths that Electron will try:
echo 1. %CD%\dashboard\dashboard.html
echo 2. %CD%\src\..\dashboard\dashboard.html
echo 3. Alternative paths in subdirectories

echo.
echo If dashboard.html exists but Electron can't find it,
echo the issue is likely a Windows path separator problem.

:end
echo.
pause