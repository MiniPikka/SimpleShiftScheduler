#!/usr/bin/env bash
# Package the KDE Plasma 6 plasmoid for KDE Store submission.
# Usage: ./package.sh
# Output: plasma/banban-shift.plasmoid (zip archive)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLASMOID_DIR="$SCRIPT_DIR/banban-shift@simpleshift.scheduler"
OUTPUT="$SCRIPT_DIR/banban-shift.plasmoid"

if [ ! -d "$PLASMOID_DIR" ]; then
    echo "Error: plasmoid directory not found: $PLASMOID_DIR"
    exit 1
fi

# Remove old package
rm -f "$OUTPUT"

# Create .plasmoid (zip format)
cd "$PLASMOID_DIR"
zip -r "$OUTPUT" . \
    -x "*.git*" \
    -x "install.sh"
cd "$SCRIPT_DIR"

echo "Packaged: $OUTPUT"
echo "Size: $(du -h "$OUTPUT" | cut -f1)"
echo ""
echo "Contents:"
unzip -l "$OUTPUT"
