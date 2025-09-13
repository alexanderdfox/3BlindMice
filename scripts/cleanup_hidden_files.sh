#!/bin/bash

# Script to clean up hidden files across all operating systems
# This script removes common hidden files that should not be in version control

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}🧹 Hidden Files Cleanup${NC}"
echo "=========================="

# Function to remove files safely
remove_files() {
    local pattern="$1"
    local description="$2"
    
    echo -e "${BLUE}🔍 Looking for $description...${NC}"
    
    # Find files matching pattern
    local files=$(find . -name "$pattern" -type f 2>/dev/null | grep -v ".git" || true)
    
    if [[ -n "$files" ]]; then
        echo -e "  ${YELLOW}Found $description files:${NC}"
        echo "$files" | while read -r file; do
            echo -e "    • $file"
        done
        
        echo -e "  ${BLUE}Removing $description files...${NC}"
        echo "$files" | while read -r file; do
            rm -f "$file"
            echo -e "    ✅ Removed: $file"
        done
    else
        echo -e "  ✅ No $description files found"
    fi
}

# Function to remove directories safely
remove_directories() {
    local pattern="$1"
    local description="$2"
    
    echo -e "${BLUE}🔍 Looking for $description directories...${NC}"
    
    # Find directories matching pattern
    local dirs=$(find . -name "$pattern" -type d 2>/dev/null | grep -v ".git" || true)
    
    if [[ -n "$dirs" ]]; then
        echo -e "  ${YELLOW}Found $description directories:${NC}"
        echo "$dirs" | while read -r dir; do
            echo -e "    • $dir"
        done
        
        echo -e "  ${BLUE}Removing $description directories...${NC}"
        echo "$dirs" | while read -r dir; do
            rm -rf "$dir"
            echo -e "    ✅ Removed: $dir"
        done
    else
        echo -e "  ✅ No $description directories found"
    fi
}

# macOS Hidden Files
echo -e "${BLUE}🍎 Cleaning macOS hidden files...${NC}"
remove_files ".DS_Store" "macOS .DS_Store"
remove_files "._*" "macOS resource fork"
remove_files ".AppleDouble" "macOS AppleDouble"
remove_files ".LSOverride" "macOS LSOverride"
remove_files ".Spotlight-V100" "macOS Spotlight"
remove_files ".Trashes" "macOS Trashes"
remove_files ".fseventsd" "macOS fseventsd"
remove_files ".TemporaryItems" "macOS TemporaryItems"
remove_files ".VolumeIcon.icns" "macOS VolumeIcon"
remove_files ".com.apple.timemachine.donotpresent" "macOS TimeMachine"
remove_files ".AppleDB" "macOS AppleDB"
remove_files ".AppleDesktop" "macOS AppleDesktop"
remove_files ".apdisk" "macOS apdisk"

# Windows Hidden Files
echo -e "${BLUE}🪟 Cleaning Windows hidden files...${NC}"
remove_files "Thumbs.db" "Windows Thumbs.db"
remove_files "ehthumbs.db" "Windows ehthumbs.db"
remove_files "Desktop.ini" "Windows Desktop.ini"
remove_directories "\$RECYCLE.BIN" "Windows Recycle Bin"
remove_files "*.cab" "Windows CAB files"
remove_files "*.msi" "Windows MSI files"
remove_files "*.msix" "Windows MSIX files"
remove_files "*.msm" "Windows MSM files"
remove_files "*.msp" "Windows MSP files"
remove_files "*.lnk" "Windows shortcut files"
remove_files "*.url" "Windows URL files"

# Linux Hidden Files
echo -e "${BLUE}🐧 Cleaning Linux hidden files...${NC}"
remove_files ".fuse_hidden*" "Linux FUSE hidden"
remove_files ".directory" "Linux directory"
remove_files ".Trash-*" "Linux Trash"
remove_files ".nfs*" "Linux NFS"
remove_files ".dmrc" "Linux DMRC"
remove_files ".session" "Linux session"
remove_files ".ICEauthority" "Linux ICE authority"
remove_files ".Xauthority" "Linux X authority"
remove_files ".xsession-errors" "Linux X session errors"
remove_files ".xsession-errors.old" "Linux X session errors old"

# ChromeOS Hidden Files
echo -e "${BLUE}🌐 Cleaning ChromeOS hidden files...${NC}"
remove_directories ".cache" "ChromeOS cache"
remove_directories ".tmp" "ChromeOS tmp"

# Cross-Platform Temporary Files
echo -e "${BLUE}🌍 Cleaning cross-platform temporary files...${NC}"
remove_files "*.tmp" "temporary files"
remove_files "*.temp" "temporary files"
remove_files "*.log" "log files"
remove_files "*.bak" "backup files"
remove_files "*.swp" "Vim swap files"
remove_files "*.swo" "Vim swap files"
remove_files "*~" "backup files"
remove_files "*.orig" "original files"
remove_files "*.rej" "reject files"

# Check for any remaining hidden files
echo -e "${BLUE}🔍 Checking for remaining hidden files...${NC}"
remaining=$(find . -name ".*" -type f 2>/dev/null | grep -v ".git" | grep -v ".gitignore" || true)

if [[ -n "$remaining" ]]; then
    echo -e "  ${YELLOW}Remaining hidden files:${NC}"
    echo "$remaining" | while read -r file; do
        echo -e "    • $file"
    done
    echo -e "  ${BLUE}Consider adding these to .gitignore if they should be ignored${NC}"
else
    echo -e "  ${GREEN}✅ No remaining hidden files found${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Hidden files cleanup complete!${NC}"
echo ""
echo -e "${BLUE}💡 Tips:${NC}"
echo -e "  • Run this script regularly to keep the repository clean"
echo -e "  • Add any new hidden file patterns to .gitignore"
echo -e "  • Use 'git status' to check for untracked files"
echo -e "  • Consider using 'git clean -fd' to remove untracked files"
echo ""
echo -e "${BLUE}🔧 To prevent future hidden files:${NC}"
echo -e "  • Configure your editor to not create backup files"
echo -e "  • Use 'git config --global core.excludesfile' for global ignores"
echo -e "  • Set up your OS to not create hidden files in project directories"
