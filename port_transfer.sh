#!/bin/bash

BASE_DIR="/opt/ssh_tunnel"
LOGFILE="$BASE_DIR/ssh_tunnel.log"
STATUSFILE="$BASE_DIR/status.log"
RUNNER="$BASE_DIR/tunnel_runner.sh"
SERVICE_FILE="/etc/systemd/system/ssh_tunnel.service"

function start_tunnel() {
    read -p "VPS IP yaz: " VPS_IP
    read -p "Trasnfer port yaz (meselem: 80): " PORT
    read -s -p "VPS password yaz: " VPS_PASS
    echo ""

    sudo mkdir -p "$BASE_DIR"

    echo "Tünel scripti .."

    cat <<EOF | sudo tee $RUNNER > /dev/null
#!/bin/bash

LOGFILE="$LOGFILE"
STATUSFILE="$STATUSFILE"
VPS_IP="$VPS_IP"
PORT=$PORT
VPS_PASS="$VPS_PASS"

while true; do
    echo "\$(date): Arabaglanysyk gurnalyar..." >> \$LOGFILE
    sshpass -p "\$VPS_PASS" ssh -o StrictHostKeyChecking=no -N -R \$PORT:localhost:\$PORT root@\$VPS_IP >> \$LOGFILE 2>&1 &
    SSH_PID=\$!

    # Bağlantı izleme
    while kill -0 \$SSH_PID 2>/dev/null; do
        sleep 5
        echo -n "\$(date): Arabaglanysyk analizi... " >> \$STATUSFILE
        nc -z -w2 127.0.0.1 \$PORT
        if [ \$? -eq 0 ]; then
            echo "✓ Tünel aktif" >> \$STATUSFILE
        else
            echo "✗ Tünel işlänok" >> \$STATUSFILE
        fi
    done

    echo "\$(date): Arabaglanysyk gitdi tazden barlayan..." >> \$LOGFILE
    sleep 5
done
EOF

    sudo chmod +x $RUNNER

    echo "systemd servisi yasalya..."

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

    echo "Servis tayyar..."
    sudo systemctl daemon-reexec
    sudo systemctl daemon-reload
    sudo systemctl enable ssh_tunnel.service
    sudo systemctl start ssh_tunnel.service

    echo "✅ Tunel servisi aktif."
}

function stop_tunnel() {
    echo "⛔ Servis pozulya..."
    sudo systemctl stop ssh_tunnel.service
    sudo systemctl disable ssh_tunnel.service
    sudo rm -f $SERVICE_FILE
    sudo systemctl daemon-reload

    echo "🧹 faýl pozulya..."
    sudo rm -rf "$BASE_DIR"

    echo "✔️ Tünel ve servis pozuldy."
}

function analyze_logs() {
    echo "---- 🔍 Tünel analiz (Son 10 ) ----"
    if [ -f "$STATUSFILE" ]; then
        tail -n 10 "$STATUSFILE"
    else
        echo "Durum fayl yok."
    fi

    echo ""
    echo "---- 🧾 SSH Logları (Son 10) ----"
    if [ -f "$LOGFILE" ]; then
        tail -n 10 "$LOGFILE"
    else
        echo "Log yok."
    fi
}

function check_dependencies() {
    for cmd in sshpass ssh nc; do
        command -v $cmd >/dev/null 2>&1 || { echo >&2 "HATA: '$cmd' yüklü değil. Yüklemek için: sudo apt install $cmd"; exit 1; }
    done
}

function show_menu() {
    while true; do
        echo ""
        echo "=== tunnel panel==="
        echo "1. Gurnamak"
        echo "2. Pozmak"
        echo "3. Analiz (log)"
        echo "4. Çyk"
        read -p "Sayla: " CHOICE

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
