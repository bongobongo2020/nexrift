@echo off
echo 🧪 NexRift Electron Test
echo ========================
echo This will help diagnose why Electron shows a blank screen
echo.

rem Install dependencies if needed
if not exist "node_modules" (
    echo Installing dependencies first...
    npm install
    if errorlevel 1 (
        echo ❌ Failed to install dependencies
        pause
        exit /b 1
    )
)

echo Starting Electron test mode...
echo.
echo What you should see:
echo 1. Electron window opens
echo 2. Developer Tools open automatically
echo 3. Test page with status checks
echo.
echo If you see a blank screen, check the Console tab in DevTools for errors!
echo.

npm run test