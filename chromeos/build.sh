#!/bin/bash

echo "🐭 Building 3 Blind Mice for ChromeOS"
echo "===================================="

# Check if running in Crostini
if ! grep -q "CHROMEOS_RELEASE_NAME" /etc/lsb-release 2>/dev/null; then
    echo "❌ This script is for ChromeOS/Crostini only"
    echo "For Chrome Extension, use: ./package.sh"
    exit 1
fi

# Check if CMake is available
if ! command -v cmake &> /dev/null; then
    echo "❌ CMake not found"
    echo "Please install CMake:"
    echo "  sudo apt update && sudo apt install cmake"
    exit 1
fi

# Check if Swift is available
if ! command -v swift &> /dev/null; then
    echo "❌ Swift not found"
    echo "Please install Swift for Linux:"
    echo "  https://swift.org/download/"
    exit 1
fi

# Check if required development packages are installed
echo "📋 Checking dependencies..."

# Check for X11 development libraries
if ! pkg-config --exists x11; then
    echo "❌ X11 development libraries not found"
    echo "Please install:"
    echo "  sudo apt install libx11-dev libxtst-dev"
    exit 1
fi

# Check for evdev development libraries
if ! pkg-config --exists libevdev; then
    echo "❌ libevdev development libraries not found"
    echo "Please install:"
    echo "  sudo apt install libevdev-dev"
    exit 1
fi

echo "✅ All dependencies found"
echo ""

# Create build directory
mkdir -p build
cd build

# Configure with CMake
echo "📋 Configuring project..."
cmake -DCMAKE_BUILD_TYPE=Release ..
if [ $? -ne 0 ]; then
    echo "❌ CMake configuration failed"
    exit 1
fi

# Build the project
echo "🔨 Building project..."
make -j$(nproc)
if [ $? -ne 0 ]; then
    echo "❌ Build failed"
    exit 1
fi

echo ""
echo "✅ Build completed successfully!"
echo "📁 Output: build/bin/ThreeBlindMiceChromeOS"
echo ""
echo "🚀 To run: ./build/bin/ThreeBlindMiceChromeOS"
echo ""
echo "💡 For proper permissions, run:"
echo "   sudo ./install.sh"
echo ""
echo "🌐 Alternative: Use Chrome Extension version"
echo "   Run: ./package.sh"
echo ""
