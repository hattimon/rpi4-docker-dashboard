#!/bin/bash
set -e

# === Konfiguracja ===
DASHBOARD_DIR="/root/panel"
SERVICE_FILE="/etc/systemd/system/rpi-dashboard.service"
PYTHON_BIN=$(which python3)

echo "🚀 Instalacja RPi Docker Dashboard (Python systemowy)"

# === Tworzenie katalogu dashboardu ===
mkdir -p "$DASHBOARD_DIR"
cd "$DASHBOARD_DIR"

# === Instalacja pip jeśli brak ===
if ! "$PYTHON_BIN" -m pip --version >/dev/null 2>&1; then
    echo "pip nie znaleziony, instalacja get-pip.py..."
    wget -O get-pip.py https://bootstrap.pypa.io/pip/3.9/get-pip.py
    sudo "$PYTHON_BIN" get-pip.py
    rm -f get-pip.py
fi

# === Upgrade pip, setuptools, wheel ===
"$PYTHON_BIN" -m pip install --upgrade pip setuptools wheel

# === Instalacja wymaganych pakietów ===
"$PYTHON_BIN" -m pip install flask psutil docker

# === Pobranie dashboard.py ===
if [ ! -f "$DASHBOARD_DIR/dashboard.py" ]; then
    echo "Pobieranie dashboard.py..."
    wget -O "$DASHBOARD_DIR/dashboard.py" "https://raw.githubusercontent.com/hattimon/rpi4-docker-dashboard/main/dashboard.py"
fi

# === Tworzenie systemd service ===
echo "Tworzenie service systemd..."
cat <<EOF | sudo tee "$SERVICE_FILE"
[Unit]
Description=RPi Docker Dashboard
After=network.target docker.service

[Service]
Type=simple
User=root
WorkingDirectory=$DASHBOARD_DIR
ExecStart=$PYTHON_BIN $DASHBOARD_DIR/dashboard.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# === Tworzenie uninstall script ===
cat <<'EOF' > "$DASHBOARD_DIR/uninstall-dashboard.sh"
#!/bin/bash
set -e
SERVICE_FILE="/etc/systemd/system/rpi-dashboard.service"
echo "🗑️ Odinstalowywanie RPi Docker Dashboard..."
sudo systemctl stop rpi-dashboard || true
sudo systemctl disable rpi-dashboard || true
sudo rm -f "$SERVICE_FILE"
sudo systemctl daemon-reload
rm -rf /root/panel
echo "✅ Dashboard odinstalowany"
EOF
chmod +x "$DASHBOARD_DIR/uninstall-dashboard.sh"

# === Reload systemd i uruchomienie ===
sudo systemctl daemon-reload
sudo systemctl enable rpi-dashboard
sudo systemctl restart rpi-dashboard

echo "✅ Dashboard zainstalowany i uruchomiony!"
echo "Do uninstallu: $DASHBOARD_DIR/uninstall-dashboard.sh"
