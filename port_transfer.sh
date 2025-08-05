#!/bin/bash

BASE_DIR="/opt/ssh_tunnel"
LOGFILE="$BASE_DIR/ssh_tunnel.log"
RUNNER="$BASE_DIR/tunnel_runner.sh"
SERVICE_FILE="/etc/systemd/system/ssh_tunnel.service"

function start_tunnel() {
    read -p "VPS IP adresini girin: " VPS_IP
    read -p "Bağlantı portunu girin (örnek: 80): " PORT
    read -s -p "VPS şifresini girin: " VPS_PASS
    echo ""

    mkdir -p "$BASE_DIR"

    echo "Tünel scripti oluşturuluyor..."

    cat <<EOF > $RUNNER
#!/bin/bash
while true; do
    echo "\$(date): Bağlantı deneniyor..." >> $LOGFILE
    sshpass -p '$VPS_PASS' ssh -v -o StrictHostKeyChecking=no -N -R $PORT:localhost:$PORT root@$VPS_IP >> $LOGFILE 2>&1
    echo "\$(date): Bağlantı koptu. 5 saniye sonra tekrar denenecek." >> $LOGFILE
    sleep 5
done
EOF

    chmod +x $RUNNER

    echo "systemd servisi oluşturuluyor..."

    cat <<EOF | sudo tee $SERVICE_FILE > /dev/null
[Unit]
Description=SSH Reverse Tunnel
After=network.target

[Service]
ExecStart=$RUNNER
Restart=always
RestartSec=5
User=root

[Install]
WantedBy=multi-user.target
EOF

    echo "Servis etkinleştiriliyor ve başlatılıyor..."
    sudo systemctl daemon-reexec
    sudo systemctl daemon-reload
    sudo systemctl enable ssh_tunnel.service
    sudo systemctl start ssh_tunnel.service

    echo "Kurulum tamamlandı. SSH tünel servisi aktif."
}

function stop_tunnel() {
    echo "Servis durduruluyor ve kaldırılıyor..."
    sudo systemctl stop ssh_tunnel.service
    sudo systemctl disable ssh_tunnel.service
    sudo rm -f $SERVICE_FILE
    sudo systemctl daemon-reload

    echo "Dosyalar temizleniyor..."
    rm -rf "$BASE_DIR"

    echo "Tünel ve servis başarıyla kaldırıldı."
}

function analyze_logs() {
    if [ -f "$LOGFILE" ]; then
        echo "---- Bağlantı Logları ----"
        tail -n 50 "$LOGFILE"
    else
        echo "Log dosyası bulunamadı."
    fi
}

function check_dependencies() {
    command -v sshpass >/dev/null 2>&1 || { echo >&2 "HATA: 'sshpass' yüklü değil. Yüklemek için: sudo apt install sshpass"; exit 1; }
    command -v ssh >/dev/null 2>&1 || { echo >&2 "HATA: 'ssh' yüklü değil."; exit 1; }
}

function show_menu() {
    while true; do
        echo ""
        echo "=== SSH Tünel Yöneticisi ==="
        echo "1. Kurulum yap"
        echo "2. Kurulumu kaldır"
        echo "3. Analiz (log görüntüle)"
        echo "4. Çıkış"
        read -p "Seçiminiz: " CHOICE

        case $CHOICE in
            1) check_dependencies; start_tunnel ;;
            2) stop_tunnel ;;
            3) analyze_logs ;;
            4) echo "Çıkılıyor..."; exit 0 ;;
            *) echo "Geçersiz seçim!" ;;
        esac
    done
}

show_menu
