#!/bin/bash
# SimpleShiftScheduler Release Script
# Builds and packages all platform artifacts with standardized naming.
#
# Usage:
#   ./scripts/release.sh                   # Build + package (dry run, no publish)
#   ./scripts/release.sh --publish         # Build + package + GitHub Release
#   ./scripts/release.sh --publish --prod  # Same, but build APK with --release
#
# Artifacts produced:
#   dist/
#     banban-v{VERSION}-linux-x86_64.tar.gz     (Rust CLI)
#     SimpleShiftScheduler-v{VERSION}.apk        (Flutter Android)
#     shift-flutter-bridge-v{VERSION}-linux-x86_64.tar.gz  (Linux .so)

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$SCRIPT_DIR"

DIST_DIR="$SCRIPT_DIR/dist"
PUBLISH=false
FLUTTER_RELEASE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --publish) PUBLISH=true; shift ;;
    --prod)    FLUTTER_RELEASE="--release"; shift ;;
    *)         echo "Usage: $0 [--publish] [--prod]"; exit 1 ;;
  esac
done

# --- Read unified version from Cargo.toml workspace ---
VERSION=$(sed -n 's/^version = "\(.*\)"/\1/p' shift-core/Cargo.toml)
if [ -z "$VERSION" ]; then
  echo "Error: could not read version from shift-core/Cargo.toml"
  exit 1
fi
echo "=== SimpleShiftScheduler Release v$VERSION ==="
echo ""

mkdir -p "$DIST_DIR"
rm -f "$DIST_DIR"/*

# --- 1. Build Rust CLI ---
echo "--- Building banban CLI ---"
cargo build --release --manifest-path shift-core/Cargo.toml -p shift-cli
BANBAN_BIN="shift-core/target/release/banban"
if [ ! -f "$BANBAN_BIN" ]; then
  echo "Error: banban binary not found at $BANBAN_BIN"
  exit 1
fi

# --- 2. Package Rust CLI ---
CLI_TGZ="banban-v${VERSION}-linux-x86_64.tar.gz"
tar -czf "$DIST_DIR/$CLI_TGZ" -C shift-core/target/release banban
echo "  -> $DIST_DIR/$CLI_TGZ ($(du -h "$DIST_DIR/$CLI_TGZ" | cut -f1))"

# --- 3. Build Linux .so for Flutter ---
echo "--- Building shift_flutter_bridge .so for Linux ---"
cargo build --release --manifest-path flutter/rust/Cargo.toml 2>/dev/null || \
  echo "  (no rust/ dir or Cargo.toml in flutter/, skipping .so)"
SO_FILE="flutter/rust/target/release/libshift_flutter_bridge.so"
if [ -f "$SO_FILE" ]; then
  SO_TGZ="shift-flutter-bridge-v${VERSION}-linux-x86_64.tar.gz"
  tar -czf "$DIST_DIR/$SO_TGZ" -C "$(dirname "$SO_FILE")" libshift_flutter_bridge.so
  echo "  -> $DIST_DIR/$SO_TGZ ($(du -h "$DIST_DIR/$SO_TGZ" | cut -f1))"
else
  echo "  (libshift_flutter_bridge.so not found, skipping)"
fi

# --- 4. Build Flutter APK (if ANDROID_HOME is set) ---
if [ -n "${ANDROID_HOME:-}" ] && [ -d flutter/android ]; then
  echo "--- Building Flutter APK ---"
  (cd flutter && flutter build apk $FLUTTER_RELEASE --debug)
  APK_SRC="flutter/build/app/outputs/flutter-apk/app-debug.apk"
  if [ -f "$APK_SRC" ]; then
    APK_NAME="SimpleShiftScheduler-v${VERSION}.apk"
    cp "$APK_SRC" "$DIST_DIR/$APK_NAME"
    echo "  -> $DIST_DIR/$APK_NAME ($(du -h "$DIST_DIR/$APK_NAME" | cut -f1))"
  else
    echo "  (APK not found at $APK_SRC, skipping)"
  fi
else
  echo "  (ANDROID_HOME not set or flutter/android not found, skipping APK)"
fi

echo ""
echo "=== Artifacts ==="
ls -lh "$DIST_DIR"

# --- 5. Publish to GitHub (optional) ---
if [ "$PUBLISH" = true ]; then
  echo ""
  echo "--- Publishing GitHub Release v$VERSION ---"
  TAG="v${VERSION}"
  if git rev-parse "$TAG" >/dev/null 2>&1; then
    echo "Error: tag $TAG already exists"
    exit 1
  fi
  NOTES=$(cat <<EOF
## SimpleShiftScheduler v${VERSION}

### Artifacts
- \`banban-v${VERSION}-linux-x86_64.tar.gz\` — Rust CLI binary
- \`SimpleShiftScheduler-v${VERSION}.apk\` — Flutter Android APK
- \`shift-flutter-bridge-v${VERSION}-linux-x86_64.tar.gz\` — Flutter Linux FFI .so
EOF
  )
  gh release create "$TAG" \
    --title "v${VERSION}" \
    --notes "$NOTES" \
    "$DIST_DIR"/*
  echo "  -> Published: https://github.com/MiniPikka/SimpleShiftScheduler/releases/tag/$TAG"
fi

echo ""
echo "=== Done ==="
