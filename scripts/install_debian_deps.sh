#!/bin/bash

# Install Dependencies for 3 Blind Mice on Debian Linux
# This script installs all required dependencies for building on Debian systems

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 Installing Dependencies for 3 Blind Mice on Debian${NC}"
echo "========================================================"

# Check if running on Debian/Ubuntu
if [[ ! -f /etc/debian_version ]]; then
    echo -e "${YELLOW}⚠️  This script is designed for Debian/Ubuntu systems${NC}"
    echo -e "${BLUE}💡 For other distributions, please install dependencies manually${NC}"
    exit 1
fi

# Update package lists
echo -e "${BLUE}📦 Updating package lists...${NC}"
sudo apt update

# Install build essentials (gcc, g++, make, etc.)
echo -e "${BLUE}🔨 Installing build essentials...${NC}"
sudo apt install -y build-essential

# Install CMake
echo -e "${BLUE}📐 Installing CMake...${NC}"
sudo apt install -y cmake

# Install development libraries
echo -e "${BLUE}📚 Installing development libraries...${NC}"
sudo apt install -y \
    libevdev-dev \
    libx11-dev \
    libxtst-dev \
    pkg-config

# Install Swift (if not already installed)
echo -e "${BLUE}🦉 Checking Swift installation...${NC}"
if ! command -v swift &> /dev/null; then
    echo -e "${YELLOW}⚠️  Swift not found. Installing Swift...${NC}"
    
    # Install Swift dependencies
    sudo apt install -y \
        curl \
        wget \
        gnupg2 \
        software-properties-common \
        apt-transport-https \
        ca-certificates
    
    # Add Swift repository
    wget -q -O - https://swift.org/keys/swift-signing-key.pub | sudo apt-key add -
    echo "deb https://swift.org/builds/swift-6.1-release/ubuntu/$(lsb_release -cs)/swift-6.1 main" | sudo tee /etc/apt/sources.list.d/swift.list
    
    # Update and install Swift
    sudo apt update
    sudo apt install -y swift-6.1
    
    echo -e "${GREEN}✅ Swift installed successfully${NC}"
else
    SWIFT_VERSION=$(swift --version | head -n1)
    echo -e "${GREEN}✅ Swift already installed: $SWIFT_VERSION${NC}"
fi

# Verify installations
echo -e "${BLUE}🔍 Verifying installations...${NC}"

echo -n "  GCC: "
if command -v gcc &> /dev/null; then
    echo -e "${GREEN}$(gcc --version | head -n1)${NC}"
else
    echo -e "${RED}Not found${NC}"
fi

echo -n "  G++: "
if command -v g++ &> /dev/null; then
    echo -e "${GREEN}$(g++ --version | head -n1)${NC}"
else
    echo -e "${RED}Not found${NC}"
fi

echo -n "  CMake: "
if command -v cmake &> /dev/null; then
    echo -e "${GREEN}$(cmake --version | head -n1)${NC}"
else
    echo -e "${RED}Not found${NC}"
fi

echo -n "  Swift: "
if command -v swift &> /dev/null; then
    echo -e "${GREEN}$(swift --version | head -n1)${NC}"
else
    echo -e "${RED}Not found${NC}"
fi

echo -n "  pkg-config: "
if command -v pkg-config &> /dev/null; then
    echo -e "${GREEN}$(pkg-config --version)${NC}"
else
    echo -e "${RED}Not found${NC}"
fi

# Check for required libraries
echo -e "${BLUE}📚 Checking development libraries...${NC}"

check_library() {
    local lib=$1
    if pkg-config --exists $lib; then
        echo -e "  ✅ $lib: $(pkg-config --modversion $lib)"
    else
        echo -e "  ❌ $lib: Not found"
    fi
}

check_library "x11"
check_library "xtst"

if ldconfig -p | grep -q libevdev; then
    echo -e "  ✅ libevdev: Found"
else
    echo -e "  ❌ libevdev: Not found"
fi

echo ""
echo -e "${GREEN}🎉 Dependency installation complete!${NC}"
echo -e "${BLUE}💡 You can now run the Linux build script${NC}"
echo -e "${BLUE}💡 Run: cd linux && ./build.sh${NC}"
