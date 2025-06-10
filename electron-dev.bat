@echo off
echo Starting NexRift in Electron Development Mode
echo.

rem Check if Node.js is installed
node --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Node.js is not installed or not in PATH
    echo Please install Node.js from https://nodejs.org/
    pause
    exit /b 1
)

rem Check if dependencies are installed
if not exist "node_modules" (
    echo Installing Electron dependencies...
    npm install
    if errorlevel 1 (
        echo ERROR: Failed to install dependencies
        pause
        exit /b 1
    )
)

echo.
echo Checking if Python backend is running...
curl -s http://127.0.0.1:8000/api/health >nul 2>&1
if errorlevel 1 (
    echo Backend not running on 127.0.0.1:8000, trying 192.168.1.227:8000...
    curl -s http://192.168.1.227:8000/api/health >nul 2>&1
    if errorlevel 1 (
        echo.
        echo WARNING: No backend server detected!
        echo Please start your Python backend first:
        echo   1. Run: python app_manager.py
        echo   2. Or use: start_app_manager.bat
        echo.
        echo Starting Electron anyway (will show connection error)...
        timeout /t 3 /nobreak >nul
    ) else (
        echo ✓ Backend found at 192.168.1.227:8000
    )
) else (
    echo ✓ Backend found at 127.0.0.1:8000
)

echo.
echo Starting Electron app in development mode...
echo.

npm run dev