#!/bin/bash
# Instalacja RPi Docker Dashboard w /root (Python 3.5 / Stretch)

set -e

echo "🚀 Instalacja RPi Docker Dashboard (Opcja 3)"

# 1️⃣ Aktualizacja systemu
sudo apt update && sudo apt upgrade -y

# 2️⃣ Instalacja potrzebnych pakietów (bez docker.io)
sudo apt install -y jq wget unzip python3-venv python3-dev

# 3️⃣ Utworzenie katalogu panel w /root
mkdir -p /root/panel

# 4️⃣ Utworzenie virtualenv i instalacja Flask kompatybilnego z Python 3.5
python3 -m venv /root/panel/venv
source /root/panel/venv/bin/activate
pip install --upgrade pip==20.3.4 setuptools==44.1.1 wheel
pip install Flask==1.1.4
deactivate

# 5️⃣ Pobranie panelu z repo
if [ ! -f /root/panel/app.py ]; then
    echo "Pobieranie plików panelu..."
    wget -O /root/panel/panel.zip "https://raw.githubusercontent.com/hattimon/rpi4-docker-dashboard/main/panel.zip"
    unzip -o /root/panel/panel.zip -d /root/panel
fi

# 6️⃣ Tworzenie skryptu generującego status
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

# 7️⃣ Dodanie crona do aktualizacji statusu co minutę
(crontab -l 2>/dev/null; echo "* * * * * /root/generate_status.sh") | crontab -

# 8️⃣ Tworzenie usługi systemd dla dashboarda (wirtualne środowisko)
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
