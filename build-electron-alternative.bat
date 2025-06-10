@echo off
echo 🔨 Building NexRift Electron App (Alternative Method)
echo ================================================

:: Method 1: Use directory build first
echo 📦 Step 1: Building directory version...
npm run pack
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Directory build failed
    pause
    exit /b 1
)

echo ✅ Directory build successful
timeout /t 2 >nul

:: Method 2: Build installer from packed directory
echo 📦 Step 2: Creating installer...
electron-builder --win --publish=never
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Installer build failed
    pause
    exit /b 1
)

echo ✅ Build completed successfully!
echo 📁 Output: dist\win-unpacked\
echo 📦 Installer: dist\NexRift-1.0.0-Setup.exe

pause