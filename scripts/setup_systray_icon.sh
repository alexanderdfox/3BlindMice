#!/bin/bash

# Script to setup system tray icon for macOS app
# This script copies icon.png to the macOS project and provides instructions

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}🍎 Setting up System Tray Icon${NC}"
echo "=================================="

# Check if we're in the right directory
if [[ ! -f "scripts/icon.png" ]]; then
    echo -e "${RED}❌ Error: scripts/icon.png not found${NC}"
    echo "Please run this script from the project root directory"
    exit 1
fi

# Copy icon.png to the macOS project directory
echo -e "${BLUE}📁 Copying icon.png to macOS project...${NC}"
cp scripts/icon.png macos/ThreeBlindMice/icon.png
echo -e "  ✅ Copied icon.png to macos/ThreeBlindMice/"

# Test the project builds
echo -e "${BLUE}🧪 Testing Xcode project...${NC}"
cd macos

if xcodebuild -project ThreeBlindMice.xcodeproj -scheme ThreeBlindMice -configuration Debug -quiet build; then
    echo -e "  ✅ Xcode project builds successfully"
else
    echo -e "  ${RED}❌ Xcode project build failed${NC}"
    exit 1
fi

cd ..

echo ""
echo -e "${GREEN}🎯 System Tray Icon Setup Complete!${NC}"
echo ""
echo -e "${BLUE}📋 What was done:${NC}"
echo -e "  • icon.png copied to macos/ThreeBlindMice/"
echo -e "  • Swift code updated to load icon.png for system tray"
echo -e "  • Project builds successfully"
echo ""
echo -e "${YELLOW}⚠️  Manual Step Required:${NC}"
echo -e "  To complete the setup, you need to add icon.png to the Xcode project:"
echo ""
echo -e "  1. Open macos/ThreeBlindMice.xcodeproj in Xcode"
echo -e "  2. Right-click on the ThreeBlindMice folder in the project navigator"
echo -e "  3. Select 'Add Files to ThreeBlindMice'"
echo -e "  4. Navigate to and select icon.png"
echo -e "  5. Make sure 'Add to target: ThreeBlindMice' is checked"
echo -e "  6. Click 'Add'"
echo ""
echo -e "${BLUE}💡 Alternative:${NC}"
echo -e "  The app will fallback to the mouse emoji (🐭) if icon.png is not found"
echo -e "  This ensures the app works even without the manual step"
echo ""
echo -e "${GREEN}🎉 Once added to Xcode, the system tray will use the high-quality icon!${NC}"
