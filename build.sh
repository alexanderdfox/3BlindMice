#!/bin/bash

echo "Building 3 Blind Mice..."
echo "========================"

# Clean previous build
rm -rf .build

# Build the application
swift build -c release

if [ $? -eq 0 ]; then
    echo "Build successful!"
    echo "Running 3 Blind Mice..."
    echo "Look for the mouse icon in your menu bar (system tray)"
    echo "Click it to open the control panel"
    echo ""
    echo "Press Ctrl+C to stop the application"
    echo "========================"
    
    # Run the application
    .build/release/ThreeBlindMice
else
    echo "Build failed!"
    exit 1
fi
