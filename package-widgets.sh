#!/usr/bin/env bash
# Package both Desktop Widgets for store submission.
# Usage: ./package-widgets.sh [kde|gnome|all]
# Default: all

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET="${1:-all}"

package_kde() {
    echo "=== Packaging KDE Plasma 6 Plasmoid ==="
    "$SCRIPT_DIR/plasma/package.sh"
    echo ""
}

package_gnome() {
    echo "=== Packaging GNOME Shell Extension ==="
    "$SCRIPT_DIR/gnome/package.sh"
    echo ""
}

case "$TARGET" in
    kde)   package_kde ;;
    gnome) package_gnome ;;
    all)
        package_kde
        package_gnome
        echo "=== Done ==="
        echo "KDE:   $SCRIPT_DIR/plasma/banban-shift.plasmoid"
        echo "GNOME: $SCRIPT_DIR/gnome/banban-shift.zip"
        ;;
    *)
        echo "Usage: $0 [kde|gnome|all]"
        exit 1
        ;;
esac
