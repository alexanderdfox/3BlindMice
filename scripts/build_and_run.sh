#!/bin/bash

# ThreeBlindMice Build and Run Script
# This script builds the Release version and launches the application

echo "🔨 Building ThreeBlindMice for Release..."

# Build the Release version
xcodebuild -project ThreeBlindMice.xcodeproj -scheme ThreeBlindMice -configuration Release build

# Check if build was successful
if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    
    # Path to the Release build
    APP_PATH="/Users/alexanderfox/Library/Developer/Xcode/DerivedData/ThreeBlindMice-guhuhjalhmkplgakukebejhurpqk/Build/Products/Release/ThreeBlindMice.app"
    
    echo "🚀 Launching ThreeBlindMice..."
    echo "📍 App location: $APP_PATH"
    echo "🎯 Features: Enhanced multi-mouse triangulation with weighted averaging"
    echo "🐭 Look for the mouse emoji in your menu bar!"
    
    # Launch the application
    open "$APP_PATH"
    
    echo "✅ ThreeBlindMice launched successfully!"
    echo "💡 Click the 🐭 icon in your menu bar to control the application"
else
    echo "❌ Build failed! Please check the error messages above."
    exit 1
fi
