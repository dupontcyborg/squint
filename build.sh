#!/bin/bash

# Exit on error
set -e

echo "Running unit tests..."
swift test

echo "Building Squint..."
swift build -c release

echo "Creating Squint.app bundle structure..."
mkdir -p build/Squint.app/Contents/MacOS
mkdir -p build/Squint.app/Contents/Resources

echo "Copying binary..."
cp .build/release/Squint build/Squint.app/Contents/MacOS/Squint

echo "Copying Info.plist..."
cp Squint/Info.plist build/Squint.app/Contents/Info.plist

echo "Copying App Icon..."
if [ -f Squint/AppIcon.icns ]; then
    cp Squint/AppIcon.icns build/Squint.app/Contents/Resources/AppIcon.icns
else
    echo "Warning: Squint/AppIcon.icns not found, icon will be missing."
fi

# Dynamically set version using git tag (default to 0.1.0)
VERSION=$(git describe --tags --abbrev=0 2>/dev/null || echo "0.1.0")
echo "Configuring version in Info.plist to $VERSION..."
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" build/Squint.app/Contents/Info.plist

echo "Done! Packaged app is at build/Squint.app"
echo "You can launch it using: open build/Squint.app"
