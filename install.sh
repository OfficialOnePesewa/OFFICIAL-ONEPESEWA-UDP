#!/bin/bash
# ZIVPN UDP Installer by @OfficialOnePesewa
# Support: https://t.me/OfficialOnePesewa

# --- Root Check ---
if [ "$EUID" -ne 0 ]; then
    echo -e "\e[1;31mPlease run as root.\e[0m"
    exit 1
fi

# --- Colors ---
G="\e[1;32m"
R="\e[1;31m"
Y="\e[1;33m"
C="\e[1;36m"
NC="\e[0m"

# --- OS Detection ---
OS=$(grep "PRETTY_NAME" /etc/os-release | cut -d '"' -f 2)
DATE=$(date +"%Y-%m-%d %H:%M:%S")

# --- Geo-IP with fallback ---
echo -e "${Y}Fetching server info...${NC}"
GEO=$(curl -4 -s --max-time 8 "https://ipapi.co/json/" 2>/dev/null)
IP=$(echo "$GEO" | grep -oP '"ip":\s*"\K[^"]+')

if [ -z "$IP" ]; then
    GEO=$(curl -4 -s --max-time 8 "http://ip-api.com/json/" 2>/dev/null)
    IP=$(echo "$GEO"      | grep -oP '"query":\s*"\K[^"]+')
    CITY=$(echo "$GEO"    | grep -oP '"city":\s*"\K[^"]+')
    COUNTRY=$(echo "$GEO" | grep -oP '"country":\s*"\K[^"]+')
    ISP=$(echo "$GEO"     | grep -oP '"isp":\s*"\K[^"]+')
else
    CITY=$(echo "$GEO"    | grep -oP '"city":\s*"\K[^"]+')
    COUNTRY=$(echo "$GEO" | grep -oP '"country_name":\s*"\K[^"]+')
    ISP=$(echo "$GEO"     | grep -oP '"org":\s*"\K[^"]+')
fi

[ -z "$IP" ]      && IP="N/A"
[ -z "$CITY" ]    && CITY="Unknown"
[ -z "$COUNTRY" ] && COUNTRY="Unknown"
[ -z "$ISP" ]     && ISP="Unknown"

LOC="${CITY}, ${COUNTRY}"

# --- Banner ---
clear
echo -e "${G}"
echo "  ____  _____  _   _ _____  ____  "
echo " / __ \|  __ \| | | |  __ \|  _ \ "
echo "| |  | | |__) | | | | |  | | |_) |"
echo "| |  | |  ___/| | | | |  | |  __/ "
echo "| |__| | |    | |_| | |__| | |    "
echo " \____/|_|     \___/|_____/|_|    "
echo -e "${NC}"
echo "---------------------------------------------------"
echo "  OS       : $OS"
echo "  Location : $LOC"
echo "  IP       : $IP"
echo "  ISP      : $ISP"
echo "  Admin    : @OfficialOnePesewa"
echo "  Date     : $DATE"
echo "---------------------------------------------------"
echo ""

# --- Dependencies ---
echo -e "${Y}[1/6] Installing dependencies...${NC}"
apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install -y \
    jq wget curl iptables iptables-persistent netfilter-persistent openssl vnstat bc

# --- Architecture Detection ---
echo -e "${Y}[2/6] Detecting architecture...${NC}"
ARCH=$(uname -m)
case $ARCH in
    x86_64)  BIN="amd64" ;;
    aarch64) BIN="arm64" ;;
    *) echo -e "${R}Unsupported architecture: $ARCH${NC}"; exit 1 ;;
esac

# --- ZIVPN Binary Download ---
echo -e "${Y}[3/6] Downloading ZIVPN binary ($BIN)...${NC}"
wget -q --show-progress -O /usr/local/bin/zivpn \
    "https://github.com/zahidbd2/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-$BIN" || {
    echo -e "${R}Failed to download ZIVPN binary. Check your internet connection.${NC}"
    exit 1
}
chmod +x /usr/local/bin/zivpn

# --- Config & Database ---
echo -e "${Y}[4/6] Setting up config and database...${NC}"
mkdir -p /etc/zivpn
cat <<EOF > /etc/zivpn/config.json
{
  "listen": ":5667",
  "cert": "/etc/zivpn/zivpn.crt",
  "key": "/etc/zivpn/zivpn.key",
  "obfs": "zivpn",
  "auth": {
    "mode": "passwords",
    "config": []
  }
}
EOF
touch /etc/zivpn/users.db

# --- SSL Certificate ---
echo -e "${Y}[5/6] Generating SSL certificate...${NC}"
openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 \
    -subj "/C=GH/ST=Accra/L=Accra/O=OnePesewa/CN=zivpn" \
    -keyout "/etc/zivpn/zivpn.key" \
    -out "/etc/zivpn/zivpn.crt" 2>/dev/null || {
    echo -e "${R}SSL certificate generation failed.${NC}"
    exit 1
}

# --- Firewall ---
echo -e "${Y}[6/6] Configuring firewall and creating systemd service...${NC}"

if command -v ufw &>/dev/null; then
    ufw disable &>/dev/null
fi

iptables -I INPUT -p tcp --dport 22 -j ACCEPT
iptables -I INPUT -p udp --dport 5667 -j ACCEPT
iptables -I INPUT -p udp --dport 6000:19999 -j ACCEPT
iptables -t nat -A PREROUTING -p udp --dport 6000:19999 -j DNAT --to-destination :5667

netfilter-persistent save

# --- Systemd Service ---
cat <<EOF > /etc/systemd/system/zivpn.service
[Unit]
Description=ZIVPN UDP Server
After=network.target

[Service]
ExecStart=/usr/local/bin/zivpn server -c /etc/zivpn/config.json
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable zivpn
systemctl start zivpn

# --- Install opudp Panel ---
echo -e "${Y}Installing opudp panel...${NC}"
wget -qO /usr/local/bin/opudp \
    https://raw.githubusercontent.com/OfficialOnePesewa/udp-zivpn/main/opudp || {
    echo -e "${R}Failed to download opudp panel.${NC}"
    exit 1
}
chmod +x /usr/local/bin/opudp

# --- Summary ---
echo ""
echo -e "${C}====================================================${NC}"
echo -e "${G}         INSTALLATION COMPLETE!${NC}"
echo -e "${C}====================================================${NC}"
echo -e "${G} Server IP  :${NC} $IP"
echo -e "${G} Location   :${NC} $LOC"
echo -e "${G} ISP        :${NC} $ISP"
echo -e "${G} ZIVPN Port :${NC} 5667 (UDP)"
echo -e "${G} NAT Range  :${NC} 6000 - 19999"
echo -e "${C}====================================================${NC}"
echo -e "${Y} Type 'opudp' to open the panel.${NC}"
echo -e "${C}====================================================${NC}"
echo ""
