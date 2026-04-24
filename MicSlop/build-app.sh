#!/bin/bash
set -e

# Build release
swift build -c release

# Create app bundle structure
APP_NAME="MicSlop.app"
rm -rf "$APP_NAME"
mkdir -p "$APP_NAME/Contents/MacOS"
mkdir -p "$APP_NAME/Contents/Resources"

# Copy executable
cp .build/release/MicSlop "$APP_NAME/Contents/MacOS/"

# Copy Info.plist
cp Info.plist "$APP_NAME/Contents/"

# Copy app icon
cp AppIcon.icns "$APP_NAME/Contents/Resources/"

echo "Built $APP_NAME"
echo "Run with: open MicSlop.app"
