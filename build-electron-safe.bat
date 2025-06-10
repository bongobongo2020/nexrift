@echo off
echo 🔨 Building NexRift Electron App (Safe Mode)
echo =====================================

:: Stop any running processes that might lock files
echo 🛑 Stopping running processes...
taskkill /F /IM python.exe >nul 2>&1
taskkill /F /IM node.exe >nul 2>&1
taskkill /F /IM electron.exe >nul 2>&1

:: Wait a moment for cleanup
timeout /t 2 >nul

:: Clean build directory
echo 🧹 Cleaning build directory...
if exist "dist" rmdir /s /q "dist" >nul 2>&1
if exist "node_modules\.cache" rmdir /s /q "node_modules\.cache" >nul 2>&1

:: Wait again
timeout /t 1 >nul

:: Create backup of files that might be locked
echo 📁 Creating temporary backups...
copy "requirements.txt" "requirements.txt.tmp" >nul 2>&1
copy "app_manager.py" "app_manager.py.tmp" >nul 2>&1

:: Build with retries
echo 🚀 Building Electron app...
set /a attempts=0
:build_retry
set /a attempts+=1
echo Attempt %attempts%/3...

npm run build
if %ERRORLEVEL% EQU 0 (
    echo ✅ Build successful!
    goto cleanup
)

if %attempts% LSS 3 (
    echo ⚠️ Build failed, retrying in 3 seconds...
    timeout /t 3 >nul
    
    :: Clean and retry
    if exist "dist" rmdir /s /q "dist" >nul 2>&1
    timeout /t 1 >nul
    goto build_retry
)

echo ❌ Build failed after 3 attempts
goto cleanup

:cleanup
echo 🧹 Cleaning up temporary files...
del "requirements.txt.tmp" >nul 2>&1
del "app_manager.py.tmp" >nul 2>&1

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ✅ Build completed successfully!
    echo 📁 Output: dist\win-unpacked\
    echo 📦 Installer: dist\NexRift-1.0.0-Setup.exe
    echo.
    echo Press any key to open the output folder...
    pause >nul
    explorer "dist\"
) else (
    echo.
    echo ❌ Build failed. Check the error messages above.
    echo.
    pause
)