#!/bin/bash
set -e

# === Konfiguracja ===
DASHBOARD_DIR="/root/panel"
VENV_DIR="$DASHBOARD_DIR/venv"
SERVICE_FILE="/etc/systemd/system/rpi-dashboard.service"

echo "🚀 Instalacja RPi Docker Dashboard (Python systemowy + virtualenv)"

# === Tworzenie katalogu dashboardu ===
mkdir -p "$DASHBOARD_DIR"
cd "$DASHBOARD_DIR"

# === Tworzenie virtualenv ===
if [ ! -d "$VENV_DIR" ]; then
    echo "Tworzenie virtualenv..."
    python3 -m venv venv
fi

source "$VENV_DIR/bin/activate"

# === Upgrade pip, setuptools, wheel w venv ===
pip install --upgrade pip setuptools wheel

# === Instalacja wymaganych pakietów ===
# Flask, psutil, docker
pip install flask psutil docker

# === Pobranie dashboardu (jeśli nie ma plików) ===
# Zakładamy, że dashboard.py jest głównym plikiem
if [ ! -f "$DASHBOARD_DIR/dashboard.py" ]; then
    echo "Pobieranie dashboard.py..."
    wget -O "$DASHBOARD_DIR/dashboard.py" "https://raw.githubusercontent.com/hattimon/rpi4-docker-dashboard/main/dashboard.py"
fi

# === Tworzenie pliku systemd ===
echo "Tworzenie service systemd..."
cat <<EOF | sudo tee "$SERVICE_FILE"
[Unit]
Description=RPi Docker Dashboard
After=network.target docker.service

[Service]
Type=simple
User=root
WorkingDirectory=$DASHBOARD_DIR
ExecStart=$VENV_DIR/bin/python $DASHBOARD_DIR/dashboard.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# === Reload systemd i uruchomienie ===
sudo systemctl daemon-reload
sudo systemctl enable rpi-dashboard
sudo systemctl restart rpi-dashboard

echo "✅ Dashboard zainstalowany i uruchomiony!"
echo "Do uninstallu: /root/panel/uninstall-dashboard.sh"
