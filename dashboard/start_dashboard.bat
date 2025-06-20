@echo off
setlocal enabledelayedexpansion

rem ============================================================================
rem Python App Manager Dashboard Launcher
rem This script starts the dashboard web server
rem ============================================================================

title Python App Manager Dashboard

echo.
echo ===============================================
echo    Python App Manager Dashboard Launcher
echo ===============================================
echo.

rem Use relative paths - script should be run from dashboard directory
set DASHBOARD_SCRIPT=serve_dashboard.py
set DASHBOARD_HTML=dashboard.html

rem Check if we're in the correct directory (dashboard folder)
if not exist "%DASHBOARD_SCRIPT%" (
    echo ERROR: %DASHBOARD_SCRIPT% not found in current directory
    echo Please run this script from the dashboard directory
    echo Current directory: %CD%
    pause
    exit /b 1
)

rem Check if required files exist
if not exist "%DASHBOARD_HTML%" (
    echo ERROR: %DASHBOARD_HTML% not found in current directory
    echo Please make sure the dashboard.html file is in the dashboard directory.
    pause
    exit /b 1
)

echo ✓ Found %DASHBOARD_SCRIPT% and %DASHBOARD_HTML% in current directory

rem Display info
echo.
echo Dashboard Information:
echo ----------------------
python --version 2>nul || echo Python not found in PATH
echo Dashboard Directory: %CD%
echo Dashboard Script: %DASHBOARD_SCRIPT%
echo Dashboard HTML: %DASHBOARD_HTML%
echo.

echo.
echo ===============================================
echo    Starting Dashboard Web Server
echo ===============================================
echo.
echo Dashboard will be available at:
echo   - Local:   http://localhost:8080/dashboard.html
echo   - Network: http://[YOUR-IP]:8080/dashboard.html
echo.
echo Make sure the App Manager backend is running at:
echo   - http://localhost:8000 (or your configured server)
echo.
echo The dashboard will open automatically in your browser
echo Press Ctrl+C to stop the dashboard server
echo ===============================================
echo.

rem Start the dashboard server
python %DASHBOARD_SCRIPT%

rem Check exit code
if errorlevel 1 (
    echo.
    echo ERROR: Dashboard server exited with an error
    echo Check the error messages above
    pause
    exit /b 1
)

echo.
echo Dashboard server stopped normally
pause
exit /b 0