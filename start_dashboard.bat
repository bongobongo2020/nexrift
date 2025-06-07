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

rem Set the path to your dashboard directory
set DASHBOARD_DIR=E:\projects\pythonappmanager\dashboard
set DASHBOARD_SCRIPT=serve_dashboard.py
set DASHBOARD_HTML=dashboard.html

rem Change to dashboard directory
echo Changing to dashboard directory: %DASHBOARD_DIR%
cd /d "%DASHBOARD_DIR%"
if errorlevel 1 (
    echo ERROR: Could not change to dashboard directory: %DASHBOARD_DIR%
    echo Please check if the path exists and update the DASHBOARD_DIR variable in this script.
    pause
    exit /b 1
)

rem Check if required files exist
if not exist "%DASHBOARD_SCRIPT%" (
    echo ERROR: %DASHBOARD_SCRIPT% not found in %DASHBOARD_DIR%
    echo Please make sure the serve_dashboard.py file is in the correct location.
    pause
    exit /b 1
)

if not exist "%DASHBOARD_HTML%" (
    echo ERROR: %DASHBOARD_HTML% not found in %DASHBOARD_DIR%
    echo Please make sure the dashboard.html file is in the correct location.
    pause
    exit /b 1
)

rem Display info
echo.
echo Dashboard Information:
echo ----------------------
python --version 2>nul || echo Python not found in PATH
echo Dashboard Directory: %DASHBOARD_DIR%
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
echo   - Network: http://192.168.1.227:8080/dashboard.html
echo.
echo Make sure the App Manager backend is running at:
echo   - http://192.168.1.227:5000
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