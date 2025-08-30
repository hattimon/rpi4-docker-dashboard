#!/bin/bash
set -e

SERVICE_FILE="/etc/systemd/system/rpi-dashboard.service"
DASHBOARD_DIR="/root/panel"

echo "🛑 Usuwanie RPi Docker Dashboard..."

# Stop i disable service
sudo systemctl stop rpi-dashboard || true
sudo systemctl disable rpi-dashboard || true
sudo rm -f "$SERVICE_FILE"
sudo systemctl daemon-reload

# Usunięcie katalogu dashboardu
rm -rf "$DASHBOARD_DIR"

echo "✅ Dashboard odinstalowany!"
