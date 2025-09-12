@echo off
echo 🐭 Building 3 Blind Mice for Windows
echo ====================================

REM Check if Visual Studio is available
where cl >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Visual Studio not found in PATH
    echo Please run this from a Developer Command Prompt
    echo Or run: "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat"
    pause
    exit /b 1
)

REM Check if CMake is available
where cmake >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ❌ CMake not found
    echo Please install CMake and add it to PATH
    pause
    exit /b 1
)

REM Check if Swift is available
where swift >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Swift not found
    echo Please install Swift for Windows and add it to PATH
    pause
    exit /b 1
)

echo ✅ All required tools found
echo.

REM Create build directory
if not exist build mkdir build

REM Configure with CMake
echo 📋 Configuring project...
cmake -B build -S . -G "Visual Studio 17 2022" -A x64
if %ERRORLEVEL% NEQ 0 (
    echo ❌ CMake configuration failed
    pause
    exit /b 1
)

REM Build the project
echo 🔨 Building project...
cmake --build build --config Release
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Build failed
    pause
    exit /b 1
)

echo.
echo ✅ Build completed successfully!
echo 📁 Output: build\bin\Release\ThreeBlindMice.exe
echo.
echo 🚀 To run: build\bin\Release\ThreeBlindMice.exe
echo.
pause
