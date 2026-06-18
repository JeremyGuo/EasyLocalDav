#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_DIR="$DIST_DIR/EasyLocalDav.app"
DMG_ROOT="$DIST_DIR/dmg-root"
RW_DMG_PATH="$DIST_DIR/EasyLocalDav-arm64-rw.dmg"
DMG_PATH="$DIST_DIR/EasyLocalDav-arm64.dmg"

if [[ ! -d "$APP_DIR" ]]; then
  echo "Missing app bundle: $APP_DIR" >&2
  exit 1
fi

rm -rf "$DMG_ROOT" "$RW_DMG_PATH" "$DMG_PATH"
mkdir -p "$DMG_ROOT"
cp -R "$APP_DIR" "$DMG_ROOT/EasyLocalDav.app"
ln -s /Applications "$DMG_ROOT/Applications"

hdiutil create \
  -volname "EasyLocalDav" \
  -srcfolder "$DMG_ROOT" \
  -ov \
  -format UDRW \
  "$RW_DMG_PATH" >/dev/null

MOUNT_DIR="$(mktemp -d /tmp/easylocaldav-dmg.XXXXXX)"
cleanup() {
  hdiutil detach "$MOUNT_DIR" -quiet 2>/dev/null || true
  rm -rf "$MOUNT_DIR"
}
trap cleanup EXIT

hdiutil attach "$RW_DMG_PATH" -mountpoint "$MOUNT_DIR" -nobrowse -quiet

if ! osascript <<APPLESCRIPT
tell application "Finder"
  set dmgFolder to POSIX file "$MOUNT_DIR" as alias
  open dmgFolder
  delay 1
  set dmgWindow to container window of dmgFolder
  set current view of dmgWindow to icon view
  set toolbar visible of dmgWindow to false
  set statusbar visible of dmgWindow to false
  set bounds of dmgWindow to {120, 120, 640, 420}
  set viewOptions to the icon view options of dmgWindow
  set arrangement of viewOptions to not arranged
  set icon size of viewOptions to 96
  set position of item "EasyLocalDav.app" of dmgFolder to {150, 145}
  set position of item "Applications" of dmgFolder to {370, 145}
  update dmgFolder without registering applications
  delay 1
  close dmgWindow
end tell
APPLESCRIPT
then
  echo "warning: Finder layout could not be applied; DMG will still include the Applications alias." >&2
fi

sync
hdiutil detach "$MOUNT_DIR" -quiet
trap - EXIT
rm -rf "$MOUNT_DIR"

hdiutil convert "$RW_DMG_PATH" -format UDZO -o "$DMG_PATH" -ov >/dev/null
rm -f "$RW_DMG_PATH"

echo "$DMG_PATH"
