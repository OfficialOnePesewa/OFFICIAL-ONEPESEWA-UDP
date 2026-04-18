#!/bin/bash
# OFFICIAL ONEPESEWA ZIVPN INSTALLER – With Device Binding Proxy
set -e

G='\e[1;32m' R='\e[1;31m' Y='\e[1;33m' C='\e[1;36m' NC='\e[0m'
ADMIN_HANDLE="@OfficialOnePesewa"

[ "$EUID" -ne 0 ] && echo -e "${R}Run as root.${NC}" && exit 1

echo -e "${Y}[+] Updating system & installing dependencies...${NC}"
apt-get update -qq
apt-get install -y -qq curl wget jq iptables-persistent netfilter-persistent openssl vnstat bc python3 python3-pip git unzip screen

OS=$(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)
echo -e "${G}[+] OS: $OS${NC}"

GEO=$(curl -4 -s --max-time 8 https://ipapi.co/json/ 2>/dev/null)
if [ -z "$GEO" ] || ! echo "$GEO" | grep -q '"ip"'; then
    IP="N/A"; CITY="Unknown"; COUNTRY="Unknown"; ISP="Unknown"
else
    IP=$(echo "$GEO" | grep -oP '"ip":\s*"\K[^"]+')
    CITY=$(echo "$GEO" | grep -oP '"city":\s*"\K[^"]+')
    COUNTRY=$(echo "$GEO" | grep -oP '"country_name":\s*"\K[^"]+')
    ISP=$(echo "$GEO" | grep -oP '"org":\s*"\K[^"]+')
    [ -z "$IP" ] && IP="N/A"
    [ -z "$CITY" ] && CITY="Unknown"
    [ -z "$COUNTRY" ] && COUNTRY="Unknown"
    [ -z "$ISP" ] && ISP="Unknown"
fi

clear
echo -e "${G}"
echo "   ___  _   _ ______ _____  ______ ______ _    _ ______          _    _ ______ _____  "
echo "  / _ \| \ | |  ____|  __ \|  ____|  ____| |  | |  ____|   /\   | |  | |  __ \|  __ \ "
echo " | | | |  \| | |__  | |__) | |__  | |__  | |  | | |__     /  \  | |  | | |__) | |__) |"
echo " | | | |     |  __| |  ___/|  __| |  __| | |  | |  __|   / /\ \ | |  | |  ___/|  ___/ "
echo " | |_| | |\  | |____| |    | |____| |____| |__| | |____ / ____ \| |__| | |    | |     "
echo "  \___/|_| \_|______|_|    |______|______|\____/|______/_/    \_\\____/|_|    |_|     "
echo -e "${NC}"
echo "---------------------------------------------------"
echo "  OS       : $OS"
echo "  Location : $CITY, $COUNTRY"
echo "  IP       : $IP"
echo "  ISP      : $ISP"
echo "  Admin    : $ADMIN_HANDLE"
echo "---------------------------------------------------"

systemctl stop zivpn 2>/dev/null || true
systemctl stop zivpn-proxy 2>/dev/null || true
systemctl stop badvpn-gateway 2>/dev/null || true

# ------------------ VPS Optimizer ------------------
echo -e "${Y}[1/5] Applying VPS network optimizations...${NC}"
wget -qO /usr/local/bin/optimize.sh https://raw.githubusercontent.com/OfficialOnePesewa/OFFICIAL-ONEPESEWA-UDP/main/optimize.sh
chmod +x /usr/local/bin/optimize.sh
bash /usr/local/bin/optimize.sh

# ------------------ Install ZIVPN (Internal Port 5668) ------------------
echo -e "${Y}[2/5] Installing ZIVPN...${NC}"
ARCH=$(uname -m)
case $ARCH in
    x86_64|amd64) BIN="amd64" ;;
    aarch64|arm64) BIN="arm64" ;;
    *) echo -e "${R}Unsupported: $ARCH${NC}"; exit 1 ;;
esac

rm -f /usr/local/bin/zivpn
wget -q --show-progress -O /usr/local/bin/zivpn \
    "https://github.com/zahidbd2/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-$BIN"
chmod +x /usr/local/bin/zivpn

mkdir -p /etc/zivpn
cat <<EOF > /etc/zivpn/config.json
{
  "listen": ":5668",
  "cert": "/etc/zivpn/zivpn.crt",
  "key": "/etc/zivpn/zivpn.key",
  "obfs": "onepesewa",
  "auth": {
    "mode": "passwords",
    "config": []
  }
}
EOF
touch /etc/zivpn/users.db /etc/zivpn/usage.db /etc/zivpn/telegram.db /etc/zivpn/admins.db /etc/zivpn/bindings.json
echo '{}' > /etc/zivpn/bindings.json

openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 \
    -subj "/C=GH/ST=Accra/L=Accra/O=OnePesewa/CN=onepesewa" \
    -keyout "/etc/zivpn/zivpn.key" -out "/etc/zivpn/zivpn.crt" 2>/dev/null

cat <<EOF > /etc/systemd/system/zivpn.service
[Unit]
Description=ZIVPN UDP Server (Internal)
After=network.target

[Service]
ExecStart=/usr/local/bin/zivpn server -c /etc/zivpn/config.json
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# ------------------ Install Device Binding Proxy ------------------
echo -e "${Y}[3/5] Installing Device Binding Proxy...${NC}"
PROXY_URL="https://raw.githubusercontent.com/OfficialOnePesewa/OFFICIAL-ONEPESEWA-UDP/main/bin/zivpn-proxy"
wget -qO /usr/local/bin/zivpn-proxy "$PROXY_URL"
chmod +x /usr/local/bin/zivpn-proxy

if [ ! -s /usr/local/bin/zivpn-proxy ]; then
    echo -e "${R}[✗] Failed to download proxy binary.${NC}"
    exit 1
fi
echo -e "${G}[✓] Proxy binary ready ($(stat -c%s /usr/local/bin/zivpn-proxy) bytes)${NC}"

cat <<EOF > /etc/systemd/system/zivpn-proxy.service
[Unit]
Description=ZIVPN Device Binding Proxy
After=network.target zivpn.service

[Service]
Type=simple
ExecStart=/usr/local/bin/zivpn-proxy --listen :5667 --backend :5668 --bindings /etc/zivpn/bindings.json
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# ------------------ Firewall (SSH Protected) ------------------
echo -e "${Y}[4/5] Configuring firewall...${NC}"
iptables -I INPUT -p tcp --dport 22 -j ACCEPT
iptables -I INPUT -p udp --dport 5667 -j ACCEPT 2>/dev/null || true
iptables -I INPUT -p udp --dport 5668 -s 127.0.0.1 -j ACCEPT 2>/dev/null || true
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

netfilter-persistent save 2>/dev/null || iptables-save > /etc/iptables/rules.v4 2>/dev/null || true

# ------------------ Install Panel ------------------
echo -e "${Y}[5/5] Installing OP UDP Panel...${NC}"
wget -qO /usr/local/bin/onepesewa https://raw.githubusercontent.com/OfficialOnePesewa/OFFICIAL-ONEPESEWA-UDP/main/onepesewa
chmod +x /usr/local/bin/onepesewa
ln -sf /usr/local/bin/onepesewa /usr/local/bin/udp

# ------------------ Telegram Bot (Optional) ------------------
set +e
pip3 install --quiet python-telegram-bot==20.3 2>/dev/null || \
pip3 install --break-system-packages --quiet python-telegram-bot==20.3 2>/dev/null || true
set -e

wget -qO /usr/local/bin/opudp_bot.py https://raw.githubusercontent.com/OfficialOnePesewa/OFFICIAL-ONEPESEWA-UDP/main/opudp_bot.py
chmod +x /usr/local/bin/opudp_bot.py

cat <<EOF > /etc/systemd/system/opudp-bot.service
[Unit]
Description=OP UDP Telegram Bot
After=network.target

[Service]
ExecStart=/usr/bin/python3 /usr/local/bin/opudp_bot.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

if python3 -c "import telegram" 2>/dev/null; then
    systemctl enable opudp-bot
    systemctl start opudp-bot 2>/dev/null || true
fi

# ------------------ Start Services ------------------
systemctl daemon-reload
systemctl enable zivpn zivpn-proxy
systemctl start zivpn
systemctl start zivpn-proxy

sleep 5

echo -e "\n${C}====================================================${NC}"
echo -e "${G}         INSTALLATION COMPLETE!${NC}"
echo -e "${C}====================================================${NC}"
echo -e "${G} Server IP   :${NC} $IP"
echo -e "${G} Location    :${NC} $CITY, $COUNTRY"
echo -e "${G} ISP         :${NC} $ISP"
echo -e "${G} ZIVPN Proxy :${NC} 5667 (internal ZIVPN: 5668)"
echo -e "${C}====================================================${NC}"

if systemctl is-active --quiet zivpn; then
    echo -e "${G}✅ ZIVPN (internal) is running${NC}"
else
    echo -e "${R}❌ ZIVPN failed to start.${NC}"
fi

if systemctl is-active --quiet zivpn-proxy; then
    echo -e "${G}✅ Device Binding Proxy is running${NC}"
else
    echo -e "${R}❌ Proxy failed to start.${NC}"
fi

echo -e "${C}====================================================${NC}"
echo -e "${Y} Type 'onepesewa' to open the control panel.${NC}"
echo -e "${C}====================================================${NC}"
