@echo off
setlocal enabledelayedexpansion

rem ============================================================================
rem Python App Manager - Master Launcher
rem This script provides options to start the backend, dashboard, or both
rem ============================================================================

title Python App Manager - Master Launcher

:menu
cls
echo.
echo ===============================================
echo     Python App Manager - Master Launcher
echo ===============================================
echo.
echo Select an option:
echo.
echo [1] Start Backend Server Only
echo [2] Start Dashboard Only  
echo [3] Start Both (Backend + Dashboard)
echo [4] Open Dashboard in Browser
echo [5] Check Server Status
echo [6] Exit
echo.
echo ===============================================

set /p choice="Enter your choice (1-6): "

if "%choice%"=="1" goto start_backend
if "%choice%"=="2" goto start_dashboard
if "%choice%"=="3" goto start_both
if "%choice%"=="4" goto open_dashboard
if "%choice%"=="5" goto check_status
if "%choice%"=="6" goto exit
goto invalid_choice

:start_backend
echo.
echo Starting Backend Server...
echo ===============================================
start "App Manager Backend" cmd /k "cd /d E:\projects\nexrift && start_app_manager.bat"
echo Backend server started in a new window
echo.
pause
goto menu

:start_dashboard
echo.
echo Starting Dashboard...
echo ===============================================
start "App Manager Dashboard" cmd /k "cd /d E:\projects\nexrift\dashboard && start_dashboard.bat"
echo Dashboard started in a new window
echo.
pause
goto menu

:start_both
echo.
echo Starting Backend Server...
echo ===============================================
start "App Manager Backend" cmd /k "cd /d E:\projects\nexrift && start_app_manager.bat"
timeout /t 3 /nobreak >nul
echo.
echo Starting Dashboard...
echo ===============================================
start "App Manager Dashboard" cmd /k "cd /d E:\projects\nexrift\dashboard && start_dashboard.bat"
echo.
echo Both services started in separate windows
echo   - Backend: http://192.168.1.227:5000
echo   - Dashboard: http://localhost:8080/dashboard.html
echo.
pause
goto menu

:open_dashboard
echo.
echo Opening dashboard in browser...
start http://localhost:8080/dashboard.html
timeout /t 2 /nobreak >nul
goto menu

:check_status
echo.
echo Checking Server Status...
echo ===============================================
echo.
echo Testing Backend Server (192.168.1.227:5000)...
curl -s http://192.168.1.227:5000/api/health >nul 2>&1
if errorlevel 1 (
    echo ❌ Backend server is NOT running
) else (
    echo ✅ Backend server is running
)

echo.
echo Testing Dashboard Server (localhost:8080)...
curl -s http://localhost:8080/dashboard.html >nul 2>&1
if errorlevel 1 (
    echo ❌ Dashboard server is NOT running
) else (
    echo ✅ Dashboard server is running
)

echo.
echo Testing Application Status:
echo ---------------------------
curl -s http://192.168.1.227:5000/api/apps 2>nul | findstr "name" >nul 2>&1
if errorlevel 1 (
    echo ❌ Cannot retrieve app status (backend may be down)
) else (
    echo ✅ Apps API is responding
    echo.
    echo Current app status:
    curl -s http://192.168.1.227:5000/api/apps 2>nul
)

echo.
pause
goto menu

:invalid_choice
echo.
echo Invalid choice. Please enter a number between 1-6.
timeout /t 2 /nobreak >nul
goto menu

:exit
echo.
echo Goodbye!
timeout /t 1 /nobreak >nul
exit /b 0