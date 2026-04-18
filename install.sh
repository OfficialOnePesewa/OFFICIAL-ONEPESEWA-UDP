#!/bin/bash
# OFFICIAL ONEPESEWA DUAL PROTOCOL INSTALLER
# ZIVPN (port 5667) + UDP Custom (port 36712) — no port conflicts
# Supports: Debian 10/11/12 | Ubuntu 20.04/22.04/24.04 | x86_64 | ARM64
# One-liner: bash <(curl -fsSL https://raw.githubusercontent.com/OfficialOnePesewa/OFFICIAL-ONEPESEWA-UDP/main/install.sh)

set -e

G='\e[1;32m' R='\e[1;31m' Y='\e[1;33m' C='\e[1;36m' W='\e[1;37m' NC='\e[0m'

[ "$EUID" -ne 0 ] && echo -e "${R}[!] Run as root.${NC}" && exit 1

# ── Banner ──────────────────────────────────────────────────────────────────
clear
echo -e "${C}"
echo "  ██████╗ ██████╗     ██╗   ██╗██████╗ ██████╗     ██████╗  █████╗ ███╗   ██╗███████╗██╗"
echo " ██╔═══██╗██╔══██╗    ██║   ██║██╔══██╗██╔══██╗    ██╔══██╗██╔══██╗████╗  ██║██╔════╝██║"
echo " ██║   ██║██████╔╝    ██║   ██║██║  ██║██████╔╝    ██████╔╝███████║██╔██╗ ██║█████╗  ██║"
echo " ██║   ██║██╔═══╝     ██║   ██║██║  ██║██╔═══╝     ██╔═══╝ ██╔══██║██║╚██╗██║██╔══╝  ██║"
echo " ╚██████╔╝██║         ╚██████╔╝██████╔╝██║         ██║     ██║  ██║██║ ╚████║███████╗███████╗"
echo "  ╚═════╝ ╚═╝          ╚═════╝ ╚═════╝ ╚═╝         ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═══╝╚══════╝╚══════╝"
echo -e "${NC}"
echo "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "  ${Y}Dual Protocol UDP Installer — ZIVPN + UDP Custom${NC}"
echo "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ── Geo detection ────────────────────────────────────────────────────────────
echo -e "\n${Y}[*] Detecting server info...${NC}"
GEO=$(curl -4 -s --max-time 8 "https://ipapi.co/json/" 2>/dev/null)
if echo "$GEO" | grep -q '"ip"'; then
    IP=$(echo "$GEO"     | grep -oP '"ip":\s*"\K[^"]+')
    CITY=$(echo "$GEO"   | grep -oP '"city":\s*"\K[^"]+')
    COUNTRY=$(echo "$GEO"| grep -oP '"country_name":\s*"\K[^"]+')
    ISP=$(echo "$GEO"    | grep -oP '"org":\s*"\K[^"]+')
else
    IP=$(curl -4 -s --max-time 5 ifconfig.me 2>/dev/null || echo "N/A")
    CITY="Unknown"; COUNTRY="Unknown"; ISP="Unknown"
fi
[ -z "$IP" ]      && IP="N/A"
[ -z "$CITY" ]    && CITY="Unknown"
[ -z "$COUNTRY" ] && COUNTRY="Unknown"
[ -z "$ISP" ]     && ISP="Unknown"

OS=$(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)
ARCH=$(uname -m)

echo ""
echo "  OS       : $OS ($ARCH)"
echo "  Location : $CITY, $COUNTRY"
echo "  IP       : $IP"
echo "  ISP      : $ISP"
echo ""

# ── Stop old services ────────────────────────────────────────────────────────
systemctl stop zivpn       2>/dev/null || true
systemctl stop udp-custom  2>/dev/null || true
systemctl disable zivpn    2>/dev/null || true
systemctl disable udp-custom 2>/dev/null || true

# ── [STEP 1] Install system dependencies ────────────────────────────────────
echo -e "${Y}[1/6] Installing system dependencies...${NC}"
apt-get update -qq
apt-get install -y -qq curl wget jq iptables-persistent netfilter-persistent \
    openssl vnstat bc python3 python3-pip unzip ca-certificates

# ── [STEP 2] Install ZIVPN ──────────────────────────────────────────────────
echo -e "${Y}[2/6] Installing ZIVPN (port 5667, NAT 6001-19999)...${NC}"

case $ARCH in
    x86_64|amd64)  BIN_SUFFIX="amd64" ;;
    aarch64|arm64) BIN_SUFFIX="arm64" ;;
    armv7l)        BIN_SUFFIX="arm"   ;;
    *)  echo -e "${R}[!] Unsupported architecture: $ARCH${NC}"; exit 1 ;;
esac

rm -f /usr/local/bin/zivpn
ZIVPN_URL="https://github.com/zahidbd2/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-$BIN_SUFFIX"
echo -e "  Downloading ZIVPN binary..."
wget -q --show-progress -O /usr/local/bin/zivpn "$ZIVPN_URL" || {
    echo -e "${R}[!] ZIVPN download failed.${NC}"; exit 1
}
chmod +x /usr/local/bin/zivpn

if ! file /usr/local/bin/zivpn 2>/dev/null | grep -qE "ELF|executable"; then
    echo -e "${R}[!] ZIVPN binary is invalid (download may have failed).${NC}"; exit 1
fi

mkdir -p /etc/zivpn

if [ ! -f /etc/zivpn/zivpn.crt ]; then
    echo -e "  Generating ZIVPN SSL certificate..."
    openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 \
        -subj "/C=GH/ST=Accra/L=Accra/O=OnePesewa/CN=onepesewa" \
        -keyout "/etc/zivpn/zivpn.key" \
        -out    "/etc/zivpn/zivpn.crt" 2>/dev/null
fi

cat > /etc/zivpn/config.json <<'EOF'
{
  "listen": ":5667",
  "cert":   "/etc/zivpn/zivpn.crt",
  "key":    "/etc/zivpn/zivpn.key",
  "obfs":   "onepesewa",
  "auth": {
    "mode":   "passwords",
    "config": []
  }
}
EOF

touch /etc/zivpn/users.db /etc/zivpn/usage.db \
      /etc/zivpn/telegram.db /etc/zivpn/admins.db

cat > /etc/systemd/system/zivpn.service <<'EOF'
[Unit]
Description=ZIVPN UDP Server (OnePesewa)
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/zivpn server -c /etc/zivpn/config.json
Restart=always
RestartSec=3
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOF

echo -e "${G}  ✔ ZIVPN installed — port 5667${NC}"

# ── [STEP 3] Install UDP Custom ─────────────────────────────────────────────
echo -e "${Y}[3/6] Installing UDP Custom (port 36712)...${NC}"

UDPC_DIR="/root/udp"
mkdir -p "$UDPC_DIR"

UDPC_PORT=36712
UDPC_GATEWAY=7300

echo -e "  Downloading UDP Custom binary..."
UDPC_URLS=(
    "https://github.com/http-custom/udp-custom/releases/latest/download/udp-custom-linux-$BIN_SUFFIX"
    "https://github.com/http-custom/udp-custom/releases/download/v1.0.0/udp-custom-linux-$BIN_SUFFIX"
    "https://github.com/http-custom/udp-custom/releases/download/v2.0.0/udp-custom-linux-$BIN_SUFFIX"
)

UDPC_OK=0
for url in "${UDPC_URLS[@]}"; do
    echo -e "  Trying: $url"
    if wget -q --show-progress -O "$UDPC_DIR/udp-custom" "$url" 2>/dev/null; then
        if file "$UDPC_DIR/udp-custom" 2>/dev/null | grep -qE "ELF|executable"; then
            UDPC_OK=1
            break
        else
            echo -e "  ${Y}  ↳ Not a valid binary, trying next...${NC}"
            rm -f "$UDPC_DIR/udp-custom"
        fi
    fi
done

if [ "$UDPC_OK" -eq 0 ]; then
    echo -e "${Y}    Attempting to build from source as fallback...${NC}"
    apt-get install -y -qq golang-go git 2>/dev/null || true
    if command -v go &>/dev/null; then
        rm -rf /tmp/udp-custom-src
        git clone --depth 1 https://github.com/http-custom/udp-custom /tmp/udp-custom-src 2>/dev/null && \
        cd /tmp/udp-custom-src && \
        go build -o "$UDPC_DIR/udp-custom" . && \
        cd / && rm -rf /tmp/udp-custom-src || true
        [ -f "$UDPC_DIR/udp-custom" ] && UDPC_OK=1
    fi
fi

if [ "$UDPC_OK" -eq 1 ]; then
    chmod +x "$UDPC_DIR/udp-custom"

    if [ ! -f "$UDPC_DIR/server.crt" ]; then
        echo -e "  Generating UDP Custom SSL certificate..."
        openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 \
            -subj "/C=GH/ST=Accra/L=Accra/O=OnePesewa/CN=udp-custom" \
            -keyout "$UDPC_DIR/server.key" \
            -out    "$UDPC_DIR/server.crt" 2>/dev/null
    fi

    cat > "$UDPC_DIR/config.json" <<EOF
{
  "listen":  ":$UDPC_PORT",
  "cert":    "$UDPC_DIR/server.crt",
  "key":     "$UDPC_DIR/server.key",
  "auth": {
    "mode":   "passwords",
    "config": []
  }
}
EOF

    [ ! -f "$UDPC_DIR/users.json" ] && echo '{}' > "$UDPC_DIR/users.json"
    echo "$UDPC_PORT" > "$UDPC_DIR/udp_port.txt"

    cat > /etc/systemd/system/udp-custom.service <<EOF
[Unit]
Description=UDP Custom Server (OnePesewa)
After=network.target

[Service]
Type=simple
WorkingDirectory=$UDPC_DIR
ExecStart=$UDPC_DIR/udp-custom server -c $UDPC_DIR/config.json
Restart=always
RestartSec=3
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOF

    echo -e "${G}  ✔ UDP Custom installed — port $UDPC_PORT${NC}"
else
    echo -e "${R}  ✘ UDP Custom installation failed. ZIVPN will still work.${NC}"
    UDPC_PORT="N/A"
fi

# ── [STEP 4] Firewall rules ──────────────────────────────────────────────────
echo -e "${Y}[4/6] Configuring firewall...${NC}"

iptables -I INPUT -p udp --dport 5667          -j ACCEPT 2>/dev/null || true
iptables -I INPUT -p udp --dport 6001:19999    -j ACCEPT 2>/dev/null || true
iptables -t nat -A PREROUTING -p udp --dport 6001:19999 \
    -j DNAT --to-destination :5667             2>/dev/null || true

if [ "$UDPC_OK" -eq 1 ]; then
    iptables -I INPUT -p udp --dport "$UDPC_PORT"    -j ACCEPT 2>/dev/null || true
    iptables -I INPUT -p tcp --dport "$UDPC_PORT"    -j ACCEPT 2>/dev/null || true
    iptables -I INPUT -p udp --dport "$UDPC_GATEWAY" -j ACCEPT 2>/dev/null || true
    iptables -I INPUT -p tcp --dport "$UDPC_GATEWAY" -j ACCEPT 2>/dev/null || true
fi

iptables -I INPUT -p tcp --dport 22  -j ACCEPT 2>/dev/null || true
iptables -I INPUT -p tcp --dport 80  -j ACCEPT 2>/dev/null || true
iptables -I INPUT -p tcp --dport 443 -j ACCEPT 2>/dev/null || true

netfilter-persistent save 2>/dev/null || \
    iptables-save > /etc/iptables/rules.v4 2>/dev/null || true

echo -e "${G}  ✔ Firewall configured${NC}"

# ── [STEP 5] Install Panel ──────────────────────────────────────────────────
echo -e "${Y}[5/6] Installing OP UDP Panel...${NC}"

PANEL_URL="https://raw.githubusercontent.com/OfficialOnePesewa/OFFICIAL-ONEPESEWA-UDP/main/onepesewa"
for attempt in 1 2 3; do
    wget -qO /usr/local/bin/onepesewa "$PANEL_URL" && break
    echo -e "  ${Y}Retry $attempt...${NC}"
    sleep 2
done
chmod +x /usr/local/bin/onepesewa
ln -sf /usr/local/bin/onepesewa /usr/local/bin/udp
ln -sf /usr/local/bin/onepesewa /usr/local/bin/panel

echo -e "${G}  ✔ Panel installed — type 'onepesewa' or 'panel' to open${NC}"

# ── [STEP 6] Start Services ─────────────────────────────────────────────────
echo -e "${Y}[6/6] Starting services...${NC}"
systemctl daemon-reload

systemctl enable zivpn
systemctl start  zivpn

if [ "$UDPC_OK" -eq 1 ]; then
    systemctl enable udp-custom
    systemctl start  udp-custom
fi

sleep 4

# ── Summary ──────────────────────────────────────────────────────────────────
echo ""
echo -e "${C}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${C}║          INSTALLATION COMPLETE — OP UDP PANEL        ║${NC}"
echo -e "${C}╠══════════════════════════════════════════════════════╣${NC}"
echo -e "${C}║${NC}  Server IP    : ${W}$IP${NC}"
echo -e "${C}║${NC}  Location     : ${W}$CITY, $COUNTRY${NC}"
echo -e "${C}║${NC}  ISP          : ${W}$ISP${NC}"
echo -e "${C}╠══════════════════════════════════════════════════════╣${NC}"
echo -e "${C}║${NC}  ZIVPN        : ${W}port 5667  (NAT 6001–19999)${NC}"
echo -e "${C}║${NC}  UDP Custom   : ${W}port $UDPC_PORT${NC}"
echo -e "${C}╠══════════════════════════════════════════════════════╣${NC}"
echo -e "${C}║${NC}  ZIVPN files  : ${W}/etc/zivpn/${NC}"
echo -e "${C}║${NC}  UDPC files   : ${W}/root/udp/${NC}"
echo -e "${C}║${NC}  Panel binary : ${W}/usr/local/bin/onepesewa${NC}"
echo -e "${C}╠══════════════════════════════════════════════════════╣${NC}"

ZIVPN_OK=0; UDPC_SVC_OK=0
systemctl is-active --quiet zivpn      && ZIVPN_OK=1
systemctl is-active --quiet udp-custom && UDPC_SVC_OK=1

[ $ZIVPN_OK    -eq 1 ] && echo -e "${C}║${NC}  ${G}✅ ZIVPN       : running${NC}" \
                       || echo -e "${C}║${NC}  ${R}❌ ZIVPN       : FAILED — check: journalctl -u zivpn${NC}"
[ "$UDPC_OK"   -eq 1 ] && {
    [ $UDPC_SVC_OK -eq 1 ] && echo -e "${C}║${NC}  ${G}✅ UDP Custom  : running${NC}" \
                           || echo -e "${C}║${NC}  ${R}❌ UDP Custom  : FAILED — check: journalctl -u udp-custom${NC}"
}
echo -e "${C}╚══════════════════════════════════════════════════════╝${NC}"
echo -e "${Y}  Type 'onepesewa' to open the control panel.${NC}"
echo ""
