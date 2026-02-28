#!/bin/bash
# setup.sh - Generate Xcode project for Galaga Neon
# Requires: xcodegen (brew install xcodegen)

set -e

echo "🕹️  WarGamesRisk - Project Setup"
echo "================================"

# Check for xcodegen
if ! command -v xcodegen &> /dev/null; then
    echo "❌ xcodegen not found. Installing via Homebrew..."
    if command -v brew &> /dev/null; then
        brew install xcodegen
    else
        echo "Please install xcodegen: brew install xcodegen"
        exit 1
    fi
fi

# Generate project
echo "📦 Generating Xcode project..."
xcodegen generate

echo ""
echo "✅ Project generated successfully!"
echo ""
echo "🎮 Enjoy!"
