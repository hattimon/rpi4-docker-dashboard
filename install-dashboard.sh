#!/bin/bash
# Instalacja RPi Docker Dashboard w /root (zmodyfikowane dla aktualnego systemu)

set -e

echo "🚀 Instalacja RPi Docker Dashboard"

# 1️⃣ Tworzenie katalogu panel w /root
mkdir -p /root/panel

# 2️⃣ Utworzenie virtualenv w panelu (używa systemowego python3.9)
python3.9 -m venv /root/panel/venv
source /root/panel/venv/bin/activate

# 3️⃣ Instalacja potrzebnych pakietów Python
pip install --upgrade pip setuptools wheel
pip install flask jq

# 4️⃣ Pobranie panelu z repo
if [ ! -f /root/panel/app.py ]; then
    echo "Pobieranie plików panelu..."
    wget -O /root/panel/panel.zip "https://raw.githubusercontent.com/hattimon/rpi4-docker-dashboard/main/panel.zip"
    unzip -o /root/panel/panel.zip -d /root/panel
fi

# 5️⃣ Tworzenie skryptu generującego status
cat <<'EOF' > /root/generate_status.sh
#!/bin/bash
STATUS_FILE="/root/panel/status.json"

CPU=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100-$1"%"}')
RAM=$(free | grep Mem | awk '{printf "%.1f%", $3/$2 * 100}')
TEMP=$(vcgencmd measure_temp 2>/dev/null | cut -d "=" -f2)
DISK=$(df -h / | tail -1 | awk '{print $5}')
ETH_IP=$(ip addr show eth0 | grep "inet " | awk '{print $2}' | cut -d/ -f1)
WIFI_IP=$(ip addr show wlan0 | grep "inet " | awk '{print $2}' | cut -d/ -f1)
ETH_IP=${ETH_IP:-"brak"}
WIFI_IP=${WIFI_IP:-"brak"}
CONTAINERS=$(docker ps --format '{"name":"{{.Names}}","image":"{{.Image}}","status":"{{.Status}}"}' | jq -s '.')

cat <<JSON > $STATUS_FILE
{
  "system":{"cpu":"$CPU","ram":"$RAM","temp":"$TEMP","disk":"$DISK"},
  "network":{"eth0":"$ETH_IP","wlan0":"$WIFI_IP"},
  "containers": $CONTAINERS
}
JSON
EOF

chmod +x /root/generate_status.sh

# 6️⃣ Dodanie crona do aktualizacji statusu co minutę
(crontab -l 2>/dev/null; echo "* * * * * /root/generate_status.sh") | crontab -

# 7️⃣ Pobranie skryptu odinstalowującego
if [ ! -f /root/uninstall-dashboard.sh ]; then
    wget -O /root/uninstall-dashboard.sh "https://raw.githubusercontent.com/hattimon/rpi4-docker-dashboard/main/uninstall-dashboard.sh"
    chmod +x /root/uninstall-dashboard.sh
    echo "✔ Skrypt uninstall-dashboard.sh gotowy do użycia"
fi

# 8️⃣ Tworzenie usługi systemd dla dashboarda
SERVICE_FILE="/etc/systemd/system/rpi-dashboard.service"
sudo bash -c "cat > $SERVICE_FILE" <<EOF
[Unit]
Description=RPi Docker Dashboard
After=network.target

[Service]
WorkingDirectory=/root/panel
ExecStart=/root/panel/venv/bin/python /root/panel/app.py
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

# 9️⃣ Włączenie i start serwisu
sudo systemctl daemon-reload
sudo systemctl enable rpi-dashboard
sudo systemctl restart rpi-dashboard

echo "✅ Instalacja zakończona."
echo "📊 Panel dostępny pod adresem: http://$(hostname -I | awk '{print $1}'):8080/"
echo "🗑️ Jeśli chcesz odinstalować panel, uruchom: /root/uninstall-dashboard.sh"
