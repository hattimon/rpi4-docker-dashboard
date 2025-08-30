#!/bin/bash
# Instalacja RPi Docker Dashboard w /root

set -e

echo "🚀 Instalacja RPi Docker Dashboard"

# 1️⃣ Aktualizacja systemu i pakietów potrzebnych do dashboardu
sudo apt update
sudo apt install -y jq wget unzip python3 python3-distutils

# 2️⃣ Instalacja Flask tylko jeśli nie ma
if ! python3 -m pip &>/dev/null; then
    curl -sS https://bootstrap.pypa.io/pip/3.9/get-pip.py -o /tmp/get-pip.py
    sudo python3 /tmp/get-pip.py
    rm -f /tmp/get-pip.py
fi

python3 -m pip install --upgrade pip
python3 -m pip install --upgrade flask

# 3️⃣ Tworzenie katalogu panel
mkdir -p /root/panel

# 4️⃣ Pobranie panelu z repo i nadpisanie
echo "📥 Pobieranie panelu..."
wget -O /root/panel/panel.zip "https://raw.githubusercontent.com/hattimon/rpi4-docker-dashboard/main/panel.zip"
unzip -o /root/panel/panel.zip -d /root/panel

# 5️⃣ Skrypt generujący status
cat <<'EOF' > /root/panel/generate_status.sh
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
chmod +x /root/panel/generate_status.sh

# 6️⃣ Cron do aktualizacji statusu co minutę
(crontab -l 2>/dev/null | grep -v "generate_status.sh"; echo "* * * * * /root/panel/generate_status.sh") | crontab -

# 7️⃣ Usługa systemd
SERVICE_FILE="/etc/systemd/system/rpi-dashboard.service"
sudo bash -c "cat > $SERVICE_FILE" <<EOF
[Unit]
Description=RPi Docker Dashboard
After=network.target

[Service]
WorkingDirectory=/root/panel
ExecStart=/usr/bin/python3 /root/panel/app.py
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable rpi-dashboard
sudo systemctl restart rpi-dashboard

# 8️⃣ Skrypt uninstall
cat <<'EOF' > /root/uninstall-dashboard.sh
#!/bin/bash
sudo systemctl stop rpi-dashboard
sudo systemctl disable rpi-dashboard
sudo rm -f /etc/systemd/system/rpi-dashboard.service
sudo systemctl daemon-reload
sudo rm -rf /root/panel
(crontab -l 2>/dev/null | grep -v "generate_status.sh") | crontab -
echo "✔ Dashboard usunięty"
EOF
chmod +x /root/uninstall-dashboard.sh

echo "✅ Instalacja zakończona."
echo "📊 Panel dostępny pod: http://$(hostname -I | awk '{print $1}'):8080/"
echo "🗑️ Odinstalowanie: /root/uninstall-dashboard.sh"
