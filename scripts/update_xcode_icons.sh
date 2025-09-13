#!/bin/bash

# Update Xcode Icons Script
# ========================
# 
# This script updates the Xcode project icons with the latest generated icons
# from the assets/icons directory.
# 
# Usage:
#   ./scripts/update_xcode_icons.sh
# 
# Requirements:
#   - Icons must be generated first using generate_icons.sh
#   - Must be run from project root directory

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🍎 Updating Xcode Icons${NC}"
echo "=========================="

# Check if we're in the right directory
if [[ ! -d "macos/ThreeBlindMice/Assets.xcassets/AppIcon.appiconset" ]]; then
    echo -e "${RED}❌ Error: Not in project root directory${NC}"
    echo -e "${YELLOW}💡 Run this script from the project root directory${NC}"
    exit 1
fi

# Check if icons exist
if [[ ! -d "assets/icons/macos" ]]; then
    echo -e "${RED}❌ Error: No generated icons found${NC}"
    echo -e "${YELLOW}💡 Run ./scripts/generate_icons.sh first${NC}"
    exit 1
fi

# Copy icons to Xcode project
echo -e "${BLUE}📁 Copying icons to Xcode project...${NC}"

ICONSET_DIR="macos/ThreeBlindMice/Assets.xcassets/AppIcon.appiconset"
COPIED_COUNT=0

# Define icon list
ICONS=(
    "icon_16x16.png"
    "icon_16x16@2x.png"
    "icon_32x32.png"
    "icon_32x32@2x.png"
    "icon_128x128.png"
    "icon_128x128@2x.png"
    "icon_256x256.png"
    "icon_256x256@2x.png"
    "icon_512x512.png"
    "icon_512x512@2x.png"
    "icon_1024x1024.png"
)

for icon in "${ICONS[@]}"; do
    source_path="assets/icons/macos/$icon"
    target_path="$ICONSET_DIR/$icon"
    
    if [[ -f "$source_path" ]]; then
        cp "$source_path" "$target_path"
        echo -e "  ✅ $icon"
        COPIED_COUNT=$((COPIED_COUNT + 1))
    else
        echo -e "  ⚠️  Missing: $icon"
    fi
done

# Update Contents.json if needed
echo -e "${BLUE}📋 Checking Contents.json...${NC}"

CONTENTS_FILE="$ICONSET_DIR/Contents.json"
if grep -q "1024x1024" "$CONTENTS_FILE"; then
    echo -e "  ✅ Contents.json already includes 1024x1024 icon"
else
    echo -e "  🔧 Adding 1024x1024 icon to Contents.json..."
    
    # Create backup
    cp "$CONTENTS_FILE" "$CONTENTS_FILE.backup"
    
    # Add 1024x1024 entry
    sed -i '' '/"size" : "512x512"/a\
    },\
    {\
      "idiom" : "mac",\
      "scale" : "1x",\
      "size" : "1024x1024"\
    ' "$CONTENTS_FILE"
    
    echo -e "  ✅ Updated Contents.json"
fi

# Check for AccentColor
echo -e "${BLUE}🎨 Checking AccentColor...${NC}"

ACCENT_COLOR_DIR="macos/ThreeBlindMice/Assets.xcassets/AccentColor.colorset"
if [[ -d "$ACCENT_COLOR_DIR" ]]; then
    echo -e "  ✅ AccentColor.colorset already exists"
else
    echo -e "  🔧 Creating AccentColor.colorset..."
    
    mkdir -p "$ACCENT_COLOR_DIR"
    
    cat > "$ACCENT_COLOR_DIR/Contents.json" << 'EOF'
{
  "colors" : [
    {
      "color" : {
        "color-space" : "srgb",
        "components" : {
          "alpha" : "1.000",
          "blue" : "0.200",
          "green" : "0.200",
          "red" : "0.200"
        }
      },
      "idiom" : "universal"
    },
    {
      "appearances" : [
        {
          "appearance" : "luminosity",
          "value" : "dark"
        }
      ],
      "color" : {
        "color-space" : "srgb",
        "components" : {
          "alpha" : "1.000",
          "blue" : "0.400",
          "green" : "0.400",
          "red" : "0.400"
        }
      },
      "idiom" : "universal"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF
    
    echo -e "  ✅ Created AccentColor.colorset"
fi

# Update ChromeOS extension icons
echo -e "${BLUE}🌐 Updating ChromeOS extension icons...${NC}"

CHROMEOS_ICONS=(
    "icon_16x16.png:icon16.png"
    "icon_32x32.png:icon32.png"
    "icon_48x48.png:icon48.png"
    "icon_128x128.png:icon128.png"
)

for icon_mapping in "${CHROMEOS_ICONS[@]}"; do
    source_icon="${icon_mapping%:*}"
    target_icon="${icon_mapping#*:}"
    source_path="assets/icons/chromeos/$source_icon"
    target_path="chromeos/extension/icons/$target_icon"
    
    if [[ -f "$source_path" ]]; then
        cp "$source_path" "$target_path"
        echo -e "  ✅ $target_icon"
        COPIED_COUNT=$((COPIED_COUNT + 1))
    else
        echo -e "  ⚠️  Missing: $source_icon"
    fi
done

# Summary
echo -e "\n${GREEN}🎉 Icon update complete!${NC}"
echo -e "${BLUE}📊 Updated $COPIED_COUNT icon files${NC}"

# Show updated files
echo -e "\n${BLUE}📋 Updated files:${NC}"
echo -e "${YELLOW}Xcode Project:${NC}"
ls -la "$ICONSET_DIR"/*.png | awk '{print "  " $9 " (" $5 " bytes)"}'

echo -e "\n${YELLOW}ChromeOS Extension:${NC}"
ls -la chromeos/extension/icons/*.png | awk '{print "  " $9 " (" $5 " bytes)"}'

echo -e "\n${YELLOW}💡 Next steps:${NC}"
echo -e "  • Open Xcode project to verify icons"
echo -e "  • Build and test the application"
echo -e "  • Icons will appear in menu bar, dock, and App Store"

echo -e "\n${BLUE}🔧 To regenerate icons:${NC}"
echo -e "  ./scripts/generate_icons.sh"
echo -e "  ./scripts/update_xcode_icons.sh"
