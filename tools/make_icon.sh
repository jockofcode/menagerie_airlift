#!/bin/sh
# Regenerates assets/icons/icon.png and icon.icns from tools/make_icon.rb,
# which paints the icon with the game's own rasterizer. macOS only (uses
# sips and iconutil).
#
# Usage: tools/make_icon.sh
set -e

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
PROJECT_DIR=$(cd "$SCRIPT_DIR/.." && pwd)
cd "$PROJECT_DIR"

mkdir -p build assets/icons
spinel tools/make_icon.rb -o build/make_icon
build/make_icon build/icon.tga

sips -s format png build/icon.tga --out assets/icons/icon.png >/dev/null

ICONSET=build/icon.iconset
rm -rf "$ICONSET"
mkdir -p "$ICONSET"
for size in 16 32 128 256 512; do
  double=$((size * 2))
  sips -z "$size" "$size" assets/icons/icon.png --out "$ICONSET/icon_${size}x${size}.png" >/dev/null
  sips -z "$double" "$double" assets/icons/icon.png --out "$ICONSET/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o assets/icons/icon.icns
rm -rf "$ICONSET" build/icon.tga
echo "wrote assets/icons/icon.png and assets/icons/icon.icns"
