#!/usr/bin/env bash
# Package the GNOME Shell extension for extensions.gnome.org submission.
# Usage: ./package.sh
# Output: gnome/banban-shift.zip

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EXT_DIR="$SCRIPT_DIR/banban-shift@simpleshift.scheduler"
OUTPUT="$SCRIPT_DIR/banban-shift.zip"

if [ ! -d "$EXT_DIR" ]; then
    echo "Error: extension directory not found: $EXT_DIR"
    exit 1
fi

# Remove old package
rm -f "$OUTPUT"

# Create .zip (exclude install.sh per GNOME Extensions guidelines)
cd "$EXT_DIR"
zip -r "$OUTPUT" . \
    -x "*.git*" \
    -x "install.sh"
cd "$SCRIPT_DIR"

echo "Packaged: $OUTPUT"
echo "Size: $(du -h "$OUTPUT" | cut -f1)"
echo ""
echo "Contents:"
unzip -l "$OUTPUT"
