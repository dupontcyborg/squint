#!/bin/bash
set -e

if [ -z "$1" ]; then
    echo "Usage: ./make_icns.sh <source_image.png>"
    exit 1
fi

SRC_IMG="$1"
ICONSET_DIR="AppIcon.iconset"
mkdir -p "$ICONSET_DIR"

echo "Resizing images for iconset..."
sips -z 16 16     -s format png "$SRC_IMG" --out "$ICONSET_DIR/icon_16x16.png" > /dev/null
sips -z 32 32     -s format png "$SRC_IMG" --out "$ICONSET_DIR/icon_16x16@2x.png" > /dev/null
sips -z 32 32     -s format png "$SRC_IMG" --out "$ICONSET_DIR/icon_32x32.png" > /dev/null
sips -z 64 64     -s format png "$SRC_IMG" --out "$ICONSET_DIR/icon_32x32@2x.png" > /dev/null
sips -z 128 128   -s format png "$SRC_IMG" --out "$ICONSET_DIR/icon_128x128.png" > /dev/null
sips -z 256 256   -s format png "$SRC_IMG" --out "$ICONSET_DIR/icon_128x128@2x.png" > /dev/null
sips -z 256 256   -s format png "$SRC_IMG" --out "$ICONSET_DIR/icon_256x256.png" > /dev/null
sips -z 512 512   -s format png "$SRC_IMG" --out "$ICONSET_DIR/icon_256x256@2x.png" > /dev/null
sips -z 512 512   -s format png "$SRC_IMG" --out "$ICONSET_DIR/icon_512x512.png" > /dev/null
sips -z 1024 1024 -s format png "$SRC_IMG" --out "$ICONSET_DIR/icon_512x512@2x.png" > /dev/null

echo "Compiling AppIcon.icns..."
iconutil -c icns "$ICONSET_DIR"

echo "Cleaning up temp files..."
rm -rf "$ICONSET_DIR"

echo "Done! Generated AppIcon.icns"
