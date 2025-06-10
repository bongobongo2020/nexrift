@echo off
echo 🔧 Testing NexRift Fixes
echo ========================
echo.

echo 1. Starting Python backend first...
echo    (This ensures the backend is available for testing)
echo.

rem Check if backend is already running
curl -s http://127.0.0.1:8000/api/health >nul 2>&1
if not errorlevel 1 (
    echo ✓ Backend already running on 127.0.0.1:8000
    goto :start_electron
)

rem Try to start backend
if exist "app_manager.py" (
    echo Starting backend...
    start "NexRift Backend" cmd /k "python app_manager.py"
    echo Waiting 5 seconds for backend to start...
    timeout /t 5 /nobreak >nul
) else (
    echo ⚠️ app_manager.py not found - you'll need to start it manually
)

:start_electron
echo.
echo 2. Starting Electron app...
echo    Look for these fixes:
echo    - ✓ No "serverAddress is not defined" errors
echo    - ✓ Settings button works
echo    - ✓ App start/stop buttons work
echo    - ✓ Server switching works
echo.

npm run dev