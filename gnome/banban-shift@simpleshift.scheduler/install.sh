#!/bin/bash
# Install GNOME Shell extension for banban shift display.
# Creates a symlink so source edits take effect immediately.
set -euo pipefail

SRC_DIR="$(cd "$(dirname "$0")" && pwd)"
UUID="banban-shift@simpleshift.scheduler"
INSTALL_DIR="${HOME}/.local/share/gnome-shell/extensions/${UUID}"

echo "=== ShiftMate GNOME Extension Installer ==="
echo ""

# Check banban CLI
if ! command -v banban &>/dev/null; then
    echo "⚠️  banban CLI not found in PATH."
    echo "   Install it first: cargo install shift-cli"
    echo "   Or ensure ~/.cargo/bin is in your PATH."
    echo ""
fi

# Remove old installation if it exists (not a symlink)
if [ -d "${INSTALL_DIR}" ] && [ ! -L "${INSTALL_DIR}" ]; then
    echo "Removing old installation at ${INSTALL_DIR}..."
    rm -rf "${INSTALL_DIR}"
fi

# Create or update symlink
if [ -L "${INSTALL_DIR}" ]; then
    echo "Symlink already exists, updating..."
    rm -f "${INSTALL_DIR}"
fi

mkdir -p "$(dirname "${INSTALL_DIR}")"
ln -sf "${SRC_DIR}" "${INSTALL_DIR}"
echo "✓ Installed to ${INSTALL_DIR}"

echo ""
echo "Next steps:"
echo "  1. Restart GNOME Shell:"
echo "     X11: Alt+F2, type 'r', press Enter"
echo "     Wayland: Log out and log back in"
echo "  2. Enable the extension:"
echo "     gnome-extensions enable ${UUID}"
echo ""
echo "Debugging:"
echo "  journalctl -f -o cat /usr/bin/gnome-shell | grep -i banban"
echo "  gnome-extensions info ${UUID}"
