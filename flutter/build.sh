#!/bin/bash
# Unified build: Rust FFI + Flutter Linux desktop release.
#
# Usage:
#   ./build.sh              # Build release (both Rust + Flutter)
#   ./build.sh --debug      # Build debug
#   ./build.sh --run        # Build release + launch app

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUST_DIR="$SCRIPT_DIR/rust"
PROFILE="${1:-release}"

case "$PROFILE" in
  --debug)  PROFILE="debug" ;;
  --run)    PROFILE="release" ;;
  "")       PROFILE="release" ;;
  --*)      echo "Usage: $0 [--debug|--run]"; exit 1 ;;
esac

echo "=== Step 1/2: Building Rust FFI library ($PROFILE) ==="
cd "$RUST_DIR"
if [ "$PROFILE" = "release" ]; then
    cargo build --release
    SO="target/release/libshift_flutter_bridge.so"
else
    cargo build
    SO="target/debug/libshift_flutter_bridge.so"
fi
echo "  .so: $SO ($(du -h "$SO" | cut -f1))"

echo ""
echo "=== Step 2/2: Building Flutter Linux desktop ($PROFILE) ==="
cd "$SCRIPT_DIR"
if [ "$PROFILE" = "release" ]; then
    flutter build linux --release
    BUNDLE="build/linux/x64/release/bundle"
else
    flutter build linux --debug
    BUNDLE="build/linux/x64/debug/bundle"
fi

# Copy the .so into the bundle so FFI can find it
mkdir -p "$BUNDLE/rust/target/$PROFILE"
cp "$RUST_DIR/$SO" "$BUNDLE/rust/target/$PROFILE/"
echo "  .so bundled at: $BUNDLE/rust/target/$PROFILE/"

echo ""
echo "Build complete."
echo "  Binary: $BUNDLE/scheduler_cp"
echo "  Run:    $BUNDLE/scheduler_cp"

if [ "${1:-}" = "--run" ]; then
    echo ""
    echo "Launching..."
    "$BUNDLE/scheduler_cp" &
fi
