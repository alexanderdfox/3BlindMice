#!/bin/bash

echo "🐭 Installing 3 Blind Mice for Linux"
echo "====================================="

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root (use sudo)"
    exit 1
fi

# Check if executable exists
if [ ! -f "build/bin/ThreeBlindMice" ]; then
    echo "❌ Executable not found"
    echo "Please run ./build.sh first"
    exit 1
fi

echo "📋 Installing udev rules..."

# Install udev rules
cp udev/99-threeblindmice.rules /etc/udev/rules.d/
if [ $? -eq 0 ]; then
    echo "✅ udev rules installed"
else
    echo "❌ Failed to install udev rules"
    exit 1
fi

# Reload udev rules
udevadm control --reload-rules
udevadm trigger

echo "📋 Adding user to input group..."

# Get the original user (not root)
ORIGINAL_USER=${SUDO_USER:-$USER}

# Add user to input group
usermod -a -G input "$ORIGINAL_USER"
if [ $? -eq 0 ]; then
    echo "✅ User $ORIGINAL_USER added to input group"
else
    echo "❌ Failed to add user to input group"
    exit 1
fi

echo "📋 Installing executable..."

# Install executable to /usr/local/bin
cp build/bin/ThreeBlindMice /usr/local/bin/
chmod +x /usr/local/bin/ThreeBlindMice

if [ $? -eq 0 ]; then
    echo "✅ Executable installed to /usr/local/bin/ThreeBlindMice"
else
    echo "❌ Failed to install executable"
    exit 1
fi

echo ""
echo "✅ Installation completed successfully!"
echo ""
echo "📋 Next steps:"
echo "1. Logout and login again to apply group changes"
echo "2. Run: ThreeBlindMice"
echo ""
echo "💡 Or run directly: /usr/local/bin/ThreeBlindMice"
echo ""
