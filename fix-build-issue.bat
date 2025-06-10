@echo off
echo 🔧 NexRift Build Issue Fixer
echo ===========================

echo 🛑 Step 1: Stopping all related processes...
taskkill /F /IM python.exe >nul 2>&1
taskkill /F /IM node.exe >nul 2>&1  
taskkill /F /IM electron.exe >nul 2>&1
taskkill /F /IM Code.exe >nul 2>&1

echo ⏳ Waiting for processes to close...
timeout /t 3 >nul

echo 🧹 Step 2: Cleaning build artifacts...
if exist "dist" (
    echo Removing dist folder...
    rmdir /s /q "dist" >nul 2>&1
)

if exist "node_modules\.cache" (
    echo Removing node cache...
    rmdir /s /q "node_modules\.cache" >nul 2>&1
)

echo 📁 Step 3: Checking file locks...
echo Checking if requirements.txt is accessible...
copy "requirements.txt" "test-lock.tmp" >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo ✅ requirements.txt is accessible
    del "test-lock.tmp" >nul 2>&1
) else (
    echo ❌ requirements.txt is still locked
    echo Try closing your text editor or IDE and run this script again
    pause
    exit /b 1
)

echo Checking if app_manager.py is accessible...
copy "app_manager.py" "test-lock2.tmp" >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo ✅ app_manager.py is accessible  
    del "test-lock2.tmp" >nul 2>&1
) else (
    echo ❌ app_manager.py is still locked
    echo Try closing your text editor or IDE and run this script again
    pause
    exit /b 1
)

echo 🚀 Step 4: Ready to build!
echo All files are accessible. You can now try:
echo.
echo   Option 1 (Safe): build-electron-safe.bat
echo   Option 2 (Alt):  build-electron-alternative.bat  
echo   Option 3 (NPM):  npm run build-safe
echo.
echo Press any key to try building with safe method...
pause >nul

call build-electron-safe.bat