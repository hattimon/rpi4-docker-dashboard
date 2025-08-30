cat <<'EOF' > uninstall-dashboard.sh
#!/bin/bash
set -e
echo "🗑️ Odinstalowywanie RPi Docker Dashboard"

# Zatrzymanie usługi systemd
sudo systemctl stop rpi-dashboard || true
sudo systemctl disable rpi-dashboard || true
sudo rm -f /etc/systemd/system/rpi-dashboard.service
sudo systemctl daemon-reload

# Usunięcie katalogu panelu
rm -rf /root/panel

# Usunięcie crona
crontab -l 2>/dev/null | grep -v "/root/generate_status.sh" | crontab -

echo "✅ Dashboard odinstalowany."
EOF
chmod +x uninstall-dashboard.sh
