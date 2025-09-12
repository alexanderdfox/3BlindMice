#!/bin/bash

echo "🐭 Running 3 Blind Mice for Linux"
echo "================================="

# Check if executable exists
if [ ! -f "build/bin/ThreeBlindMice" ]; then
    echo "❌ Executable not found"
    echo "Please run ./build.sh first"
    exit 1
fi

echo "✅ Found executable: build/bin/ThreeBlindMice"
echo ""

# Check if running with proper permissions
if ! groups | grep -q input; then
    echo "⚠️  User not in input group"
    echo "Some features may not work properly"
    echo "For full functionality, run: sudo ./install.sh"
    echo ""
fi

# Check if udev rules are installed
if [ ! -f "/etc/udev/rules.d/99-threeblindmice.rules" ]; then
    echo "⚠️  udev rules not installed"
    echo "For proper device access, run: sudo ./install.sh"
    echo ""
fi

echo "🚀 Starting 3 Blind Mice..."
echo "Press Ctrl+C to stop"
echo ""

# Run the application
./build/bin/ThreeBlindMice

echo ""
echo "👋 Application stopped"
