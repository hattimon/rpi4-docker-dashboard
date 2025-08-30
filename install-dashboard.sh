#!/bin/bash

# Aktualizacja repozytoriów dla Debiana Stretch
echo "deb http://archive.debian.org/debian stretch main contrib non-free" > /etc/apt/sources.list
echo "deb http://archive.debian.org/debian-security stretch/updates main contrib non-free" >> /etc/apt/sources.list

# Aktualizacja i instalacja pakietów
apt-get update
apt-get install -y jq wget unzip python3-pip python3.5

# Instalacja zgodnej wersji Flask dla Python 3.5
pip3 install flask==1.0.2  # Starsza wersja Flask dla zgodności z Python 3.5

# Instalacja zależności dla SenseCAP M1 (LoRa, jeśli wymagane przez Crankk)
apt-get install -y libloragw-dev  # Biblioteki dla LoRaWAN, jeśli Crankk tego wymaga

# Reszta skryptu pozostaje bez zmian, np.:
mkdir -p /root/panel
cd /root/panel
wget -O panel.zip https://github.com/hattimon/rpi4-docker-dashboard/archive/refs/heads/main.zip
unzip panel.zip
mv rpi4-docker-dashboard-main/* .
rm -rf rpi4-docker-dashboard-main panel.zip

# Pobieranie generate_status.sh i ustawianie crona
wget -O /root/generate_status.sh https://raw.githubusercontent.com/hattimon/rpi4-docker-dashboard/main/generate_status.sh
chmod +x /root/generate_status.sh
(crontab -l 2>/dev/null; echo "* * * * * /root/generate_status.sh") | crontab -

# Tworzenie usługi systemd
cat > /etc/systemd/system/rpi-dashboard.service <<EOF
[Unit]
Description=RPi Docker Dashboard
After=network.target

[Service]
ExecStart=/usr/bin/python3 /root/panel/app.py
WorkingDirectory=/root/panel
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl enable rpi-dashboard
systemctl start rpi-dashboard

# Pobieranie skryptu odinstalowującego
wget -O /root/uninstall-dashboard.sh https://raw.githubusercontent.com/hattimon/rpi4-docker-dashboard/main/uninstall-dashboard.sh
chmod +x /root/uninstall-dashboard.sh
