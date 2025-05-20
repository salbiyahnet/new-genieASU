#!/bin/bash
# Warna
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'
# Alamat IP lokal
local_ip=$(hostname -I | awk '{print $1}')
# Banner
echo -e "${GREEN}============================================================================${NC}"
echo -e "${GREEN}============================ Install GenieACS. =============================${NC}"
echo -e "${GREEN}======================== NodeJS, MongoDB, GenieACS, ========================${NC}"
echo -e "${GREEN}=================== By SALBIYAH-NET. Info 081336128448 =====================${NC}"
echo -e "${GREEN}============================================================================${NC}"
echo -e "${GREEN}Sebelum melanjutkan, silahkan baca terlebih dahulu. Apakah anda ingin melanjutkan? (y/n)${NC}"
read confirmation

if [ "$confirmation" != "y" ]; then
    echo -e "${GREEN}Install dibatalkan..${NC}"
    exit 1
fi

for ((i = 5; i >= 1; i--)); do
    sleep 1
    echo "Lanjut Boskuh... $i. Tekan ctrl+c untuk membatalkan"
done

# Instal MongoDB
if ! sudo systemctl is-active --quiet mongod; then
    echo -e "${GREEN}================== Menginstall MongoDB ==================${NC}"
    cd ~
    sudo apt-get install gnupg curl
    curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | sudo gpg -o /usr/share/keyrings/mongodb-server-8.0.gpg --dearmor
    echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] https://repo.mongodb.org/apt/ubuntu noble/mongodb-org/8.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list
    sudo apt-get update
    apt install -y mongodb-org
    systemctl enable --now mongod
    mongo --eval 'db.runCommand({ connectionStatus: 1 })'
    echo -e "${GREEN}================== Sukses MongoDB ==================${NC}"
else
    echo -e "${GREEN}MongoDB sudah terinstall sebelumnya.${NC}"
fi

# Cek versi NodeJS
check_node_version() {
    if command -v node > /dev/null 2>&1; then
        NODE_VERSION=$(node -v | cut -d 'v' -f 2)
        NODE_MAJOR=$(echo $NODE_VERSION | cut -d '.' -f 1)
        NODE_MINOR=$(echo $NODE_VERSION | cut -d '.' -f 2)
        if [ "$NODE_MAJOR" -lt 12 ] || { [ "$NODE_MAJOR" -eq 12 ] && [ "$NODE_MINOR" -lt 13 ]; } || [ "$NODE_MAJOR" -gt 22 ]; then
            return 1
        else
            return 0
        fi
    else
        return 1
    fi
}

# Install NodeJS
if ! check_node_version; then
    echo -e "${GREEN}================== Menginstall NodeJS ==================${NC}"
    curl -fsSL https://deb.nodesource.com/setup_22.x -o nodesource_setup.sh
    sudo -E bash nodesource_setup.sh
    sudo apt-get install -y nodejs npm
    rm nodesource_setup.sh

    if ! dpkg -s libssl1.1 >/dev/null 2>&1; then
        echo "deb http://security.ubuntu.com/ubuntu impish-security main" | tee /etc/apt/sources.list.d/impish-security.list
        apt update
        apt install -y libssl1.1
    fi

    echo -e "${GREEN}================== Sukses NodeJS ==================${NC}"
else
    NODE_VERSION=$(node -v)
    echo -e "${GREEN}NodeJS sudah terinstall versi ${NODE_VERSION}, lanjut...${NC}"
fi

# Install GenieACS
if ! systemctl is-active --quiet genieacs-cwmp; then
    echo -e "${GREEN}================== Menginstall GenieACS ==================${NC}"
    if ! npm install -g genieacs@1.2.13; then
        echo -e "${RED}❌ Gagal menginstal GenieACS.${NC}"
        exit 1
    fi

    useradd --system --no-create-home --user-group genieacs || true
    mkdir -p /opt/genieacs/ext
    mkdir -p /var/log/genieacs
    chown -R genieacs:genieacs /opt/genieacs /var/log/genieacs

    cat << EOF > /opt/genieacs/genieacs.env
GENIEACS_CWMP_ACCESS_LOG_FILE=/var/log/genieacs/genieacs-cwmp-access.log
GENIEACS_NBI_ACCESS_LOG_FILE=/var/log/genieacs/genieacs-nbi-access.log
GENIEACS_FS_ACCESS_LOG_FILE=/var/log/genieacs/genieacs-fs-access.log
GENIEACS_UI_ACCESS_LOG_FILE=/var/log/genieacs/genieacs-ui-access.log
GENIEACS_DEBUG_FILE=/var/log/genieacs/genieacs-debug.yaml
GENIEACS_EXT_DIR=/opt/genieacs/ext
GENIEACS_UI_JWT_SECRET=secret
EOF

    chmod 600 /opt/genieacs/genieacs.env
    chown genieacs:genieacs /opt/genieacs/genieacs.env

    # Buat service
    for service in cwmp nbi fs ui; do
        cat << EOF > /etc/systemd/system/genieacs-${service}.service
[Unit]
Description=GenieACS ${service^^}
After=network.target

[Service]
User=genieacs
EnvironmentFile=/opt/genieacs/genieacs.env
ExecStart=/usr/bin/genieacs-${service}

[Install]
WantedBy=default.target
EOF
    done

    # Konfigurasi logrotate
    cat << EOF > /etc/logrotate.d/genieacs
/var/log/genieacs/*.log /var/log/genieacs/*.yaml {
    daily
    rotate 30
    compress
    delaycompress
    dateext
}
EOF

    systemctl daemon-reload
    systemctl enable --now genieacs-{cwmp,nbi,fs,ui}
    echo -e "${GREEN}================== GenieACS berhasil dijalankan ==================${NC}"
else
    echo -e "${GREEN}GenieACS sudah terinstall sebelumnya.${NC}"
fi

# Sukses instalasi
echo -e "${GREEN}============================================================================${NC}"
echo -e "${GREEN}Akses UI GenieACS: http://$local_ip:3000${NC}"
echo -e "${GREEN}Whatsapp Support: 081-336-128-448${NC}"
echo -e "${GREEN}============================================================================${NC}"

# Restore DB Parameter
echo -e "${GREEN}Sekarang install parameter. Apakah anda ingin melanjutkan? (y/n)${NC}"
read confirmation

if [ "$confirmation" != "y" ]; then
    echo -e "${GREEN}Install dibatalkan..${NC}"
    exit 1
fi

for ((i = 5; i >= 1; i--)); do
    sleep 1
    echo "Lanjut Install Parameter $i. Tekan ctrl+c untuk membatalkan"
done

cd ~

if [ -d "new-genieASU" ]; then
    mongorestore --db=genieacs --drop www.salbiyah.my.id:2002/genieacs/genieacs/
    rm -rf new-genieASU
    echo -e "${GREEN}Database parameter berhasil di-restore.${NC}"
else
    echo -e "${RED}❌ Folder 'new-genieASU' tidak ditemukan. Lewati restore.${NC}"
fi
