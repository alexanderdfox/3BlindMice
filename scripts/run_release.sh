#!/bin/bash

# ThreeBlindMice Release Launcher
# This script launches the Release build of the ThreeBlindMice application

echo "🚀 Launching ThreeBlindMice (Release Build)..."

# Path to the Release build
APP_PATH="/Users/alexanderfox/Library/Developer/Xcode/DerivedData/ThreeBlindMice-guhuhjalhmkplgakukebejhurpqk/Build/Products/Release/ThreeBlindMice.app"

# Check if the app exists
if [ ! -d "$APP_PATH" ]; then
    echo "❌ Error: Release build not found at $APP_PATH"
    echo "Please run: xcodebuild -project ThreeBlindMice.xcodeproj -scheme ThreeBlindMice -configuration Release build"
    exit 1
fi

# Launch the application
echo "📍 App location: $APP_PATH"
echo "🎯 Features: Enhanced multi-mouse triangulation with weighted averaging"
echo "🐭 Look for the mouse emoji in your menu bar!"

open "$APP_PATH"

echo "✅ ThreeBlindMice launched successfully!"
echo "💡 Click the 🐭 icon in your menu bar to control the application"
