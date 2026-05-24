#!/bin/bash
# Install ShiftMate (Flutter Linux desktop) system-wide.
#
# Usage:
#   ./install_linux.sh              # Install to /usr/local
#   ./install_linux.sh /usr         # Install to /usr
#   ./install_linux.sh --uninstall  # Remove installation

set -e

PREFIX="${1:-/usr/local}"
if [ "$PREFIX" = "--uninstall" ]; then
    echo "Uninstalling ShiftMate..."
    sudo rm -rf "$PREFIX/lib/shiftmate"
    sudo rm -f "$PREFIX/bin/shiftmate"
    sudo rm -f "$PREFIX/share/applications/shiftmate.desktop"
    sudo rm -f "$PREFIX/share/icons/hicolor/256x256/apps/shiftmate.png"
    echo "Done."
    exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== ShiftMate Linux Install ==="
echo "Prefix: $PREFIX"

# Step 1: Build if not already built
BUNDLE="$SCRIPT_DIR/build/linux/x64/release/bundle"
if [ ! -f "$BUNDLE/scheduler_cp" ]; then
    echo ""
    echo "No release build found. Running build.sh..."
    "$SCRIPT_DIR/build.sh"
fi

# Step 2: Copy application files
echo "Installing to $PREFIX/lib/shiftmate..."
sudo mkdir -p "$PREFIX/lib/shiftmate"
sudo cp -r "$BUNDLE"/* "$PREFIX/lib/shiftmate/"

# Step 3: Symlink binary
sudo mkdir -p "$PREFIX/bin"
sudo ln -sf "$PREFIX/lib/shiftmate/scheduler_cp" "$PREFIX/bin/shiftmate"

# Step 4: Install icon
sudo mkdir -p "$PREFIX/share/icons/hicolor/256x256/apps"
sudo cp "$SCRIPT_DIR/linux_icon.png" "$PREFIX/share/icons/hicolor/256x256/apps/shiftmate.png"

# Step 5: Install .desktop file
sudo mkdir -p "$PREFIX/share/applications"
sudo cp "$SCRIPT_DIR/shiftmate.desktop" "$PREFIX/share/applications/"

# Step 6: Update desktop database
if command -v update-desktop-database &> /dev/null; then
    sudo update-desktop-database "$PREFIX/share/applications" || true
fi

echo ""
echo "Installation complete."
echo "  Binary:    $PREFIX/bin/shiftmate"
echo "  App data:  $PREFIX/lib/shiftmate/"
echo "  Launcher:  $PREFIX/share/applications/shiftmate.desktop"
echo ""
echo "Run: shiftmate"
echo "Or find '倒班助手' in your application launcher."
