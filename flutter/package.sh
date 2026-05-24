#!/bin/bash
# Package ShiftMate for distribution.
# Produces a portable tar.gz that runs from any directory.
#
# Usage:
#   ./package.sh                  # Build release + package
#   ./package.sh --appimage       # Build AppImage (requires linuxdeploy)

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== Building ShiftMate release ==="
"$SCRIPT_DIR/build.sh"

echo ""
echo "=== Packaging ==="

VERSION="1.0.0"
BUNDLE="$SCRIPT_DIR/build/linux/x64/release/bundle"
PACKAGE_DIR="$SCRIPT_DIR/build/shiftmate-$VERSION-x86_64"
PACKAGE_FILE="$SCRIPT_DIR/build/shiftmate-$VERSION-x86_64.tar.gz"

if [ -d "$PACKAGE_DIR" ]; then
    rm -rf "$PACKAGE_DIR"
fi

mkdir -p "$PACKAGE_DIR"
cp -r "$BUNDLE"/* "$PACKAGE_DIR/"

# Create launcher script
cat > "$PACKAGE_DIR/shiftmate" << 'LAUNCHER'
#!/bin/bash
DIR="$(cd "$(dirname "$0")" && pwd)"
exec "$DIR/scheduler_cp" "$@"
LAUNCHER
chmod +x "$PACKAGE_DIR/shiftmate"

# Copy icon and .desktop
cp "$SCRIPT_DIR/linux_icon.png" "$PACKAGE_DIR/"
sed 's|Exec=shiftmate|Exec=./shiftmate|' "$SCRIPT_DIR/shiftmate.desktop" > "$PACKAGE_DIR/shiftmate.desktop"
sed -i 's|Icon=shiftmate|Icon=./linux_icon.png|' "$PACKAGE_DIR/shiftmate.desktop"

# Create README
cat > "$PACKAGE_DIR/README.txt" << 'README'
ShiftMate (倒班助手) — Linux Desktop
=====================================

Quick start:
  ./shiftmate          Launch the application
  ./install_linux.sh   Install system-wide (requires sudo)

For calendar integration:
  banban export --ics  Export shift schedule to ICS file
  banban install       Set up systemd auto-sync timers

See: https://github.com/MiniPikka/SimpleShiftScheduler
README

# Create archive
cd "$SCRIPT_DIR/build"
tar czf "$PACKAGE_FILE" "$(basename "$PACKAGE_DIR")"
rm -rf "$PACKAGE_DIR"

echo ""
echo "Package: $PACKAGE_FILE"
echo "Size:    $(du -h "$PACKAGE_FILE" | cut -f1)"

# Optional AppImage
if [ "${1:-}" = "--appimage" ]; then
    if ! command -v linuxdeploy &> /dev/null; then
        echo ""
        echo "AppImage: linuxdeploy not found. Install it first:"
        echo "  yay -S linuxdeploy"
        exit 0
    fi

    echo ""
    echo "=== Building AppImage ==="
    APPDIR="$SCRIPT_DIR/build/AppDir"
    rm -rf "$APPDIR"

    mkdir -p "$APPDIR/usr/bin"
    mkdir -p "$APPDIR/usr/share/applications"
    mkdir -p "$APPDIR/usr/share/icons/hicolor/256x256/apps"

    cp -r "$BUNDLE"/* "$APPDIR/usr/bin/"
    cp "$SCRIPT_DIR/shiftmate.desktop" "$APPDIR/usr/share/applications/"
    cp "$SCRIPT_DIR/linux_icon.png" "$APPDIR/usr/share/icons/hicolor/256x256/apps/shiftmate.png"

    linuxdeploy --appdir "$APPDIR" --output appimage
    echo "AppImage built."
fi
