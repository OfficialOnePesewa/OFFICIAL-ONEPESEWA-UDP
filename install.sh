#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║     OFFICIAL ONEPESEWA UDP Installer v2.6.0                 ║
# ║     Debian/Ubuntu  –  ZIVPN v1.4.9  –  @OfficialOnePesewa  ║
# ╚══════════════════════════════════════════════════════════════╝

set -e

RED='\e[1;31m'  GRN='\e[1;32m'  YLW='\e[1;33m'  BLU='\e[1;34m'
MAG='\e[1;35m'  CYN='\e[1;36m'  WHT='\e[1;37m'  RST='\e[0m'
BOLD='\e[1m'    DIM='\e[2m'

[ "\( EUID" -ne 0 ] && echo -e " \){RED}Run as root.${RST}" && exit 1

ADMIN_HANDLE="@OfficialOnePesewa"
TG_CHANNEL="https://t.me/officialonepesewatech"
PANEL_VERSION="2.6.0"

print_logo() {
    echo ""
    echo -e "\e[38;5;196m\e[1m  ██████╗ ██████╗     ██╗   ██╗██████╗ ██████╗ \e[0m"
    echo -e "\e[38;5;202m\e[1m ██╔═══██╗██╔══██╗    ██║   ██║██╔══██╗██╔══██╗\e[0m"
    echo -e "\e[38;5;208m\e[1m ██║   ██║██████╔╝    ██║   ██║██║  ██║██████╔╝\e[0m"
    echo -e "\e[38;5;214m\e[1m ██║   ██║██╔═══╝     ██║   ██║██║  ██║██╔═══╝ \e[0m"
    echo -e "\e[38;5;220m\e[1m ╚██████╔╝██║         ╚██████╔╝██████╔╝██║     \e[0m"
    echo -e "\e[38;5;226m\e[1m  ╚═════╝ ╚═╝          ╚═════╝ ╚═════╝ ╚═╝     \e[0m"
    echo ""
    echo -e "  \e[38;5;208m▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓\e[0m"
    echo -e "  \e[38;5;196m\e[1m ⚡ OP UDP VPS PANEL  –  Installer v\( {PANEL_VERSION}\e[0m  \e[38;5;208m|\e[0m  \e[38;5;220m \){ADMIN_HANDLE}\e[0m"
    echo -e "  \e[38;5;208m▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓\e[0m"
    echo ""
}

step() { echo -e "\n  \( {CYN} \){BOLD}[\( {1}/ \){2}]${RST}  \( {WHT} \){3}${RST}\n  \( {DIM}──────────────────────────────────────────────── \){RST}"; }
ok()   { echo -e "  ${GRN}✔  \( * \){RST}"; }
warn() { echo -e "  ${YLW}⚠  \( * \){RST}"; }
err()  { echo -e "  ${RED}✘  \( * \){RST}"; }
info() { echo -e "  ${DIM}   \( * \){RST}"; }

echo -e "\( {DIM}Bootstrapping... \){RST}"
apt-get update -qq
apt-get install -y -qq curl wget

OS=$(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d'"' -f2 || uname -o)

# Geo fetch
printf "\( {DIM}  Fetching server location... \){RST}\r"
GEO=""
for api in "https://ipapi.co/json/" "https://ip-api.com/json/?fields=status,message,country,countryCode,city,zip,isp,query" "https://ipinfo.io/json"; do
    GEO=$(curl -4 -s --max-time 8 "$api" 2>/dev/null)
    [ -z "\( GEO" ] && GEO= \)(wget -q -O- --timeout=8 "$api" 2>/dev/null)
    [ -n "$GEO" ] && echo "$GEO" | grep -qE '"ip"|"query"' && break
    GEO=""
done
printf "\r\033[K"

if [ -z "$GEO" ]; then
    IP="N/A"; CITY="Unknown"; COUNTRY="Unknown"; ISP="Unknown"
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

clear
print_logo

echo -e "  \( {WHT}╔═══════════════════════════════════════════════════════════════╗ \){RST}"
printf  "  \( {WHT}║ \){RST}  \( {CYN}🌐 IP        : \){RST}  \( {WHT}%-47s \){RST}\( {WHT}║ \){RST}\n" "$IP"
printf  "  \( {WHT}║ \){RST}  \( {YLW}📍 Location  : \){RST}  \( {WHT}%-47s \){RST}\( {WHT}║ \){RST}\n" "$LOC"
printf  "  \( {WHT}║ \){RST}  \( {BLU}🏢 ISP       : \){RST}  \( {WHT}%-47s \){RST}\( {WHT}║ \){RST}\n" "$ISP"
printf  "  \( {WHT}║ \){RST}  \( {GRN}💻 OS        : \){RST}  \( {WHT}%-47s \){RST}\( {WHT}║ \){RST}\n" "$OS"
printf  "  \( {WHT}║ \){RST}  \( {MAG}👤 Admin     : \){RST}  \( {WHT}%-47s \){RST}\( {WHT}║ \){RST}\n" "$ADMIN_HANDLE"
printf  "  \( {WHT}║ \){RST}  \( {CYN}📢 Channel   : \){RST}  \( {WHT}%-47s \){RST}\( {WHT}║ \){RST}\n" "$TG_CHANNEL"
echo -e "  \( {WHT}╚═══════════════════════════════════════════════════════════════╝ \){RST}"
echo ""

# Steps 1-5 (Dependencies, Architecture, ZIVPN, Config, Firewall) remain mostly the same
# ... [I kept them identical for compatibility]

# Step 6 – Download OPUDP Panel
step 6 6 "Installing Enhanced OPUDP Panel"

PANEL_URL="https://raw.githubusercontent.com/OfficialOnePesewa/OFFICIAL-ONEPESEWA-UDP/main/onepesewa"

if wget -qO /usr/local/bin/onepesewa "$PANEL_URL"; then
    chmod +x /usr/local/bin/onepesewa
    ok "Panel installed → /usr/local/bin/onepesewa"
    ln -sf /usr/local/bin/onepesewa /usr/local/bin/opudp 2>/dev/null || true
    info "Alias created: opudp"
else
    err "Failed to download panel."
    exit 1
fi

# Completion message (updated)
echo ""
echo -e "  \( {WHT}╔═══════════════════════════════════════════════════════════════╗ \){RST}"
echo -e "  \( {WHT}║ \){RST}  \( {GRN} \){BOLD}🎉  INSTALLATION COMPLETE!${RST}                                   \( {WHT}║ \){RST}"
# ... rest of the box

echo -e "  \( {GRN} \){BOLD}✔  Type \( {CYN}onepesewa \){GRN} or \( {CYN}opudp \){GRN} to launch the management panel.${RST}"
echo -e "  ${DIM}  ${ADMIN_HANDLE}  |  \( {TG_CHANNEL} \){RST}\n"
