#!/bin/bash

# Script to add icon.png to Xcode project
# This script properly adds the icon.png file to the Xcode project bundle

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}🍎 Adding icon.png to Xcode Project${NC}"
echo "=============================================="

# Check if we're in the right directory
if [[ ! -f "scripts/icon.png" ]]; then
    echo -e "${RED}❌ Error: scripts/icon.png not found${NC}"
    echo "Please run this script from the project root directory"
    exit 1
fi

# Check if Xcode project exists
if [[ ! -d "macos/ThreeBlindMice.xcodeproj" ]]; then
    echo -e "${RED}❌ Error: Xcode project not found${NC}"
    echo "Expected: macos/ThreeBlindMice.xcodeproj"
    exit 1
fi

# Copy icon.png to the macOS project directory
echo -e "${BLUE}📁 Copying icon.png to macOS project...${NC}"
cp scripts/icon.png macos/ThreeBlindMice/icon.png
echo -e "  ✅ Copied icon.png to macos/ThreeBlindMice/"

# Generate proper UUIDs for Xcode project
ICON_BUILD_UUID=$(uuidgen | tr '[:lower:]' '[:upper:]')
ICON_FILE_UUID=$(uuidgen | tr '[:lower:]' '[:upper:]')

echo -e "${BLUE}🔧 Updating Xcode project file...${NC}"

# Create backup
cp macos/ThreeBlindMice.xcodeproj/project.pbxproj macos/ThreeBlindMice.xcodeproj/project.pbxproj.backup

# Add icon.png to PBXBuildFile section
sed -i '' "/Assets.xcassets in Resources/a\\
		${ICON_BUILD_UUID} /* icon.png in Resources */ = {isa = PBXBuildFile; fileRef = ${ICON_FILE_UUID} /* icon.png */; };" macos/ThreeBlindMice.xcodeproj/project.pbxproj

# Add icon.png to PBXFileReference section
sed -i '' "/Info.plist.*sourceTree = \"<group>\";/a\\
		${ICON_FILE_UUID} /* icon.png */ = {isa = PBXFileReference; lastKnownFileType = image.png; path = icon.png; sourceTree = \"<group>\"; };" macos/ThreeBlindMice.xcodeproj/project.pbxproj

# Add icon.png to ThreeBlindMice group
sed -i '' "/Info.plist.*path = Info.plist;/a\\
				${ICON_FILE_UUID} /* icon.png */," macos/ThreeBlindMice.xcodeproj/project.pbxproj

# Add icon.png to Resources build phase
sed -i '' "/Assets.xcassets in Resources/a\\
				${ICON_BUILD_UUID} /* icon.png in Resources */," macos/ThreeBlindMice.xcodeproj/project.pbxproj

echo -e "  ✅ Updated Xcode project file"

# Test the project
echo -e "${BLUE}🧪 Testing Xcode project...${NC}"
cd macos

if xcodebuild -project ThreeBlindMice.xcodeproj -scheme ThreeBlindMice -configuration Debug -quiet build; then
    echo -e "  ✅ Xcode project builds successfully"
    echo -e "${GREEN}🎉 icon.png successfully added to Xcode project!${NC}"
else
    echo -e "  ${RED}❌ Xcode project build failed${NC}"
    echo -e "  ${YELLOW}⚠️  Restoring backup...${NC}"
    cp ThreeBlindMice.xcodeproj/project.pbxproj.backup ThreeBlindMice.xcodeproj/project.pbxproj
    echo -e "  ✅ Backup restored"
    exit 1
fi

cd ..

echo ""
echo -e "${GREEN}🎯 Summary:${NC}"
echo -e "  • icon.png copied to macos/ThreeBlindMice/"
echo -e "  • Xcode project updated with proper references"
echo -e "  • Project builds successfully"
echo ""
echo -e "${BLUE}💡 Next steps:${NC}"
echo -e "  • Open Xcode project to verify icon.png is included"
echo -e "  • Build and run the app to see the new system tray icon"
echo -e "  • The system tray will now use the high-quality icon.png instead of emoji"
