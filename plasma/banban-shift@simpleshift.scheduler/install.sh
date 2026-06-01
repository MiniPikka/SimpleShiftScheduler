#!/bin/bash
# Install KDE Plasma 6 plasmoid for banban shift display.
# Requires: banban CLI, banban serve (HTTP API at localhost:11451).
set -euo pipefail

SRC_DIR="$(cd "$(dirname "$0")" && pwd)"
PLASMOID_ID="com.simpleshift.banban"
INSTALL_DIR="${HOME}/.local/share/plasma/plasmoids/${PLASMOID_ID}"
SERVICE_DIR="${HOME}/.config/systemd/user"

echo "=== ShiftMate KDE Plasma Plasmoid Installer ==="
echo ""

# ── 1. Check banban CLI ──
if ! command -v banban &>/dev/null; then
    echo "⚠️  banban CLI not found. Install: cargo install shift-cli"
fi

# ── 2. Install systemd user service for banban serve ──
BANBAN_BIN="$(command -v banban 2>/dev/null || echo "$HOME/.cargo/bin/banban")"
mkdir -p "${SERVICE_DIR}"
cat > "${SERVICE_DIR}/banban-serve.service" << SERVICE
[Unit]
Description=Banban Shift API Server
After=network.target

[Service]
Type=simple
ExecStart=${BANBAN_BIN} serve
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
SERVICE
echo "✓ systemd service: ${SERVICE_DIR}/banban-serve.service"

# ── 3. Install plasmoid ──
rm -rf "${INSTALL_DIR}"
mkdir -p "${INSTALL_DIR}"
cp -r "${SRC_DIR}/contents" "${INSTALL_DIR}/"
cp "${SRC_DIR}/metadata.json" "${INSTALL_DIR}/"
echo "✓ Plasmoid installed to ${INSTALL_DIR}"

# ── 4. Start and enable the API server ──
systemctl --user daemon-reload
systemctl --user enable --now banban-serve.service 2>/dev/null || true
sleep 1
if curl -s http://localhost:11451/health >/dev/null 2>&1; then
    echo "✓ banban API server is running (http://localhost:11451)"
else
    echo "⚠️  API server not responding. Try: systemctl --user start banban-serve"
fi

echo ""
echo "Next steps:"
echo "  1. Restart Plasma: systemctl --user restart plasma-plasmashell"
echo "  2. Add widget: Right-click panel → Add Widgets → ShiftMate"
echo ""
echo "Uninstall:"
echo "  rm -rf ${INSTALL_DIR}"
echo "  systemctl --user disable --now banban-serve.service"
echo "  rm ${SERVICE_DIR}/banban-serve.service"
echo "  systemctl --user restart plasma-plasmashell"
