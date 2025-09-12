@echo off
echo 🐭 Running 3 Blind Mice for Windows
echo ===================================

REM Check if executable exists
if not exist "build\bin\Release\ThreeBlindMice.exe" (
    echo ❌ Executable not found
    echo Please run build.bat first
    pause
    exit /b 1
)

echo ✅ Found executable: build\bin\Release\ThreeBlindMice.exe
echo.

REM Check if running as administrator
net session >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ⚠️  Not running as administrator
    echo Some features may not work properly
    echo For full functionality, run as administrator
    echo.
)

echo 🚀 Starting 3 Blind Mice...
echo Press Ctrl+C to stop
echo.

REM Run the application
build\bin\Release\ThreeBlindMice.exe

echo.
echo 👋 Application stopped
pause
