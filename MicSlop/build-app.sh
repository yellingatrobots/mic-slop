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

# Convert PNG to icns and copy
ICON_SOURCE="../mic-slop.png"
if [ -f "$ICON_SOURCE" ]; then
    ICONSET_DIR="AppIcon.iconset"
    rm -rf "$ICONSET_DIR"
    mkdir -p "$ICONSET_DIR"
    
    # Generate all required icon sizes
    sips -z 16 16     "$ICON_SOURCE" --out "$ICONSET_DIR/icon_16x16.png" > /dev/null
    sips -z 32 32     "$ICON_SOURCE" --out "$ICONSET_DIR/icon_16x16@2x.png" > /dev/null
    sips -z 32 32     "$ICON_SOURCE" --out "$ICONSET_DIR/icon_32x32.png" > /dev/null
    sips -z 64 64     "$ICON_SOURCE" --out "$ICONSET_DIR/icon_32x32@2x.png" > /dev/null
    sips -z 128 128   "$ICON_SOURCE" --out "$ICONSET_DIR/icon_128x128.png" > /dev/null
    sips -z 256 256   "$ICON_SOURCE" --out "$ICONSET_DIR/icon_128x128@2x.png" > /dev/null
    sips -z 256 256   "$ICON_SOURCE" --out "$ICONSET_DIR/icon_256x256.png" > /dev/null
    sips -z 512 512   "$ICON_SOURCE" --out "$ICONSET_DIR/icon_256x256@2x.png" > /dev/null
    sips -z 512 512   "$ICON_SOURCE" --out "$ICONSET_DIR/icon_512x512.png" > /dev/null
    sips -z 1024 1024 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_512x512@2x.png" > /dev/null
    
    # Convert iconset to icns
    iconutil -c icns "$ICONSET_DIR" -o "$APP_NAME/Contents/Resources/AppIcon.icns"
    rm -rf "$ICONSET_DIR"
    echo "Icon converted and added"
fi

echo "Built $APP_NAME"
echo "Run with: open MicSlop.app"
