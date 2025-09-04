#!/bin/bash

echo "🔍 Testing HID Permissions for 3 Blind Mice"
echo "==========================================="

# Check if app is running
if pgrep -f "ThreeBlindMice" > /dev/null; then
    echo "✅ ThreeBlindMice app is running"
    echo "   Process ID: $(pgrep -f "ThreeBlindMice")"
else
    echo "❌ ThreeBlindMice app is not running"
fi

echo ""

# Check app location
RELEASE_APP="/Users/alexanderfox/Library/Developer/Xcode/DerivedData/ThreeBlindMice-guhuhjalhmkplgakukebejhurpqk/Build/Products/Release/ThreeBlindMice.app"
DEBUG_APP="/Users/alexanderfox/Library/Developer/Xcode/DerivedData/ThreeBlindMice-guhuhjalhmkplgakukebejhurpqk/Build/Products/Debug/ThreeBlindMice.app"

if [ -d "$RELEASE_APP" ]; then
    echo "✅ Release app found: $RELEASE_APP"
    APP_PATH="$RELEASE_APP"
elif [ -d "$DEBUG_APP" ]; then
    echo "✅ Debug app found: $DEBUG_APP"
    APP_PATH="$DEBUG_APP"
else
    echo "❌ No ThreeBlindMice.app found"
    exit 1
fi

echo ""

# Check code signing
echo "🔐 Code Signing Status:"
codesign -dv "$APP_PATH" 2>/dev/null | grep -E "(Signature|Identifier)" || echo "❌ Code signing check failed"

echo ""

# Check entitlements
echo "📋 Entitlements:"
codesign -d --entitlements :- "$APP_PATH" 2>/dev/null | grep -A 10 "entitlements" || echo "❌ Entitlements check failed"

echo ""

# Check if app appears in menu bar
echo "🎯 Menu Bar Status:"
if pgrep -f "ThreeBlindMice" > /dev/null; then
    echo "✅ App should be visible in menu bar (look for 🐭 icon)"
    echo "   Click the mouse emoji to open the control panel"
else
    echo "❌ App not running - check for permission prompts"
fi

echo ""

# Test HID access
echo "🖱️  HID Access Test:"
echo "   Move your mouse around to test if the app detects input"
echo "   If you have multiple mice, try moving them simultaneously"
echo "   The app should show triangulation in action"

echo ""

# Instructions
echo "📋 Next Steps:"
echo "=============="
echo ""
echo "1. Look for the 🐭 icon in your menu bar"
echo "2. Click the icon to open the control panel"
echo "3. Click 'Start Triangulation' to begin"
echo "4. Move your mice to see the enhanced triangulation"
echo "5. Check the status in the control panel"
echo ""

echo "🔧 If the app isn't working:"
echo "============================"
echo ""
echo "1. Check System Preferences → Security & Privacy → Privacy → Input Monitoring"
echo "2. Make sure ThreeBlindMice.app is listed and checked"
echo "3. Try running from Finder instead of terminal"
echo "4. Check Console.app for any error messages"
echo ""

echo "✅ Test completed!"
