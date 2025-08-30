#!/bin/bash
# Odinstalowanie RPi Docker Dashboard z /root (bez usuwania Dockera)

echo "🗑️ Odinstalowywanie RPi Docker Dashboard..."

# 1. Zatrzymanie i usunięcie usługi systemd
if systemctl list-unit-files | grep -q rpi-dashboard.service; then
    sudo systemctl stop rpi-dashboard
    sudo systemctl disable rpi-dashboard
    sudo rm -f /etc/systemd/system/rpi-dashboard.service
    sudo systemctl daemon-reload
    echo "✔ Usługa rpi-dashboard usunięta"
fi

# 2. Usunięcie crona dla generate_status.sh
crontab -l 2>/dev/null | grep -v "generate_status.sh" | crontab -
echo "✔ Cron wyczyszczony"

# 3. Usunięcie plików panelu i skryptów
rm -rf /root/panel /root/generate_status.sh /root/install-dashboard.sh /root/uninstall-dashboard.sh
echo "✔ Pliki dashboarda usunięte"

echo "✅ Odinstalowanie zakończone. Docker i inne kontenery pozostały nietknięte."
