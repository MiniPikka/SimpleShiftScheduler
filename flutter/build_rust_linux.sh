#!/bin/bash
# Build Rust FFI library for Linux desktop and optionally run the Flutter app.
#
# Usage:
#   ./build_rust_linux.sh          # Build release .so + Flutter Linux release
#   ./build_rust_linux.sh --debug  # Build debug .so
#   ./build_rust_linux.sh --run    # Build release + flutter run -d linux

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUST_DIR="$SCRIPT_DIR/rust"
PROFILE="release"

case "${1:-}" in
  --debug)  PROFILE="debug" ;;
  --run)    PROFILE="release" ;;
  "")       PROFILE="release" ;;
  *)        echo "Usage: $0 [--debug|--run]"; exit 1 ;;
esac

echo "Building Rust FFI library for Linux ($PROFILE)..."
cd "$RUST_DIR"
if [ "$PROFILE" = "release" ]; then
    cargo build --release
    SO="$RUST_DIR/target/release/libshift_flutter_bridge.so"
else
    cargo build
    SO="$RUST_DIR/target/debug/libshift_flutter_bridge.so"
fi

echo "Library: $SO ($(du -h "$SO" | cut -f1))"

if [ "${1:-}" = "--run" ]; then
    echo ""
    echo "Launching Flutter Linux desktop..."
    cd "$SCRIPT_DIR"
    flutter run -d linux
fi
