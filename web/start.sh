#!/bin/bash

# 3 Blind Mice Web Server Startup Script

echo "🐭 Starting 3 Blind Mice Web Server..."
echo "======================================"

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js 16+ first."
    echo "   Visit: https://nodejs.org/"
    exit 1
fi

# Check Node.js version
NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 16 ]; then
    echo "⚠️  Node.js version $NODE_VERSION detected. Version 16+ is recommended."
fi

echo "✅ Node.js version: $(node -v)"

# Check if package.json exists
if [ ! -f "package.json" ]; then
    echo "❌ package.json not found. Please run this script from the web directory."
    exit 1
fi

# Install dependencies if node_modules doesn't exist
if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install
    if [ $? -ne 0 ]; then
        echo "❌ Failed to install dependencies."
        exit 1
    fi
    echo "✅ Dependencies installed successfully"
else
    echo "✅ Dependencies already installed"
fi

# Check if robotjs is installed (optional)
if npm list robotjs &> /dev/null; then
    echo "✅ Host cursor control enabled (robotjs installed)"
else
    echo "⚠️  Host cursor control disabled (robotjs not installed)"
    echo "   To enable host cursor control, run: npm install robotjs"
fi

echo ""
echo "🚀 Starting server..."
echo "   Server will be available at: http://localhost:3000"
echo "   Open this URL on multiple computers to connect"
echo ""
echo "📋 Controls:"
echo "   - Press Ctrl+C to stop the server"
echo "   - Host computer can toggle modes with 'M' key"
echo "   - Press 'C' to clear data, 'H' to toggle help"
echo ""

# Start the server
npm start
