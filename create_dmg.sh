#!/bin/bash
set -e

# Resolve version
if [ ! -d build/Squint.app ]; then
    echo "Error: build/Squint.app not found. Run ./build.sh first."
    exit 1
fi

VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" build/Squint.app/Contents/Info.plist)
DMG_NAME="Squint-$VERSION.dmg"

echo "Packaging Squint-$VERSION into DMG..."

# Create a temporary staging area
STAGING_DIR="build_dmg"
rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"

# Copy App Bundle
cp -R build/Squint.app "$STAGING_DIR/"

# Create symlink to /Applications
ln -s /Applications "$STAGING_DIR/Applications"

# Create DMG
echo "Generating DMG..."
hdiutil create -volname "Squint" -srcfolder "$STAGING_DIR/" -ov -format UDZO "$DMG_NAME"

# Clean up
rm -rf "$STAGING_DIR"

echo "Done! DMG created at $DMG_NAME"
