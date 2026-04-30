#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#   TouchifyMouse — macOS DMG builder
#
#   Output:
#     dist/TouchifyMouse-mac.dmg              ← stable filename for hosting
#     dist/TouchifyMouse-<version>-mac.dmg    ← versioned archive copy
#
#   Run from the touchifymouse_desktop/ directory:
#     bash scripts/build_dmg.sh
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

APP_NAME="TouchifyMouse"
VERSION=$(grep '^version:' pubspec.yaml | awk '{print $2}' | tr -d "'" | cut -d'+' -f1)
DIST_DIR="dist"
BUILD_DIR="build/macos/Build/Products/Release"
FLUTTER_APP="touchifymouse_desktop.app"
APP_PATH="${BUILD_DIR}/${FLUTTER_APP}"

# We ship under a stable filename so https://.../releases/latest/download/<this>
# always works — no need to update mobile-app constants on every release.
DMG_STABLE="${DIST_DIR}/${APP_NAME}-mac.dmg"
DMG_VERSIONED="${DIST_DIR}/${APP_NAME}-${VERSION}-mac.dmg"

echo "──────────────────────────────────────────────"
echo "  Building ${APP_NAME} v${VERSION} (macOS)"
echo "──────────────────────────────────────────────"

# 1. Clean prior build artifacts so the icon / asset catalog refreshes.
echo "→ flutter clean"
flutter clean >/dev/null

# 2. Flutter release build.
echo "→ flutter build macos --release"
flutter build macos --release

if [[ ! -d "${APP_PATH}" ]]; then
  echo "✗ Build did not produce ${APP_PATH}" >&2
  exit 1
fi

# 3. Stage the .app under its user-facing name + an /Applications symlink.
mkdir -p "${DIST_DIR}"
STAGE_DIR="$(mktemp -d)"
trap 'rm -rf "${STAGE_DIR}"' EXIT

cp -R "${APP_PATH}" "${STAGE_DIR}/${APP_NAME}.app"
ln -s /Applications "${STAGE_DIR}/Applications"

# 4. Remove any old DMGs to avoid hdiutil "exists" errors.
rm -f "${DMG_STABLE}" "${DMG_VERSIONED}"

echo "→ Creating DMG…"
hdiutil create \
  -volname "${APP_NAME}" \
  -srcfolder "${STAGE_DIR}" \
  -ov \
  -format UDZO \
  "${DMG_STABLE}" >/dev/null

# 5. Versioned copy for archival.
cp "${DMG_STABLE}" "${DMG_VERSIONED}"

SIZE_MB=$(du -m "${DMG_STABLE}" | awk '{print $1}')
echo ""
echo "✅  Built:"
echo "    ${DMG_STABLE}            (${SIZE_MB} MB — upload this to GitHub)"
echo "    ${DMG_VERSIONED}    (archival copy)"
echo ""
echo "Next: gh release upload <tag> ${DMG_STABLE}"
echo "      or upload via the GitHub Releases web UI."
