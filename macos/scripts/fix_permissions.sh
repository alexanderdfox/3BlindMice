#!/bin/bash

# Fix HID Permissions for 3 Blind Mice
echo "🔧 Fixing HID Permissions for 3 Blind Mice"
echo "=========================================="

# Find the application
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "ThreeBlindMice.app" -type d | head -1)

if [ -z "$APP_PATH" ]; then
    echo "❌ ThreeBlindMice.app not found. Please build the project first."
    echo "   Run: xcodebuild -project ThreeBlindMice.xcodeproj -scheme ThreeBlindMice -configuration Debug build"
    exit 1
fi

echo "✅ Found application at: $APP_PATH"
echo ""

echo "📋 Manual Steps Required:"
echo "=========================="
echo ""
echo "1. Open System Preferences (or System Settings)"
echo "2. Go to Security & Privacy (or Privacy & Security)"
echo "3. Click on the 'Privacy' tab"
echo "4. Select 'Input Monitoring' from the left sidebar"
echo "5. Click the lock icon and enter your password"
echo "6. Click the '+' button"
echo "7. Navigate to: $APP_PATH"
echo "8. Select ThreeBlindMice.app and click 'Open'"
echo "9. Check the box next to ThreeBlindMice.app"
echo "10. Restart the application"
echo ""

echo "🚀 Quick Commands:"
echo "=================="
echo ""
echo "# Open System Preferences directly to Privacy settings"
echo "open 'x-apple.systempreferences:com.apple.preference.security?Privacy_InputMonitoring'"
echo ""
echo "# Open the application"
echo "open '$APP_PATH'"
echo ""

echo "🔍 Alternative Solutions:"
echo "========================"
echo ""
echo "If the above doesn't work, try these alternatives:"
echo ""
echo "1. Add Terminal.app to Input Monitoring (for command-line version)"
echo "2. Add Accessibility permissions instead"
echo "3. Run the application from Xcode directly"
echo ""

echo "📝 Troubleshooting:"
echo "==================="
echo ""
echo "If you still get TCC errors:"
echo "1. Make sure the app is properly code signed"
echo "2. Try running from Finder instead of Xcode"
echo "3. Check if macOS version has stricter policies"
echo "4. Consider using the Xcode version for development"
echo ""

echo "🎯 Ready to proceed!"
echo "===================="
echo ""
echo "The application path is: $APP_PATH"
echo ""
echo "Would you like me to:"
echo "1. Open System Preferences to Privacy settings"
echo "2. Open the application directly"
echo "3. Show more debugging information"
echo ""
read -p "Enter your choice (1-3): " choice

case $choice in
    1)
        echo "Opening System Preferences..."
        open 'x-apple.systempreferences:com.apple.preference.security?Privacy_InputMonitoring'
        ;;
    2)
        echo "Opening ThreeBlindMice.app..."
        open "$APP_PATH"
        ;;
    3)
        echo "Debugging information:"
        echo "======================"
        echo ""
        echo "# Check if app is code signed:"
        codesign -dv "$APP_PATH" 2>/dev/null || echo "App not code signed"
        echo ""
        echo "# Check app entitlements:"
        codesign -d --entitlements :- "$APP_PATH" 2>/dev/null || echo "No entitlements found"
        echo ""
        echo "# Check running processes:"
        ps aux | grep ThreeBlindMice | grep -v grep || echo "No ThreeBlindMice processes running"
        ;;
    *)
        echo "Invalid choice. Please run the script again."
        ;;
esac

echo ""
echo "✅ Permission fix script completed!"
echo "   Follow the manual steps above to grant Input Monitoring permissions."
