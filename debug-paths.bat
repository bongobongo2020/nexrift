@echo off
echo 🔍 NexRift Path Debug Tool
echo ==========================
echo.

echo 1. First, let's check your file structure:
call check-files.bat

echo.
echo 2. Now starting Electron with detailed path logging...
echo    Watch the console output carefully!
echo.

echo 3. When Electron opens:
echo    - Look for path messages in the console
echo    - Check if DevTools show any errors
echo    - See if the dashboard loads or shows an error page
echo.

echo Starting in 3 seconds...
timeout /t 3 /nobreak >nul

npm run dev