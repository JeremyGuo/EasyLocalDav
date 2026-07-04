#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_DIR="$DIST_DIR/EasyLocalDav.app"
CONTENTS_DIR="$APP_DIR/Contents"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
MACOS_DIR="$CONTENTS_DIR/MacOS"

rm -rf "$DIST_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

swift build -c release --arch arm64 --package-path "$ROOT_DIR"
BIN_PATH="$(swift build -c release --arch arm64 --package-path "$ROOT_DIR" --show-bin-path)"

cp "$BIN_PATH/EasyLocalDav" "$MACOS_DIR/EasyLocalDav"
cp "$ROOT_DIR/Packaging/Info.plist" "$CONTENTS_DIR/Info.plist"
cp -R "$ROOT_DIR/Resources/Icons" "$RESOURCES_DIR/Icons"
cp "$ROOT_DIR/Resources/ThirdPartyNotices.md" "$RESOURCES_DIR/ThirdPartyNotices.md"

swift "$ROOT_DIR/Scripts/make_app_icon.swift" "$DIST_DIR/AppIcon.iconset" "$RESOURCES_DIR/AppIcon.icns"

if [[ -n "${RCLONE_PATH:-}" ]]; then
  cp "$RCLONE_PATH" "$RESOURCES_DIR/rclone"
  chmod +x "$RESOURCES_DIR/rclone"
elif command -v rclone >/dev/null 2>&1; then
  cp "$(command -v rclone)" "$RESOURCES_DIR/rclone"
  chmod +x "$RESOURCES_DIR/rclone"
else
  echo "warning: rclone was not embedded because it was not found" >&2
fi

if [[ "${SKIP_CODESIGN:-0}" != "1" ]]; then
  if command -v codesign >/dev/null 2>&1; then
    if command -v xattr >/dev/null 2>&1; then
      xattr -cr "$APP_DIR" || true
    fi

    SIGN_IDENTITY="${CODESIGN_IDENTITY:--}"
    if [[ -x "$RESOURCES_DIR/rclone" ]]; then
      codesign --force --sign "$SIGN_IDENTITY" "$RESOURCES_DIR/rclone"
    fi
    codesign --force --deep --sign "$SIGN_IDENTITY" "$APP_DIR"
    codesign --verify --deep --strict --verbose=2 "$APP_DIR"
  else
    echo "warning: codesign was not found; app bundle was left unsigned" >&2
  fi
fi

echo "$APP_DIR"
