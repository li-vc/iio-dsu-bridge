#!/usr/bin/env bash
set -e

# Installer for iio-dsu-bridge (user service, SteamOS-friendly)
# 1) Asks which device you have
# 2) Downloads the binary and device-specific config
# 3) Creates a systemd --user service
# 4) Enables and starts it

SERVICE_NAME="iio-dsu-bridge"
BIN_DIR="$HOME/.local/bin"
BIN_PATH="$BIN_DIR/iio-dsu-bridge"
CONFIG_DIR="$HOME/.config"
CONFIG_FILE="$CONFIG_DIR/iio-dsu-bridge.yaml"
SERVICE_FILE="$CONFIG_DIR/systemd/user/${SERVICE_NAME}.service"

# Base URL for release assets
RELEASE_URL="https://github.com/Sebalvarez97/iio-dsu-bridge/releases/latest/download"

echo "============================================"
echo "  iio-dsu-bridge Installer"
echo "============================================"
echo ""

# Check for curl
if ! command -v curl >/dev/null 2>&1; then
  echo "error: curl is required" >&2
  exit 1
fi

# Check if running interactively
if [ ! -t 0 ]; then
  echo "This installer requires interactive input."
  echo ""
  echo "Please run one of these commands instead:"
  echo ""
  echo "  bash <(curl -fsSL ${RELEASE_URL}/install.sh)"
  echo ""
  echo "Or download and run manually:"
  echo "  curl -fLO ${RELEASE_URL}/install.sh"
  echo "  bash install.sh"
  echo ""
  exit 1
fi

# Interactive device selection
echo "==> Select your device:"
echo "  1) ROG Ally"
echo "  2) Legion Go S"
echo ""
read -p "Enter choice [1-2]: " DEVICE_CHOICE

case "$DEVICE_CHOICE" in
  1)
    CONFIG_URL="${RELEASE_URL}/rog-ally.yaml"
    DEVICE_NAME="ROG Ally"
    ;;
  2)
    CONFIG_URL="${RELEASE_URL}/legion-go-s.yaml"
    DEVICE_NAME="Legion Go S"
    ;;
  *)
    echo "Invalid choice. Exiting."
    exit 1
    ;;
esac

echo ""
echo "==> Installing for: $DEVICE_NAME"
echo ""

echo "==> Creating required folders..."
mkdir -p "$BIN_DIR"
mkdir -p "$CONFIG_DIR"
mkdir -p "$(dirname "$SERVICE_FILE")"

echo "==> Downloading binary..."
curl -fL "${RELEASE_URL}/iio-dsu-bridge" -o "$BIN_PATH"
chmod +x "$BIN_PATH"

echo "==> Downloading config for $DEVICE_NAME..."
curl -fL "$CONFIG_URL" -o "$CONFIG_FILE"

echo "==> Downloading uninstaller to Desktop..."
DESKTOP_DIR="$HOME/Desktop"
mkdir -p "$DESKTOP_DIR"
curl -fL "${RELEASE_URL}/uninstall-iio-dsu-bridge.desktop" -o "$DESKTOP_DIR/uninstall-iio-dsu-bridge.desktop"
chmod +x "$DESKTOP_DIR/uninstall-iio-dsu-bridge.desktop"

echo "==> Writing user service: $SERVICE_FILE"
cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=IIO to DSU Bridge for Gyro/Motion Controls ($DEVICE_NAME)
After=default.target

[Service]
Type=simple
ExecStart=$BIN_PATH --rate=250 --log-every=0
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
EOF

echo "==> Reloading systemd user daemon and enabling service..."
systemctl --user daemon-reload
systemctl --user enable --now "${SERVICE_NAME}.service" || {
  echo ""
  echo "Hint: If systemd --user isn't active in this shell, try re-login or run:"
  echo "      systemctl --user daemon-reload && systemctl --user enable --now ${SERVICE_NAME}.service"
  exit 1
}

# Enable linger so service starts on boot without login
if command -v loginctl >/dev/null 2>&1; then
  echo "==> Enabling user service auto-start on boot..."
  sudo loginctl enable-linger "$USER" 2>/dev/null || true
fi

echo ""
echo "============================================"
echo "  Installation complete!"
echo "============================================"
echo ""
echo "Config file: $CONFIG_FILE"
echo "Binary:      $BIN_PATH"
echo "Service:     $SERVICE_FILE"
echo "Uninstaller: $DESKTOP_DIR/uninstall-iio-dsu-bridge.desktop"
echo ""
echo "View logs with:"
echo "  journalctl --user -u ${SERVICE_NAME} -f"
echo ""
echo "To uninstall, double-click the uninstaller on your Desktop."
