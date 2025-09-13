#!/bin/bash

# Script to verify all icons are consistent across platforms
# This script checks icon consistency, sizes, and references

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 Icon Consistency Verification${NC}"
echo "======================================"

# Check if we're in the right directory
if [[ ! -d "assets/icons" ]]; then
    echo -e "${RED}❌ Error: assets/icons directory not found${NC}"
    echo "Please run this script from the project root directory"
    exit 1
fi

# Function to check if file exists and get its size
check_icon() {
    local file="$1"
    local platform="$2"
    local size="$3"
    
    if [[ -f "$file" ]]; then
        local file_size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null)
        echo -e "  ✅ $platform $size: ${file_size} bytes"
        return 0
    else
        echo -e "  ${RED}❌ $platform $size: Missing${NC}"
        return 1
    fi
}

# Function to check icon consistency
check_consistency() {
    local base_size="$1"
    local platforms=("macos" "windows" "linux" "chromeos")
    local sizes=()
    
    case "$base_size" in
        16) sizes=("16x16" "16x16" "16x16" "16x16") ;;
        32) sizes=("32x32" "32x32" "32x32" "32x32") ;;
        48) sizes=("48x48" "48x48" "48x48" "48x48") ;;
        128) sizes=("128x128" "128x128" "128x128" "128x128") ;;
        256) sizes=("256x256" "256x256" "256x256" "256x256") ;;
        512) sizes=("512x512" "512x512" "512x512" "512x512") ;;
        1024) sizes=("1024x1024" "1024x1024" "1024x1024" "1024x1024") ;;
    esac
    
    echo -e "${BLUE}📏 Checking $base_size pixel icons...${NC}"
    
    local all_good=true
    for i in "${!platforms[@]}"; do
        local platform="${platforms[$i]}"
        local size="${sizes[$i]}"
        
        case "$platform" in
            macos)
                check_icon "assets/icons/macos/icon_${size}.png" "macOS" "$size" || all_good=false
                ;;
            windows)
                if [[ "$base_size" -le 256 ]]; then
                    check_icon "assets/icons/windows/icon_${size}.png" "Windows" "$size" || all_good=false
                    check_icon "assets/icons/windows/icon_${size}.ico" "Windows" "$size.ico" || all_good=false
                fi
                ;;
            linux)
                if [[ "$base_size" -le 512 ]]; then
                    check_icon "assets/icons/linux/icon_${size}.png" "Linux" "$size" || all_good=false
                    check_icon "assets/icons/linux/icon_${size}.svg" "Linux" "$size.svg" || all_good=false
                fi
                ;;
            chromeos)
                if [[ "$base_size" -le 128 ]]; then
                    check_icon "assets/icons/chromeos/icon_${size}.png" "ChromeOS" "$size" || all_good=false
                fi
                ;;
        esac
    done
    
    if [[ "$all_good" == true ]]; then
        echo -e "  ${GREEN}✅ All $base_size pixel icons present${NC}"
    else
        echo -e "  ${RED}❌ Some $base_size pixel icons missing${NC}"
    fi
}

# Check platform-specific icons
echo -e "${BLUE}🎯 Platform-Specific Icon Checks${NC}"

# macOS AppIcon.appiconset
echo -e "${BLUE}🍎 macOS AppIcon.appiconset...${NC}"
macos_icons=(
    "macos/ThreeBlindMice/Assets.xcassets/AppIcon.appiconset/icon_16x16.png"
    "macos/ThreeBlindMice/Assets.xcassets/AppIcon.appiconset/icon_16x16@2x.png"
    "macos/ThreeBlindMice/Assets.xcassets/AppIcon.appiconset/icon_32x32.png"
    "macos/ThreeBlindMice/Assets.xcassets/AppIcon.appiconset/icon_32x32@2x.png"
    "macos/ThreeBlindMice/Assets.xcassets/AppIcon.appiconset/icon_128x128.png"
    "macos/ThreeBlindMice/Assets.xcassets/AppIcon.appiconset/icon_128x128@2x.png"
    "macos/ThreeBlindMice/Assets.xcassets/AppIcon.appiconset/icon_256x256.png"
    "macos/ThreeBlindMice/Assets.xcassets/AppIcon.appiconset/icon_256x256@2x.png"
    "macos/ThreeBlindMice/Assets.xcassets/AppIcon.appiconset/icon_512x512.png"
    "macos/ThreeBlindMice/Assets.xcassets/AppIcon.appiconset/icon_512x512@2x.png"
    "macos/ThreeBlindMice/Assets.xcassets/AppIcon.appiconset/icon_1024x1024.png"
)

macos_good=true
for icon in "${macos_icons[@]}"; do
    if [[ -f "$icon" ]]; then
        echo -e "  ✅ $(basename "$icon")"
    else
        echo -e "  ${RED}❌ $(basename "$icon") - Missing${NC}"
        macos_good=false
    fi
done

# ChromeOS Extension
echo -e "${BLUE}🌐 ChromeOS Extension...${NC}"
chromeos_icons=(
    "chromeos/extension/icons/icon16.png"
    "chromeos/extension/icons/icon32.png"
    "chromeos/extension/icons/icon48.png"
    "chromeos/extension/icons/icon128.png"
)

chromeos_good=true
for icon in "${chromeos_icons[@]}"; do
    if [[ -f "$icon" ]]; then
        echo -e "  ✅ $(basename "$icon")"
    else
        echo -e "  ${RED}❌ $(basename "$icon") - Missing${NC}"
        chromeos_good=false
    fi
done

# System tray icon
echo -e "${BLUE}📱 System Tray Icon...${NC}"
if [[ -f "macos/ThreeBlindMice/icon.png" ]]; then
    echo -e "  ✅ macOS system tray icon.png"
else
    echo -e "  ${RED}❌ macOS system tray icon.png - Missing${NC}"
fi

# Check icon consistency across platforms
echo -e "${BLUE}🔄 Cross-Platform Consistency Check${NC}"
check_consistency 16
check_consistency 32
check_consistency 48
check_consistency 128
check_consistency 256
check_consistency 512
check_consistency 1024

# Check manifest references
echo -e "${BLUE}📋 Manifest References${NC}"

# ChromeOS manifest
if grep -q "icon16.png" chromeos/extension/manifest.json; then
    echo -e "  ✅ ChromeOS manifest references correct icons"
else
    echo -e "  ${RED}❌ ChromeOS manifest has incorrect icon references${NC}"
fi

# Linux desktop file
if [[ -f "assets/icons/linux/threeblindmice.desktop" ]]; then
    echo -e "  ✅ Linux desktop file exists"
else
    echo -e "  ${RED}❌ Linux desktop file missing${NC}"
fi

# Summary
echo ""
echo -e "${GREEN}🎉 Icon Verification Complete!${NC}"
echo ""
echo -e "${BLUE}📊 Summary:${NC}"
echo -e "  • Generated icons: $(find assets/icons -name "*.png" | wc -l | tr -d ' ') PNG files"
echo -e "  • Generated icons: $(find assets/icons -name "*.ico" | wc -l | tr -d ' ') ICO files"
echo -e "  • Generated icons: $(find assets/icons -name "*.svg" | wc -l | tr -d ' ') SVG files"
echo -e "  • macOS AppIcon: $([ "$macos_good" == true ] && echo "✅ Complete" || echo "❌ Issues")"
echo -e "  • ChromeOS Extension: $([ "$chromeos_good" == true ] && echo "✅ Complete" || echo "❌ Issues")"
echo ""
echo -e "${BLUE}💡 Next steps:${NC}"
echo -e "  • Test icons in each platform"
echo -e "  • Verify icons appear correctly in system tray/menu bar"
echo -e "  • Check icon quality at different sizes"
