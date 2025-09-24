#!/bin/bash

echo "🐭 Building 3 Blind Mice for Linux"
echo "=================================="

# Check if running on Linux
if [[ "$OSTYPE" != "linux-gnu"* ]]; then
    echo "❌ This script is for Linux only"
    exit 1
fi

# Check if CMake is available
if ! command -v cmake &> /dev/null; then
    echo "❌ CMake not found"
    echo "Please install CMake:"
    echo "  Ubuntu/Debian: sudo apt install cmake"
    echo "  Fedora/RHEL: sudo dnf install cmake"
    exit 1
fi

# Swift is optional now; if present we'll build the Swift executable (requires swiftc)
HAS_SWIFT=1
if ! command -v swiftc &> /dev/null; then
    HAS_SWIFT=0
    echo "⚠️  Swift compiler (swiftc) not found - will build C library only"
fi

# Check if required development packages are installed
echo "📋 Checking dependencies..."

# Check for X11 development libraries
if ! pkg-config --exists x11; then
    echo "❌ X11 development libraries not found"
    echo "Please install:"
    echo "  Ubuntu/Debian: sudo apt install libx11-dev libxtst-dev"
    echo "  Fedora/RHEL: sudo dnf install libX11-devel libXtst-devel"
    exit 1
fi

# Check for evdev development libraries
if ! pkg-config --exists libevdev; then
    echo "❌ libevdev development libraries not found"
    echo "Please install:"
    echo "  Ubuntu/Debian: sudo apt install libevdev-dev"
    echo "  Fedora/RHEL: sudo dnf install libevdev-devel"
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
echo "✅ C library built successfully!"

# Build Swift executable if Swift is available
if [ "$HAS_SWIFT" -eq 1 ]; then
  echo "📦 Building Swift executable..."
  SWIFT_SOURCES=(
    ../src/swift/main.swift
    ../src/swift/MultiMouseManager.swift
    ../src/swift/DisplayManager.swift
  )

  mkdir -p bin
  # Ensure lib path at runtime
  export LD_LIBRARY_PATH="${PWD}/bin:${LD_LIBRARY_PATH}"

  swiftc -O \
    -L"${PWD}/bin" -lthreeblindmice \
    -Xlinker -rpath -Xlinker '$ORIGIN' \
    -o bin/ThreeBlindMice "${SWIFT_SOURCES[@]}"

  if [ $? -ne 0 ]; then
    echo "❌ Swift build failed"
    exit 1
  fi

  echo ""
  echo "✅ Build completed successfully!"
  echo "📁 Output: build/bin/ThreeBlindMice"
  echo ""
  echo "🚀 To run: ./build/bin/ThreeBlindMice"
  echo ""
  echo "💡 For proper permissions, run:"
  echo "   sudo ./install.sh"
  echo ""
else
  echo "ℹ️  Skipped Swift build. Only libthreeblindmice.so was produced in build/bin."
fi
