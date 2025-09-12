#!/bin/bash

echo "🐭 Running 3 Blind Mice for ChromeOS"
echo "===================================="

# Check if executable exists
if [ ! -f "build/bin/ThreeBlindMiceChromeOS" ]; then
    echo "❌ Executable not found"
    echo "Please run ./build.sh first"
    exit 1
fi

echo "✅ Found executable: build/bin/ThreeBlindMiceChromeOS"
echo ""

# Check if running in Crostini
if ! grep -q "CHROMEOS_RELEASE_NAME" /etc/lsb-release 2>/dev/null; then
    echo "⚠️  Not running in Crostini environment"
    echo "Some features may not work properly"
    echo "For full functionality, enable Crostini: Settings → Linux (Beta)"
    echo ""
fi

# Check if running with proper permissions
if ! groups | grep -q input; then
    echo "⚠️  User not in input group"
    echo "Some features may not work properly"
    echo "For full functionality, run: sudo ./install.sh"
    echo ""
fi

echo "🚀 Starting 3 Blind Mice..."
echo "Press Ctrl+C to stop"
echo ""

# Run the application
./build/bin/ThreeBlindMiceChromeOS

echo ""
echo "👋 Application stopped"
