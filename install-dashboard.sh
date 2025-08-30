#!/bin/bash
set -e
echo "🚀 Instalacja RPi Docker Dashboard"

# Tworzenie katalogu panelu
mkdir -p /root/panel

# Tworzenie virtualenv
python3.9 -m venv /root/panel/venv
source /root/panel/venv/bin/activate

# Upgrade pip i setuptools w venv
pip install --upgrade pip setuptools wheel

# Instalacja wymaganych bibliotek w venv
pip install flask jq

# Pobranie panelu
wget -O /root/panel/panel.zip "https://raw.githubusercontent.com/hattimon/rpi4-docker-dashboard/main/panel.zip"
unzip -o /root/panel/panel.zip -d /root/panel

# Skrypt generujący status
cat <<'EOF' > /root/generate_status.sh
#!/bin/bash
STATUS_FILE="/root/panel/status.json"
CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print 100-$8"%"}')
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

# Cron do aktualizacji statusu co minutę
(crontab -l 2>/dev/null; echo "* * * * * /root/generate_status.sh") | crontab -

# Systemd service
cat <<EOF | sudo tee /etc/systemd/system/rpi-dashboard.service
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

sudo systemctl daemon-reload
sudo systemctl enable rpi-dashboard
sudo systemctl restart rpi-dashboard

echo "✅ Instalacja zakończona. Panel: http://$(hostname -I | awk '{print $1}'):8080/"
