@echo off
setlocal enabledelayedexpansion

rem ============================================================================
rem Python App Manager Launcher
rem This script starts the Python App Manager backend server
rem ============================================================================

title Python App Manager Server

echo.
echo ===============================================
echo    Python App Manager Server Launcher
echo ===============================================
echo.

rem Use relative paths - script should be run from project directory
set ENV_NAME=app_manager_env
set SERVER_SCRIPT=app_manager.py

rem Check if we're in the correct directory
if not exist "%SERVER_SCRIPT%" (
    echo ERROR: %SERVER_SCRIPT% not found in current directory
    echo Please run this script from the NexRift project directory
    echo Current directory: %CD%
    pause
    exit /b 1
)

echo ✓ Found %SERVER_SCRIPT% in current directory

rem Activate the conda/virtual environment
echo Activating environment: %ENV_NAME%
if exist "%ENV_NAME%\Scripts\activate.bat" (
    rem Virtual environment
    call "%ENV_NAME%\Scripts\activate.bat"
    if errorlevel 1 (
        echo ERROR: Failed to activate virtual environment
        goto :env_error
    )
    echo Virtual environment activated successfully
) else (
    rem Try conda environment
    call conda activate %ENV_NAME% 2>nul
    if errorlevel 1 (
        echo ERROR: Failed to activate conda environment
        goto :env_error
    )
    echo Conda environment activated successfully
)

rem Display environment info
echo.
echo Environment Information:
echo ------------------------
python --version 2>nul || echo Python not found in PATH
echo Environment: %ENV_NAME%
echo Project Directory: %CD%
echo Server Script: %SERVER_SCRIPT%
echo.

rem Check required packages
echo Checking required packages...
python -c "import flask, flask_cors, psutil; print('✓ All required packages found')" 2>nul
if errorlevel 1 (
    echo WARNING: Some required packages may be missing
    echo Installing required packages...
    pip install Flask Flask-CORS psutil
    if errorlevel 1 (
        echo ERROR: Failed to install required packages
        pause
        exit /b 1
    )
)

echo.
echo ===============================================
echo    Starting Python App Manager Server
echo ===============================================
echo.
echo Server will be available at:
echo   - Local:   http://localhost:8000
echo   - Network: http://[YOUR-IP]:8000
echo.
echo Dashboard can be accessed at:
echo   - http://localhost:8080/dashboard.html (if dashboard server is running)
echo.
echo Press Ctrl+C to stop the server
echo ===============================================
echo.

rem Start the server
python %SERVER_SCRIPT%

rem Check exit code
if errorlevel 1 (
    echo.
    echo ERROR: Server exited with an error
    echo Check the error messages above
    pause
    exit /b 1
)

echo.
echo Server stopped normally
pause
exit /b 0

:env_error
echo.
echo ENVIRONMENT SETUP FAILED
echo ========================
echo.
echo The script could not activate the environment '%ENV_NAME%'.
echo.
echo Please check:
echo 1. Environment exists: %ENV_NAME%
echo 2. If using conda: conda env list
echo 3. If using venv: check if %ENV_NAME%\Scripts\activate.bat exists in current directory
echo.
echo To create the environment manually:
echo.
echo For conda:
echo   conda create -n %ENV_NAME% python=3.9
echo   conda activate %ENV_NAME%
echo   pip install Flask Flask-CORS psutil
echo.
echo For virtual environment:
echo   python -m venv %ENV_NAME%
echo   %ENV_NAME%\Scripts\activate
echo   pip install Flask Flask-CORS psutil
echo.
pause
exit /b 1