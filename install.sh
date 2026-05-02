#!/bin/bash
# Galley installer — downloads, installs, and clears macOS quarantine.
# Usage: curl -fsSL https://raw.githubusercontent.com/m0tay/Galley/main/install.sh | bash

set -euo pipefail

APP_NAME="Galley"
DEST="/Applications/${APP_NAME}.app"
RELEASE_URL="https://github.com/m0tay/Galley/releases/latest/download/Galley-v1.0.0-macOS.zip"
TMP_DIR=$(mktemp -d)

cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

echo "==> Downloading ${APP_NAME}..."
curl -fsSL "$RELEASE_URL" -o "$TMP_DIR/Galley.zip"

echo "==> Extracting..."
ditto -xk "$TMP_DIR/Galley.zip" "$TMP_DIR"

echo "==> Installing to /Applications..."
rm -rf "$DEST"
mv "$TMP_DIR/${APP_NAME}.app" "$DEST"

echo "==> Clearing quarantine flag..."
xattr -cr "$DEST" 2>/dev/null || true

echo ""
echo "  ✅  ${APP_NAME} installed to ${DEST}"
echo "  Run:  open /Applications/Galley.app"
echo ""
