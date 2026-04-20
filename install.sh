#!/bin/bash
# OFFICIAL ONEPESEWA OPUDP Installer + BBR
set -e

G='\e[1;32m'
R='\e[1;31m'
Y='\e[1;33m'
C='\e[1;36m'
NC='\e[0m'

[ "$EUID" -ne 0 ] && echo -e "${R}Run as root.${NC}" && exit 1

show_header(){
clear
echo -e "${C}====================================================================${NC}"

cat << "EOF"
   ██████╗ ██████╗ ██╗   ██╗██████╗ ██████╗
  ██╔═══██╗██╔══██╗██║   ██║██╔══██╗██╔══██╗
  ██║   ██║██████╔╝██║   ██║██║  ██║██████╔╝
  ██║   ██║██╔═══╝ ██║   ██║██║  ██║██╔═══╝
  ╚██████╔╝██║     ╚██████╔╝██████╔╝██║
   ╚═════╝ ╚═╝      ╚═════╝ ╚═════╝ ╚═╝

                VPS PANEL
EOF

echo -e "${C}====================================================================${NC}"
echo -e "${G}      OFFICIAL ONEPESEWA OPUDP MANAGER${NC}"
echo -e "${C}====================================================================${NC}"
echo -e "${Y}OS       :${NC} $OS"
echo -e "${Y}Location :${NC} $LOC"
echo -e "${Y}IP       :${NC} $IP"
echo -e "${Y}ISP      :${NC} $ISP"
echo -e "${C}====================================================================${NC}"
}

echo -e "${Y}[+] Installing dependencies...${NC}"
apt-get update -qq
apt-get install -y -qq curl wget jq iptables-persistent netfilter-persistent openssl irqbalance

OS=$(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)
IP=$(curl -4 -s ifconfig.me || echo N/A)
LOC="Auto Detect"
ISP="Auto Detect"

show_header

ARCH=$(uname -m)
case $ARCH in
 x86_64|amd64) BIN="amd64" ;;
 aarch64|arm64) BIN="arm64" ;;
 *) echo "Unsupported architecture"; exit 1 ;;
esac

echo -e "${Y}[+] Installing ZIVPN...${NC}"
systemctl stop zivpn 2>/dev/null || true
rm -f /usr/local/bin/zivpn

wget -O /usr/local/bin/zivpn \
https://github.com/zahidbd2/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-$BIN

chmod +x /usr/local/bin/zivpn

mkdir -p /etc/zivpn

cat <<EOF >/etc/zivpn/config.json
{
"listen":":5667",
"cert":"/etc/zivpn/zivpn.crt",
"key":"/etc/zivpn/zivpn.key",
"obfs":"onepesewa",
"auth":{
"mode":"passwords",
"config":[]
}
}
EOF

openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 \
-subj "/C=GH/ST=Accra/L=Accra/O=OnePesewa/CN=onepesewa" \
-keyout /etc/zivpn/zivpn.key \
-out /etc/zivpn/zivpn.crt

echo -e "${Y}[+] Firewall rules...${NC}"
iptables -I INPUT -p udp --dport 5667 -j ACCEPT || true
iptables -I INPUT -p udp --dport 5060 -j ACCEPT || true
iptables -I INPUT -p udp --dport 6000:19999 -j ACCEPT || true
iptables-save > /etc/iptables/rules.v4 || true

cat <<EOF >/etc/systemd/system/zivpn.service
[Unit]
Description=ZIVPN UDP Server
After=network.target

[Service]
ExecStart=/usr/local/bin/zivpn server -c /etc/zivpn/config.json
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable zivpn
systemctl restart zivpn

echo -e "${Y}[+] Installing OPUDP panel...${NC}"

cat <<'EOF' >/usr/local/bin/onepesewa
#!/bin/bash
clear
echo "OPUDP PANEL"
echo "1 Create User"
echo "2 List Users"
read -p "Choose: " a
EOF

chmod +x /usr/local/bin/onepesewa

# ======================
# BBR + NETWORK TUNING
# ======================

echo -e "${Y}[+] Applying BBR optimization...${NC}"

modprobe tcp_bbr 2>/dev/null || true

[ ! -f /etc/sysctl.conf.bak ] && cp /etc/sysctl.conf /etc/sysctl.conf.bak || true

sed -i '/# OPUDP BBR START/,/# OPUDP BBR END/d' /etc/sysctl.conf

cat <<'EOF' >> /etc/sysctl.conf

# OPUDP BBR START
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr

net.core.somaxconn=65535
net.core.netdev_max_backlog=250000

net.core.rmem_max=67108864
net.core.wmem_max=67108864

net.ipv4.tcp_rmem=4096 87380 67108864
net.ipv4.tcp_wmem=4096 65536 67108864

net.ipv4.tcp_fastopen=3
net.ipv4.tcp_mtu_probing=1
net.ipv4.tcp_slow_start_after_idle=0

net.ipv4.udp_rmem_min=16384
net.ipv4.udp_wmem_min=16384
# OPUDP BBR END

EOF

sysctl -p >/dev/null 2>&1 || true

systemctl enable irqbalance >/dev/null 2>&1 || true
systemctl restart irqbalance >/dev/null 2>&1 || true

BBR=$(sysctl -n net.ipv4.tcp_congestion_control || echo unknown)

echo -e "${G}[+] BBR Active: $BBR${NC}"

echo
echo "=================================="
echo " INSTALL COMPLETE"
echo " COMMAND: onepesewa"
echo " UDP PORT: 5667"
echo " BBR: ENABLED"
echo "=================================="
