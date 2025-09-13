#!/bin/bash

# ThreeBlindMice CLI Build Script
# This script builds and runs the command-line version

echo "🔨 Building ThreeBlindMice CLI version..."

# Check if Swift is available
if ! command -v swift &> /dev/null; then
    echo "❌ Error: Swift is not installed or not in PATH"
    echo "Please install Xcode Command Line Tools:"
    echo "xcode-select --install"
    exit 1
fi

# Navigate to project root (in case script is run from elsewhere)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

# Build and run the CLI version
echo "📁 Source: src/cli/3blindmice.swift"
echo "🚀 Running CLI version..."

swift src/cli/3blindmice.swift

echo "✅ CLI version completed"
