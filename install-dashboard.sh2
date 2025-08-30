#!/bin/bash
# Instalacja RPi Docker Dashboard w /root (Python 3.9 dla panelu, Python 3.5 zostaje dla crankk)

set -e

echo "🚀 Instalacja RPi Docker Dashboard (Python 3.9)"

# 1️⃣ Aktualizacja systemu
sudo apt update && sudo apt upgrade -y

# 2️⃣ Instalacja potrzebnych pakietów (bez docker.io, bez python3-pip ze Stretch!)
sudo apt install -y jq wget unzip curl

# 3️⃣ Instalacja pip tylko dla Python 3.9 (panel)
if ! python3.9 -m pip --version >/dev/null 2>&1; then
    echo "➡ Instaluję pip dla Python 3.9"
    curl -sS https://bootstrap.pypa.io/get-pip.py -o get-pip.py
    sudo python3.9 get-pip.py
    rm -f get-pip.py
fi

# 4️⃣ Utworzenie katalogu panel w /root
mkdir -p /root/panel

# 5️⃣ Pobranie panelu z repo
if [ ! -f /root/panel/app.py ]; then
    echo "Pobieranie plików panelu..."
    wget -O /root/panel/panel.zip "https://raw.githubusercontent.com/hattimon/rpi4-docker-dashboard/main/panel.zip"
    unzip -o /root/panel/panel.zip -d /root/panel
fi

# 6️⃣ Instalacja Flask na Pythonie 3.9
python3.9 -m pip install --upgrade pip
python3.9 -m pip install flask

# 7️⃣ Tworzenie skryptu generującego status
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

# 8️⃣ Dodanie crona do aktualizacji statusu co minutę
(crontab -l 2>/dev/null; echo "* * * * * /root/generate_status.sh") | crontab -

# 9️⃣ Pobranie skryptu odinstalowującego
if [ ! -f /root/uninstall-dashboard.sh ]; then
    wget -O /root/uninstall-dashboard.sh "https://raw.githubusercontent.com/hattimon/rpi4-docker-dashboard/main/uninstall-dashboard.sh"
    chmod +x /root/uninstall-dashboard.sh
    echo "✔ Skrypt uninstall-dashboard.sh gotowy do użycia"
fi

# 🔟 Tworzenie usługi systemd dla dashboarda (Python 3.9)
SERVICE_FILE="/etc/systemd/system/rpi-dashboard.service"
sudo bash -c "cat > $SERVICE_FILE" <<EOF
[Unit]
Description=RPi Docker Dashboard
After=network.target

[Service]
WorkingDirectory=/root/panel
ExecStart=/usr/bin/python3.9 /root/panel/app.py
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

# 1️⃣1️⃣ Włączenie i start serwisu
sudo systemctl daemon-reload
sudo systemctl enable rpi-dashboard
sudo systemctl restart rpi-dashboard

echo "✅ Instalacja zakończona."
echo "📊 Panel dostępny pod adresem: http://$(hostname -I | awk '{print $1}'):8080/"
echo "🗑️ Jeśli chcesz odinstalować panel, uruchom: /root/uninstall-dashboard.sh"
