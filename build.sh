#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
CONFIG="${1:-release}"
case "$CONFIG" in debug|release) ;; *) echo "Usage: ./build.sh [debug|release]" >&2; exit 1 ;; esac
APP="build/Pomo.app"
swift build -c "$CONFIG"
BIN_DIR="$(swift build -c "$CONFIG" --show-bin-path)"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_DIR/Pomo" "$APP/Contents/MacOS/Pomo"
cp Resources/Info.plist "$APP/Contents/Info.plist"
mkdir -p build/AppIcon.iconset
swift Resources/DrawIcon.swift build/AppIcon.iconset
iconutil -c icns build/AppIcon.iconset -o "$APP/Contents/Resources/AppIcon.icns"
codesign --force --sign - "$APP"
codesign --verify --strict "$APP"
echo "Built $APP for $(uname -m), ad-hoc signed. No Apple account required."
echo "Launch: open \"$APP\""
