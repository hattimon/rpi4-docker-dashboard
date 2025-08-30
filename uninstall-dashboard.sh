#!/bin/bash
# Skrypt do odinstalowania RPi Docker Dashboard

set -e

echo "🗑️ Odinstalowywanie RPi Docker Dashboard..."

# 1️⃣ Usunięcie usługi systemd
if systemctl is-active --quiet rpi-dashboard; then
    sudo systemctl stop rpi-dashboard
fi
if systemctl is-enabled --quiet rpi-dashboard; then
    sudo systemctl disable rpi-dashboard
fi
sudo rm -f /etc/systemd/system/rpi-dashboard.service
sudo systemctl daemon-reload

# 2️⃣ Usunięcie crona aktualizacji statusu
(crontab -l 2>/dev/null | grep -v "/root/generate_status.sh") | crontab -

# 3️⃣ Usunięcie katalogu panelu i virtualenv
rm -rf /root/panel

echo "✅ Dashboard został odinstalowany."
