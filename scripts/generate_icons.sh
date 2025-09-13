#!/bin/bash

# 3 Blind Mice - Cross-Platform Icon Generator (Shell Script)
# ===========================================================
# 
# Generates icons for all platforms using ImageMagick or sips
# 
# Usage:
#   ./scripts/generate_icons.sh [source_image] [output_dir]
# 
# Examples:
#   ./scripts/generate_icons.sh                    # Generate from default mouse icon
#   ./scripts/generate_icons.sh logo.png            # Generate from source image
#   ./scripts/generate_icons.sh logo.png custom/    # Custom output directory

set -e

# Configuration
SOURCE_IMAGE="${1:-}"
OUTPUT_DIR="${2:-assets/icons}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Icon sizes for each platform
MACOS_SIZES=(16 32 64 128 256 512 1024)
WINDOWS_SIZES=(16 24 32 48 64 96 128 256)
LINUX_SIZES=(16 24 32 48 64 96 128 256 512)
CHROMEOS_SIZES=(16 32 48 128)

echo -e "${BLUE}🐭 3 Blind Mice - Cross-Platform Icon Generator${NC}"
echo "=================================================="

# Check dependencies
check_dependencies() {
    echo -e "${BLUE}🔍 Checking dependencies...${NC}"
    
    if command -v convert >/dev/null 2>&1; then
        echo -e "${GREEN}✅ ImageMagick found${NC}"
        CONVERT_CMD="convert"
    elif command -v sips >/dev/null 2>&1; then
        echo -e "${GREEN}✅ macOS sips found${NC}"
        CONVERT_CMD="sips"
    else
        echo -e "${RED}❌ Neither ImageMagick nor sips found${NC}"
        echo -e "${YELLOW}💡 Install ImageMagick: brew install imagemagick${NC}"
        echo -e "${YELLOW}💡 Or use macOS sips (built-in)${NC}"
        return 1
    fi
    
    return 0
}

# Create output directories
create_directories() {
    echo -e "${BLUE}📁 Creating output directories...${NC}"
    
    mkdir -p "$OUTPUT_DIR"/{macos,windows,linux,chromeos}
    
    echo -e "${GREEN}✅ Directories created${NC}"
}

# Generate a simple mouse icon using ImageMagick
create_mouse_icon() {
    local size="$1"
    local output="$2"
    
    if [[ "$CONVERT_CMD" == "convert" ]]; then
        # ImageMagick version
        convert -size "${size}x${size}" xc:transparent \
            -fill '#999999' \
            -draw "roundrectangle 2,2 $((size-2)),$((size-2)) 8,8" \
            -fill '#bbbbbb' \
            -draw "rectangle 4,$((size/4)) $((size/3)),$((size/4+2))" \
            -draw "rectangle $((size*2/3)),$((size/4)) $((size-4)),$((size/4+2))" \
            -fill '#666666' \
            -draw "circle $((size/2)),$((size/2)) $((size/2+4)),$((size/2))" \
            -fill '#ffffff' \
            -pointsize $((size/4)) \
            -gravity center \
            -annotate +0+0 "3" \
            "$output"
    else
        # sips version (macOS)
        # Create a simple colored square as fallback
        sips -s format png -z "$size" "$size" -c "$size" "$size" \
            --setProperty format png \
            --out "$output" /System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GenericApplicationIcon.icns 2>/dev/null || \
        convert -size "${size}x${size}" xc:'#999999' "$output"
    fi
}

# Resize image using available tool
resize_image() {
    local source="$1"
    local size="$2"
    local output="$3"
    
    if [[ "$CONVERT_CMD" == "convert" ]]; then
        convert "$source" -resize "${size}x${size}" "$output"
    else
        sips -z "$size" "$size" "$source" --out "$output"
    fi
}

# Generate icons for macOS
generate_macos_icons() {
    echo -e "${BLUE}🍎 Generating macOS icons...${NC}"
    
    local macos_dir="$OUTPUT_DIR/macos"
    
    for size in "${MACOS_SIZES[@]}"; do
        local filename="icon_${size}x${size}.png"
        local filepath="$macos_dir/$filename"
        
        if [[ -n "$SOURCE_IMAGE" ]]; then
            resize_image "$SOURCE_IMAGE" "$size" "$filepath"
        else
            create_mouse_icon "$size" "$filepath"
        fi
        
        echo -e "  ✅ $filename"
    done
    
    # Create @2x versions
    for size in 16 32 128 256 512; do
        local source_file="$macos_dir/icon_${size}x${size}.png"
        local target_file="$macos_dir/icon_${size}x${size}@2x.png"
        
        if [[ -f "$source_file" ]]; then
            cp "$source_file" "$target_file"
            echo -e "  ✅ icon_${size}x${size}@2x.png"
        fi
    done
    
    # Create .iconset directory for Xcode
    create_macos_iconset "$macos_dir"
}

# Generate icons for Windows
generate_windows_icons() {
    echo -e "${BLUE}🪟 Generating Windows icons...${NC}"
    
    local windows_dir="$OUTPUT_DIR/windows"
    
    for size in "${WINDOWS_SIZES[@]}"; do
        local filename="icon_${size}x${size}.png"
        local filepath="$windows_dir/$filename"
        
        if [[ -n "$SOURCE_IMAGE" ]]; then
            resize_image "$SOURCE_IMAGE" "$size" "$filepath"
        else
            create_mouse_icon "$size" "$filepath"
        fi
        
        echo -e "  ✅ $filename"
    done
    
    # Create ICO file for Windows
    if command -v convert >/dev/null 2>&1; then
        local ico_file="$windows_dir/icon_256x256.ico"
        convert "$windows_dir/icon_256x256.png" "$ico_file"
        echo -e "  ✅ icon_256x256.ico"
    fi
}

# Generate icons for Linux
generate_linux_icons() {
    echo -e "${BLUE}🐧 Generating Linux icons...${NC}"
    
    local linux_dir="$OUTPUT_DIR/linux"
    
    for size in "${LINUX_SIZES[@]}"; do
        local filename="icon_${size}x${size}.png"
        local filepath="$linux_dir/$filename"
        
        if [[ -n "$SOURCE_IMAGE" ]]; then
            resize_image "$SOURCE_IMAGE" "$size" "$filepath"
        else
            create_mouse_icon "$size" "$filepath"
        fi
        
        echo -e "  ✅ $filename"
    done
    
    # Create desktop file
    create_linux_desktop "$linux_dir"
}

# Generate icons for ChromeOS
generate_chromeos_icons() {
    echo -e "${BLUE}🌐 Generating ChromeOS icons...${NC}"
    
    local chromeos_dir="$OUTPUT_DIR/chromeos"
    
    for size in "${CHROMEOS_SIZES[@]}"; do
        local filename="icon_${size}x${size}.png"
        local filepath="$chromeos_dir/$filename"
        
        if [[ -n "$SOURCE_IMAGE" ]]; then
            resize_image "$SOURCE_IMAGE" "$size" "$filepath"
        else
            create_mouse_icon "$size" "$filepath"
        fi
        
        echo -e "  ✅ $filename"
    done
    
    # Create manifest snippet
    create_chromeos_manifest "$chromeos_dir"
}

# Create macOS .iconset directory for Xcode
create_macos_iconset() {
    local macos_dir="$1"
    local iconset_dir="$macos_dir/ThreeBlindMice.iconset"
    
    mkdir -p "$iconset_dir"
    
    # Copy icons to iconset format
    cp "$macos_dir/icon_16x16.png" "$iconset_dir/icon_16x16.png"
    cp "$macos_dir/icon_32x32.png" "$iconset_dir/icon_16x16@2x.png"
    cp "$macos_dir/icon_32x32.png" "$iconset_dir/icon_32x32.png"
    cp "$macos_dir/icon_64x64.png" "$iconset_dir/icon_32x32@2x.png"
    cp "$macos_dir/icon_128x128.png" "$iconset_dir/icon_128x128.png"
    cp "$macos_dir/icon_256x256.png" "$iconset_dir/icon_128x128@2x.png"
    cp "$macos_dir/icon_256x256.png" "$iconset_dir/icon_256x256.png"
    cp "$macos_dir/icon_512x512.png" "$iconset_dir/icon_256x256@2x.png"
    cp "$macos_dir/icon_512x512.png" "$iconset_dir/icon_512x512.png"
    cp "$macos_dir/icon_1024x1024.png" "$iconset_dir/icon_512x512@2x.png"
    
    echo -e "  ✅ Created .iconset directory for Xcode"
}

# Create Linux desktop file
create_linux_desktop() {
    local linux_dir="$1"
    local desktop_file="$linux_dir/threeblindmice.desktop"
    
    cat > "$desktop_file" << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=3 Blind Mice
Comment=Multi-Mouse Triangulation Tool
Exec=threeblindmice
Icon=threeblindmice
Terminal=false
Categories=Utility;Accessibility;
Keywords=mouse;multi;accessibility;triangulation;
EOF
    
    echo -e "  ✅ Created desktop file"
}

# Create ChromeOS manifest snippet
create_chromeos_manifest() {
    local chromeos_dir="$1"
    local manifest_file="$chromeos_dir/icon_manifest.json"
    
    cat > "$manifest_file" << 'EOF'
{
  "icons": {
    "16": "icon_16x16.png",
    "32": "icon_32x32.png",
    "48": "icon_48x48.png",
    "128": "icon_128x128.png"
  }
}
EOF
    
    echo -e "  ✅ Created manifest snippet"
}

# Main execution
main() {
    # Check if source image exists
    if [[ -n "$SOURCE_IMAGE" && ! -f "$SOURCE_IMAGE" ]]; then
        echo -e "${RED}❌ Source image not found: $SOURCE_IMAGE${NC}"
        exit 1
    fi
    
    # Check dependencies
    if ! check_dependencies; then
        exit 1
    fi
    
    # Create directories
    create_directories
    
    # Generate icons for all platforms
    generate_macos_icons
    generate_windows_icons
    generate_linux_icons
    generate_chromeos_icons
    
    # Summary
    echo -e "\n${GREEN}🎉 Icon generation complete!${NC}"
    echo -e "${BLUE}📁 Output directory: $OUTPUT_DIR${NC}"
    
    # Count generated files
    local file_count=$(find "$OUTPUT_DIR" -name "*.png" -o -name "*.ico" | wc -l)
    echo -e "${BLUE}📊 Generated $file_count icon files${NC}"
    
    # Show directory structure
    echo -e "\n${BLUE}📋 Directory structure:${NC}"
    tree "$OUTPUT_DIR" 2>/dev/null || find "$OUTPUT_DIR" -type f | sort
    
    echo -e "\n${YELLOW}💡 Next steps:${NC}"
    echo -e "  • Copy icons to your platform-specific directories"
    echo -e "  • Update Xcode project with macOS icons"
    echo -e "  • Include Windows icons in your build"
    echo -e "  • Install Linux desktop file"
    echo -e "  • Update Chrome Extension manifest"
}

# Run main function
main "$@"
