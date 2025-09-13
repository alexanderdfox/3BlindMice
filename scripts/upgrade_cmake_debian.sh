#!/bin/bash

# Upgrade CMake for Debian Linux
# This script helps upgrade CMake to a newer version on Debian systems

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 CMake Upgrade Helper for Debian Linux${NC}"
echo "=============================================="

# Check if running on Debian/Ubuntu
if [[ ! -f /etc/debian_version ]]; then
    echo -e "${YELLOW}⚠️  This script is designed for Debian/Ubuntu systems${NC}"
    echo -e "${BLUE}💡 For other distributions, please install CMake manually${NC}"
    exit 1
fi

# Check current CMake version
if command -v cmake &> /dev/null; then
    CURRENT_VERSION=$(cmake --version | head -n1)
    echo -e "${BLUE}📋 Current CMake version: $CURRENT_VERSION${NC}"
    
    CMAKE_VERSION_NUM=$(cmake --version | head -n1 | grep -oE '[0-9]+\.[0-9]+' | head -n1)
    CMAKE_MAJOR=$(echo $CMAKE_VERSION_NUM | cut -d. -f1)
    CMAKE_MINOR=$(echo $CMAKE_VERSION_NUM | cut -d. -f2)
    
    if [[ $CMAKE_MAJOR -gt 3 ]] || [[ $CMAKE_MAJOR -eq 3 && $CMAKE_MINOR -ge 10 ]]; then
        echo -e "${GREEN}✅ CMake version is already compatible (3.10+)${NC}"
        exit 0
    fi
else
    echo -e "${YELLOW}⚠️  CMake not found${NC}"
fi

echo -e "${BLUE}🔍 Checking available CMake versions...${NC}"

# Method 1: Try to install from official repositories
echo -e "${BLUE}📦 Method 1: Installing from official repositories...${NC}"
if sudo apt update && sudo apt install -y cmake; then
    NEW_VERSION=$(cmake --version | head -n1)
    echo -e "${GREEN}✅ CMake updated: $NEW_VERSION${NC}"
    exit 0
fi

# Method 2: Install from Kitware repository (newer versions)
echo -e "${BLUE}📦 Method 2: Installing from Kitware repository...${NC}"

# Add Kitware GPG key
wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - | sudo tee /etc/apt/trusted.gpg.d/kitware.gpg >/dev/null

# Add Kitware repository
echo "deb https://apt.kitware.com/ubuntu/ $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/kitware.list >/dev/null

# Update and install
if sudo apt update && sudo apt install -y cmake; then
    NEW_VERSION=$(cmake --version | head -n1)
    echo -e "${GREEN}✅ CMake updated from Kitware: $NEW_VERSION${NC}"
    exit 0
fi

# Method 3: Build from source (last resort)
echo -e "${BLUE}📦 Method 3: Building from source...${NC}"
echo -e "${YELLOW}⚠️  This will take several minutes${NC}"

# Install build dependencies
sudo apt install -y build-essential libssl-dev

# Download and build CMake
cd /tmp
CMAKE_VERSION="3.28.1"
wget "https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}.tar.gz"
tar -xzf "cmake-${CMAKE_VERSION}.tar.gz"
cd "cmake-${CMAKE_VERSION}"

# Configure and build
./bootstrap --prefix=/usr/local
make -j$(nproc)
sudo make install

# Update PATH
echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.bashrc
export PATH="/usr/local/bin:$PATH"

NEW_VERSION=$(cmake --version | head -n1)
echo -e "${GREEN}✅ CMake built from source: $NEW_VERSION${NC}"
echo -e "${BLUE}💡 You may need to restart your terminal or run: source ~/.bashrc${NC}"

echo ""
echo -e "${GREEN}🎉 CMake upgrade complete!${NC}"
echo -e "${BLUE}💡 You can now run the Linux build script${NC}"
