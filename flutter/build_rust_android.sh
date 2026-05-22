#!/bin/bash
# Build Rust FFI library for Android and deploy to connected device.
# Prerequisites: cargo-ndk, Android NDK, Rust Android targets
#
# Usage:
#   ./build_rust_android.sh          # Build for ARM64 only
#   ./build_rust_android.sh --all    # Build for all 4 Android ABIs
#   ./build_rust_android.sh --run    # Build + flutter run

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUST_DIR="$SCRIPT_DIR/rust"
JNILIB_DIR="$SCRIPT_DIR/android/app/src/main/jniLibs"
ANDROID_NDK=$(ls -d "$ANDROID_HOME/ndk/"*/ 2>/dev/null | sort -V | tail -1)

if [ -z "$ANDROID_NDK" ]; then
    echo "Error: ANDROID_HOME not set or no NDK found"
    echo "Set ANDROID_HOME to your Android SDK path"
    exit 1
fi

export ANDROID_NDK_HOME="$ANDROID_NDK"
echo "Using NDK: $ANDROID_NDK_HOME"

TARGETS="arm64-v8a"
if [ "${1:-}" = "--all" ]; then
    TARGETS="arm64-v8a armeabi-v7a x86_64 x86"
fi

echo "Building Rust library for Android ($TARGETS)..."
cd "$RUST_DIR"

for target in $TARGETS; do
    echo "  Building $target..."
    cargo ndk -t "$target" -o "$JNILIB_DIR" build --release
done

echo "Done. Libraries in $JNILIB_DIR"
ls -la "$JNILIB_DIR"/*/libshift_flutter_bridge.so 2>/dev/null || true

if [ "${1:-}" = "--run" ] || [ "${2:-}" = "--run" ]; then
    echo ""
    echo "Deploying to device..."
    cd "$SCRIPT_DIR"
    flutter run
fi
