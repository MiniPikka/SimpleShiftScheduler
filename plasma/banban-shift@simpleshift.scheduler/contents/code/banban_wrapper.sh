#!/bin/sh
# Wrapper to locate banban CLI for Plasma plasmoid.
# Plasma's PATH is minimal — it doesn't include ~/.cargo/bin.
# This script tries common install locations.

# Try cargo install location first (most common)
if [ -x "$HOME/.cargo/bin/banban" ]; then
    exec "$HOME/.cargo/bin/banban" "$@"
fi

# Try system install
if [ -x "/usr/local/bin/banban" ]; then
    exec /usr/local/bin/banban "$@"
fi

# Try AUR/system package
if [ -x "/usr/bin/banban" ]; then
    exec /usr/bin/banban "$@"
fi

# Last resort: hope it's in PATH
exec banban "$@"
