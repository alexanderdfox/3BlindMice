#!/bin/bash

echo "🐭 Packaging 3 Blind Mice Chrome Extension"
echo "=========================================="

# Check if extension directory exists
if [ ! -d "extension" ]; then
    echo "❌ Extension directory not found"
    exit 1
fi

# Create package directory
mkdir -p package

# Copy extension files
echo "📦 Copying extension files..."
cp -r extension/* package/

# Create package info
echo "📋 Creating package info..."
cat > package/package-info.txt << EOF
3 Blind Mice Chrome Extension
Version: 1.0.0
Platform: ChromeOS
Build Date: $(date)

Installation Instructions:
1. Open Chrome and go to chrome://extensions/
2. Enable "Developer mode"
3. Click "Load unpacked" and select this package folder
4. Grant permissions when prompted

Features:
- Multi-mouse triangulation
- Individual and Fused modes
- Real-time mouse tracking
- Keyboard shortcuts
- ChromeOS integration

Keyboard Shortcuts:
- Ctrl+Shift+M: Toggle triangulation
- Ctrl+Shift+T: Switch mode

For more information, see README.md
EOF

# Create zip package
echo "📦 Creating zip package..."
cd package
zip -r ../3BlindMice-ChromeOS-Extension.zip . -x "*.DS_Store" "*.git*"
cd ..

echo ""
echo "✅ Extension packaged successfully!"
echo "📁 Package: 3BlindMice-ChromeOS-Extension.zip"
echo ""
echo "🚀 To install:"
echo "1. Extract the zip file"
echo "2. Open Chrome → chrome://extensions/"
echo "3. Enable 'Developer mode'"
echo "4. Click 'Load unpacked' and select the extracted folder"
echo ""
echo "💡 Alternative: Load directly from extension/ folder"
echo "   chrome://extensions/ → Load unpacked → Select extension/"
echo ""
