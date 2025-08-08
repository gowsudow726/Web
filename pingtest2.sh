#!/bin/bash

# Scriptin adı: ping_checker2.sh
# Çalıştırmak için: chmod +x ping_checker2.sh && ./ping_checker2.sh

CONFIG_FILE="/etc/ping_checker2.conf"
SERVICE_FILE="/etc/systemd/system/ping_checker2.service"
SCRIPT_FILE="/usr/local/bin/ping_checker2_script.sh"

# Renkli çıktı için
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # Renk sıfırlama

# Kurulum fonksiyonu
install_script() {
    clear
    echo -e "${GREEN}Ping Checker 2 Kurulum${NC}"
    read -p "Ping testi yapılacak IP adresini girin: " ping_ip
    read -p "Timeout durumunda çalıştırılacak komutu girin: " timeout_command

    # Konfigürasyon dosyasını oluştur
    echo "PING_IP=$ping_ip" > $CONFIG_FILE
    echo "TIMEOUT_COMMAND=$timeout_command" >> $CONFIG_FILE

    # Ping kontrol scriptini oluştur
    cat > $SCRIPT_FILE << EOL
#!/bin/bash
source $CONFIG_FILE

while true; do
    ping -c 1 -W 2 \$PING_IP > /dev/null 2>&1
    if [ \$? -ne 0 ]; then
        echo "Ping timeout! Çalıştırılıyor: \$TIMEOUT_COMMAND"
        eval \$TIMEOUT_COMMAND
    fi
    sleep 10
done
EOL

    # Script dosyasına çalıştırma izni ver
    chmod +x $SCRIPT_FILE

    # Systemd servis dosyasını oluştur
    cat > $SERVICE_FILE << EOL
[Unit]
Description=Ping Checker Service 2
After=network.target

[Service]
ExecStart=$SCRIPT_FILE
Restart=always

[Install]
WantedBy=multi-user.target
EOL

    # Servisi başlat ve etkinleştir
    systemctl daemon-reload
    systemctl enable ping_checker2.service
    systemctl start ping_checker2.service

    echo -e "${GREEN}Kurulum tamamlandı! Servis başlatıldı.${NC}"
    sleep 2
}

# Kaldırma fonksiyonu
uninstall_script() {
    clear
    echo -e "${GREEN}Ping Checker 2 Kaldırma${NC}"
    
    # Servisi durdur ve devre dışı bırak
    systemctl stop ping_checker2.service 2>/dev/null
    systemctl disable ping_checker2.service 2>/dev/null

    # Dosyaları sil
    rm -f $CONFIG_FILE $SERVICE_FILE $SCRIPT_FILE

    # Systemd daemon'ını yeniden yükle
    systemctl daemon-reload
    systemctl reset-failed

    echo -e "${GREEN}Kurulum kaldırıldı!${NC}"
    sleep 2
}

# Ana menü
while true; do
    clear
    echo -e "${GREEN}Ping Checker 2 Script${NC}"
    echo "1. Kurulum"
    echo "2. Kurulumu Kaldır"
    echo "3. Çıkış"
    read -p "Seçiminizi yapın (1-3): " choice

    case $choice in
        1)
            install_script
            ;;
        2)
            uninstall_script
            ;;
        3)
            echo -e "${GREEN}Çıkılıyor...${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Geçersiz seçim! Lütfen 1-3 arasında bir sayı girin.${NC}"
            sleep 2
            ;;
    esac
done
