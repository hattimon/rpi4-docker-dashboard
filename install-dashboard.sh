#!/bin/bash
set -e

# === Konfiguracja ===
DASHBOARD_DIR="/root/panel"
SERVICE_FILE="/etc/systemd/system/rpi-dashboard.service"
UNINSTALL_SCRIPT="$DASHBOARD_DIR/uninstall-dashboard.sh"

echo "🚀 Instalacja RPi Docker Dashboard (Python systemowy, bez virtualenv)"

# === Tworzenie katalogu dashboardu ===
mkdir -p "$DASHBOARD_DIR"
cd "$DASHBOARD_DIR"

# === Sprawdzenie pip ===
if ! python3 -m pip --version &>/dev/null; then
    echo "⚠️ Systemowy Python nie ma pip."
    echo "Zainstaluj pip poleceniem:"
    echo "    sudo apt update && sudo apt install python3-pip"
    echo "Po instalacji uruchom ponownie ten skrypt."
    exit 1
fi

# === Upgrade pip, setuptools, wheel ===
python3 -m pip install --upgrade pip setuptools wheel

# === Instalacja wymaganych pakietów ===
python3 -m pip install flask psutil docker

# === Pobranie dashboard.py ===
DASHBOARD_PY="$DASHBOARD_DIR/dashboard.py"
echo "📥 Pobieranie dashboard.py..."
wget -O "$DASHBOARD_PY" "https://raw.githubusercontent.com/hattimon/rpi4-docker-dashboard/main/dashboard.py"

# === Tworzenie pliku systemd ===
echo "🛠️ Tworzenie service systemd..."
cat <<EOF | sudo tee "$SERVICE_FILE"
[Unit]
Description=RPi Docker Dashboard
After=network.target docker.service

[Service]
Type=simple
User=root
WorkingDirectory=$DASHBOARD_DIR
ExecStart=/usr/bin/python3 $DASHBOARD_PY
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# === Reload systemd i uruchomienie ===
sudo systemctl daemon-reload
sudo systemctl enable rpi-dashboard
sudo systemctl restart rpi-dashboard

# === Tworzenie skryptu uninstall ===
cat <<'EOF' > "$UNINSTALL_SCRIPT"
#!/bin/bash
set -e
DASHBOARD_DIR="/root/panel"
SERVICE_FILE="/etc/systemd/system/rpi-dashboard.service"

echo "🗑️ Usuwanie RPi Docker Dashboard..."

sudo systemctl stop rpi-dashboard || true
sudo systemctl disable rpi-dashboard || true
sudo rm -f "$SERVICE_FILE"
sudo systemctl daemon-reload
rm -rf "$DASHBOARD_DIR"

echo "✅ Dashboard odinstalowany."
EOF
chmod +x "$UNINSTALL_SCRIPT"

echo "✅ Dashboard zainstalowany i uruchomiony!"
echo "Do uninstallu: $UNINSTALL_SCRIPT"
