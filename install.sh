#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║     OFFICIAL ONEPESEWA UDP Installer                        ║
# ║     Debian/Ubuntu  –  ZIVPN v1.4.9  –  @OfficialOnePesewa  ║
# ╚══════════════════════════════════════════════════════════════╝

set -e

# ── Colors ─────────────────────────────────────────────────────
RED='\e[1;31m' GRN='\e[1;32m' YLW='\e[1;33m' BLU='\e[1;34m'
MAG='\e[1;35m' CYN='\e[1;36m' WHT='\e[1;37m' RST='\e[0m'
BOLD='\e[1m'   DIM='\e[2m'

# ── Root check ─────────────────────────────────────────────────
[ "$EUID" -ne 0 ] && echo -e "${RED}Run as root.${RST}" && exit 1

# ══════════════════════════════════════════════════════════════
#  PIXEL ART LOGO  –  "OPUDP"  fire-gradient (matches panel)
# ══════════════════════════════════════════════════════════════
print_logo() {
    local COLS=(196 196 202 208 208 214 220 220)
    local INDENT="        "
    local GAP="   "

    local O0="11111" O1="10001" O2="10001" O3="10001" O4="10001" O5="10001" O6="10001" O7="11111"
    local P0="11110" P1="10001" P2="10001" P3="11110" P4="10000" P5="10000" P6="10000" P7="10000"
    local U0="10001" U1="10001" U2="10001" U3="10001" U4="10001" U5="10001" U6="10001" U7="11111"
    local D0="11110" D1="10001" D2="10001" D3="10001" D4="10001" D5="10001" D6="10001" D7="11110"

    local letters=("O" "P" "U" "D" "P")

    echo ""
    for row in 0 1 2 3 4 5 6 7; do
        local col="${COLS[$row]}"
        printf "%s" "$INDENT"
        for ltr in "${letters[@]}"; do
            local varname="${ltr}${row}"
            local bits="${!varname}"
            for (( i=0; i<5; i++ )); do
                if [[ "${bits:$i:1}" == "1" ]]; then
                    printf "\e[38;5;${col}m\e[48;5;${col}m█\e[0m"
                else
                    printf " "
                fi
            done
            printf "%s" "$GAP"
        done
        echo ""
    done
    echo ""
}

step() {
    local num="$1" total="$2" msg="$3"
    echo -e "\n  ${CYN}${BOLD}[${num}/${total}]${RST}  ${WHT}${msg}${RST}"
    echo -e "  ${DIM}────────────────────────────────────────────────${RST}"
}

ok()   { echo -e "  ${GRN}✔  $*${RST}"; }
warn() { echo -e "  ${YLW}⚠  $*${RST}"; }
err()  { echo -e "  ${RED}✘  $*${RST}"; }
info() { echo -e "  ${DIM}   $*${RST}"; }

# ── Bootstrap: curl + wget ─────────────────────────────────────
echo -e "${DIM}Bootstrapping...${RST}"
apt-get update -qq
apt-get install -y -qq curl wget

# ── OS detection ───────────────────────────────────────────────
OS=$(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d'"' -f2 || uname -o)

# ── Geo fetch with dual-API fallback ──────────────────────────
printf "${DIM}  Fetching server location...${RST}\r"
GEO=""
for api in \
    "https://ipapi.co/json/" \
    "https://ip-api.com/json/?fields=status,message,country,countryCode,city,zip,isp,query" \
    "https://ipinfo.io/json"; do
    GEO=$(curl -4 -s --max-time 8 "$api" 2>/dev/null)
    [ -n "$GEO" ] && echo "$GEO" | grep -qE '"ip"|"query"' && break
    GEO=""
done
printf "\r\033[K"

if [ -z "$GEO" ]; then
    IP="N/A"; CITY="Unknown"; COUNTRY="Unknown"; ISP="Unknown"; COUNTRY_CODE=""
else
    IP=$(echo "$GEO"      | grep -oP '"(?:ip|query)":\s*"\K[^"]+' | head -1)
    CITY=$(echo "$GEO"    | grep -oP '"city":\s*"\K[^"]+')
    COUNTRY=$(echo "$GEO" | grep -oP '"(?:country_name|country)":\s*"\K[^"]+' | head -1)
    ISP=$(echo "$GEO"     | grep -oP '"(?:org|isp)":\s*"\K[^"]+' | head -1)
    [ -z "$IP" ]      && IP="N/A"
    [ -z "$CITY" ]    && CITY="Unknown"
    [ -z "$COUNTRY" ] && COUNTRY="Unknown"
    [ -z "$ISP" ]     && ISP="Unknown"
fi
LOC="$CITY, $COUNTRY"

# ══════════════════════════════════════════════════════════════
#  BANNER
# ══════════════════════════════════════════════════════════════
clear
print_logo

echo -e "   ${DIM}${WHT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RST}"
printf  "   ${CYN}${BOLD}  OP UDP VPS PANEL  –  Installer${RST}  ${DIM}|  @OfficialOnePesewa${RST}\n"
echo -e "   ${DIM}${WHT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RST}\n"

echo -e "  ${WHT}╭─────────────────────────────────────────────────────────────╮${RST}"
printf  "  ${WHT}│${RST}  ${CYN}🌐 IP       :${RST}  %-44s${WHT}│${RST}\n" "$IP"
printf  "  ${WHT}│${RST}  ${YLW}📍 Location :${RST}  %-44s${WHT}│${RST}\n" "$LOC"
printf  "  ${WHT}│${RST}  ${BLU}🏢 ISP      :${RST}  %-44s${WHT}│${RST}\n" "$ISP"
printf  "  ${WHT}│${RST}  ${GRN}💻 OS       :${RST}  %-44s${WHT}│${RST}\n" "$OS"
printf  "  ${WHT}│${RST}  ${MAG}👤 Admin    :${RST}  %-44s${WHT}│${RST}\n" "@OfficialOnePesewa"
echo -e "  ${WHT}╰─────────────────────────────────────────────────────────────╯${RST}\n"

# ══════════════════════════════════════════════════════════════
#  STEP 1 – Dependencies
# ══════════════════════════════════════════════════════════════
step 1 6 "Installing dependencies"
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    jq iptables-persistent netfilter-persistent openssl vnstat bc 2>/dev/null
ok "Dependencies installed"

# ══════════════════════════════════════════════════════════════
#  STEP 2 – Architecture detection
# ══════════════════════════════════════════════════════════════
step 2 6 "Detecting system architecture"
ARCH=$(uname -m)
case $ARCH in
    x86_64|amd64)   BIN="amd64" ;;
    aarch64|arm64)  BIN="arm64" ;;
    *)
        err "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac
ok "Architecture: ${ARCH} → ${BIN}"

# ══════════════════════════════════════════════════════════════
#  STEP 3 – Download ZIVPN binary
# ══════════════════════════════════════════════════════════════
step 3 6 "Downloading ZIVPN v1.4.9 binary"
systemctl stop zivpn 2>/dev/null || true
rm -f /usr/local/bin/zivpn

ZIVPN_URL="https://github.com/zahidbd2/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-${BIN}"
info "Source: $ZIVPN_URL"

if wget -q --show-progress -O /usr/local/bin/zivpn "$ZIVPN_URL"; then
    chmod +x /usr/local/bin/zivpn
    ok "ZIVPN binary installed → /usr/local/bin/zivpn"
else
    err "Failed to download ZIVPN binary."
    exit 1
fi

# ══════════════════════════════════════════════════════════════
#  STEP 4 – Config, SSL & kernel tuning
# ══════════════════════════════════════════════════════════════
step 4 6 "Setting up config, SSL certificate & kernel"

mkdir -p /etc/zivpn
touch /etc/zivpn/users.db /etc/zivpn/usage.db

# Write initial ZIVPN config if missing
if [ ! -f /etc/zivpn/config.json ]; then
    cat > /etc/zivpn/config.json <<'JSONEOF'
{
  "listen": ":5667",
  "cert": "/etc/zivpn/zivpn.crt",
  "key":  "/etc/zivpn/zivpn.key",
  "auth": {
    "mode": "passwords",
    "config": []
  }
}
JSONEOF
    ok "ZIVPN config created → /etc/zivpn/config.json"
else
    info "Existing config preserved."
fi

# SSL certificate
if [ ! -f /etc/zivpn/zivpn.crt ] || [ ! -f /etc/zivpn/zivpn.key ]; then
    openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 \
        -subj "/C=GH/ST=Accra/L=Accra/O=OnePesewa/CN=onepesewa" \
        -keyout /etc/zivpn/zivpn.key \
        -out    /etc/zivpn/zivpn.crt 2>/dev/null
    ok "SSL certificate generated (RSA 4096, 365 days)"
else
    info "Existing SSL cert preserved."
fi

# Kernel UDP performance tuning
sysctl -w net.core.rmem_max=67108864      >/dev/null 2>&1 || true
sysctl -w net.core.wmem_max=67108864      >/dev/null 2>&1 || true
sysctl -w net.core.rmem_default=16777216  >/dev/null 2>&1 || true
sysctl -w net.core.wmem_default=16777216  >/dev/null 2>&1 || true
sysctl -w net.ipv4.udp_mem="65536 131072 262144" >/dev/null 2>&1 || true
ok "Kernel UDP buffers tuned (64MB)"

# Persist sysctl across reboots
cat > /etc/sysctl.d/99-opudp.conf <<'SYSCTL'
net.core.rmem_max=67108864
net.core.wmem_max=67108864
net.core.rmem_default=16777216
net.core.wmem_default=16777216
net.ipv4.udp_mem=65536 131072 262144
SYSCTL
ok "Sysctl persisted → /etc/sysctl.d/99-opudp.conf"

# ══════════════════════════════════════════════════════════════
#  STEP 5 – Firewall / iptables
# ══════════════════════════════════════════════════════════════
step 5 6 "Configuring firewall"

# Disable UFW to avoid conflicts
command -v ufw &>/dev/null && ufw disable &>/dev/null && info "UFW disabled"

# Detect primary interface
INTERFACE=$(ip -4 route ls | grep default | grep -oP '(?<=dev )(\S+)' | head -1)
[ -z "$INTERFACE" ] && INTERFACE="eth0"
info "Primary interface: $INTERFACE"

# Core INPUT rules
iptables -I INPUT -p tcp  --dport 22           -j ACCEPT 2>/dev/null || true
iptables -I INPUT -p udp  --dport 5667         -j ACCEPT 2>/dev/null || true
iptables -I INPUT -p udp  --dport 5060         -j ACCEPT 2>/dev/null || true
iptables -I INPUT -p udp  --dport 7300         -j ACCEPT 2>/dev/null || true
iptables -I INPUT -p udp  --dport 6000:19999   -j ACCEPT 2>/dev/null || true

# NAT forwarding to ZIVPN
iptables -t nat -A PREROUTING -i "$INTERFACE" -p udp --dport 7300       -j DNAT --to-destination :5667 2>/dev/null || true
iptables -t nat -A PREROUTING -i "$INTERFACE" -p udp --dport 6000:19999 -j DNAT --to-destination :5667 2>/dev/null || true

# Persist
if command -v netfilter-persistent &>/dev/null; then
    netfilter-persistent save 2>/dev/null
elif command -v iptables-save &>/dev/null; then
    mkdir -p /etc/iptables
    iptables-save > /etc/iptables/rules.v4 2>/dev/null || true
fi
ok "Firewall rules applied and saved"
info "Ports open: 22(TCP)  5060  5667  7300  6000-19999 (UDP)"

# ══════════════════════════════════════════════════════════════
#  Systemd service
# ══════════════════════════════════════════════════════════════
cat > /etc/systemd/system/zivpn.service <<'SERVICE'
[Unit]
Description=ZIVPN UDP Server – OP UDP Panel
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/etc/zivpn
ExecStart=/usr/local/bin/zivpn server -c /etc/zivpn/config.json
Restart=always
RestartSec=3
Environment=ZIVPN_LOG_LEVEL=info
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
systemctl enable zivpn 2>/dev/null
systemctl start  zivpn 2>/dev/null

if systemctl is-active --quiet zivpn; then
    ok "ZIVPN service started and enabled"
else
    warn "ZIVPN service failed to start – check: journalctl -u zivpn -n 30"
fi

# ══════════════════════════════════════════════════════════════
#  STEP 6 – Download OPUDP Panel
# ══════════════════════════════════════════════════════════════
step 6 6 "Installing OPUDP Panel"

PANEL_URL="https://raw.githubusercontent.com/OfficialOnePesewa/opudp-panel/main/opudp"
if wget -qO /usr/local/bin/opudp "$PANEL_URL" 2>/dev/null; then
    chmod +x /usr/local/bin/opudp
    ok "Panel installed → /usr/local/bin/opudp"
    info "Command: opudp"
else
    warn "Could not download panel from $PANEL_URL"
    warn "You can install it manually later."
fi

# Legacy alias for backwards compatibility
ln -sf /usr/local/bin/opudp /usr/local/bin/onepesewa 2>/dev/null || true

# ══════════════════════════════════════════════════════════════
#  COMPLETION SUMMARY
# ══════════════════════════════════════════════════════════════
echo ""
echo -e "  ${WHT}╭─────────────────────────────────────────────────────────────╮${RST}"
echo -e "  ${WHT}│${RST}  ${GRN}${BOLD}🎉  INSTALLATION COMPLETE!${RST}                                   ${WHT}│${RST}"
echo -e "  ${WHT}├─────────────────────────────────────────────────────────────┤${RST}"
printf  "  ${WHT}│${RST}  ${CYN}🌐 Server IP   :${RST}  %-40s${WHT}│${RST}\n" "$IP"
printf  "  ${WHT}│${RST}  ${YLW}📍 Location    :${RST}  %-40s${WHT}│${RST}\n" "$LOC"
printf  "  ${WHT}│${RST}  ${BLU}🏢 ISP         :${RST}  %-40s${WHT}│${RST}\n" "$ISP"
echo -e "  ${WHT}├─────────────────────────────────────────────────────────────┤${RST}"
printf  "  ${WHT}│${RST}  ${GRN}🔌 ZIVPN Port  :${RST}  %-40s${WHT}│${RST}\n" "5667 (UDP)"
printf  "  ${WHT}│${RST}  ${GRN}🎯 NAT Range   :${RST}  %-40s${WHT}│${RST}\n" "6000 – 19999  +  7300"
printf  "  ${WHT}│${RST}  ${GRN}📞 VoIP SIP    :${RST}  %-40s${WHT}│${RST}\n" "5060 (UDP)"
printf  "  ${WHT}│${RST}  ${MAG}📋 Panel cmd   :${RST}  %-40s${WHT}│${RST}\n" "opudp  (or: onepesewa)"
echo -e "  ${WHT}╰─────────────────────────────────────────────────────────────╯${RST}"
echo ""

# ══════════════════════════════════════════════════════════════
#  OPTIONAL: BBR + TCP Optimizer
# ══════════════════════════════════════════════════════════════
echo -e "  ${YLW}${BOLD}▸ Install BBR + TCP Optimizer?${RST}  ${DIM}(recommended for performance)${RST}"
echo -ne "  ${CYN}  [y/N]: ${RST}"; read -r answer_bbr
if [[ "$answer_bbr" =~ ^[Yy]$ ]]; then
    echo -e "\n  ${YLW}▸ Running BBR optimizer...${RST}\n"
    apt-get install -y curl -qq 2>/dev/null
    bash <(curl -4 -s "https://raw.githubusercontent.com/opiran-club/VPS-Optimizer/main/optimizer.sh" --ipv4)
    echo -e "\n  ${GRN}✔  BBR optimization complete.${RST}"
else
    echo -e "  ${DIM}  Skipped.${RST}"
fi

echo ""

# ══════════════════════════════════════════════════════════════
#  OPTIONAL: BadVPN UDPGW
# ══════════════════════════════════════════════════════════════
echo -e "  ${YLW}${BOLD}▸ Install BadVPN UDP Gateway?${RST}  ${DIM}(for VoIP / UDP tunneling)${RST}"
echo -ne "  ${CYN}  [y/N]: ${RST}"; read -r answer_badvpn
if [[ "$answer_badvpn" =~ ^[Yy]$ ]]; then
    echo -e "\n  ${YLW}▸ Installing BadVPN UDPGW...${RST}\n"
    wget -qN "https://raw.githubusercontent.com/opiran-club/VPS-Optimizer/main/Install/udpgw.sh" \
        && bash udpgw.sh
    echo -e "\n  ${GRN}✔  BadVPN installed.${RST}"
else
    echo -e "  ${DIM}  Skipped.${RST}"
fi

# ── Final prompt ───────────────────────────────────────────────
echo ""
echo -e "  ${GRN}${BOLD}✔  All done!  Type ${CYN}opudp${GRN} to open the management panel.${RST}"
echo -e "  ${DIM}  Admin: @OfficialOnePesewa  |  t.me/officialonepesewatech${RST}\n"
