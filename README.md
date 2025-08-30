RPi Docker Dashboard
Prosty, profesjonalny panel monitorujący Raspberry Pi i kontenery Docker.Pokazuje status systemu (CPU, RAM, temperatura, dysk), aktywne kontenery z opcją manualnego restartu, konfigurację WiFi (skanowanie, łączenie, zapominanie sieci) oraz połączenia sieciowe w trybie ciemnym z animacjami. Automatyczna aktualizacja co kilka sekund.
Funkcjonalności

📊 Graficzne wykresy (progress bary) dla CPU, RAM, temperatury i użycia dysku.
📡 Sekcja "WiFi Config": skanowanie sieci, wybór i łączenie z siecią, zapominanie sieci.
🐳 Lista kontenerów Docker z przyciskami do restartu.
🌑 Tryb ciemny z animacjami CSS i cieniami dla profesjonalnego wyglądu.
🚀 Backend Flask dla dynamicznego statusu i interakcji.

Instalacja
wget https://raw.githubusercontent.com/hattimon/rpi4-docker-dashboard/main/install-dashboard.sh
chmod +x install-dashboard.sh
sudo ./install-dashboard.sh

Po instalacji panel jest dostępny w katalogu /root/panel/ i uruchamia się automatycznie jako usługa pod adresem:👉 http://<IP_Raspberry_Pi>:8080/
Skrypt instalacyjny:

Instaluje wymagane pakiety (jq, wget, unzip, python3-pip, flask).
Tworzy usługę systemd dla Flask app.
Pobiera uninstall-dashboard.sh do /root.

Odinstalowanie
Aby całkowicie usunąć RPi Docker Dashboard (bez usuwania Dockera i innych kontenerów), uruchom:
/root/uninstall-dashboard.sh

Skrypt:

Zatrzymuje i usuwa usługę systemd dla dashboarda.
Czyści cron dla generate_status.sh.
Usuwa pliki /root/panel/, generate_status.sh, install-dashboard.sh oraz uninstall-dashboard.sh.
