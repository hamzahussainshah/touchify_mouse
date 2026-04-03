#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
#  TouchifyMouse — macOS DMG Builder
#  Usage:  bash scripts/build_dmg.sh
#  Output: dist/TouchifyMouse.dmg
# ─────────────────────────────────────────────────────────────
set -e

APP_NAME="TouchifyMouse"
VERSION=$(grep '^version:' pubspec.yaml | awk '{print $2}' | tr -d "'" | cut -d'+' -f1)
DMG_NAME="${APP_NAME}-${VERSION}-mac.dmg"
BUILD_DIR="build/macos/Build/Products/Release"
# Flutter names the bundle after the project folder, not the display name
FLUTTER_APP="touchifymouse_desktop.app"
APP_PATH="${BUILD_DIR}/${FLUTTER_APP}"
DIST_DIR="dist"

echo "──────────────────────────────────────"
echo "  Building ${APP_NAME} v${VERSION}"
echo "──────────────────────────────────────"

# 1. Flutter release build
echo "→ flutter build macos --release"
flutter build macos --release

# 2. Ensure dist dir exists
mkdir -p "${DIST_DIR}"

# 3. Create a temporary staging folder for the DMG
STAGE_DIR=$(mktemp -d)
# Rename bundle to user-facing name inside the DMG
cp -R "${APP_PATH}" "${STAGE_DIR}/${APP_NAME}.app"
ln -s /Applications "${STAGE_DIR}/Applications"

echo "→ Creating DMG…"

# 4. Build the DMG with hdiutil (ships with macOS — no extra tools needed)
hdiutil create \
  -volname "${APP_NAME}" \
  -srcfolder "${STAGE_DIR}" \
  -ov \
  -format UDZO \
  "${DIST_DIR}/${DMG_NAME}"

rm -rf "${STAGE_DIR}"

echo ""
echo "✅  Done: ${DIST_DIR}/${DMG_NAME}"
echo ""
echo "To install: Open the DMG, drag ${APP_NAME}.app to Applications."
