#!/bin/bash

# Install generated icons into Xcode project
echo "Installing icons into Xcode project..."

# Check if icons exist
if [ ! -f "icon_512.png" ]; then
    echo "Icons not found. Running icon generation first..."
    ./generate_icon.sh
fi

# Create the app icon directory structure
ICON_DIR="ThreeBlindMice/Assets.xcassets/AppIcon.appiconset"

# Copy icons to the appropriate locations
echo "Copying icons to $ICON_DIR..."

# 16x16 (1x and 2x)
cp icon_16.png "$ICON_DIR/icon_16x16.png"
cp icon_32.png "$ICON_DIR/icon_16x16@2x.png"

# 32x32 (1x and 2x)
cp icon_32.png "$ICON_DIR/icon_32x32.png"
cp icon_64.png "$ICON_DIR/icon_32x32@2x.png" 2>/dev/null || cp icon_32.png "$ICON_DIR/icon_32x32@2x.png"

# 128x128 (1x and 2x)
cp icon_128.png "$ICON_DIR/icon_128x128.png"
cp icon_256.png "$ICON_DIR/icon_128x128@2x.png"

# 256x256 (1x and 2x)
cp icon_256.png "$ICON_DIR/icon_256x256.png"
cp icon_512.png "$ICON_DIR/icon_256x256@2x.png"

# 512x512 (1x and 2x)
cp icon_512.png "$ICON_DIR/icon_512x512.png"
cp icon_512.png "$ICON_DIR/icon_512x512@2x.png"

echo "Icons installed successfully!"
echo "You can now build the Xcode project to see the new app icon."
echo ""
echo "To build and run:"
echo "  xcodebuild -project ThreeBlindMice.xcodeproj -scheme ThreeBlindMice -configuration Debug build"
echo "  open /Users/alexanderfox/Library/Developer/Xcode/DerivedData/ThreeBlindMice-*/Build/Products/Debug/ThreeBlindMice.app"
