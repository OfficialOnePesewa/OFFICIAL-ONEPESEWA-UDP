#!/bin/bash
# OPUDP Panel — Shared Library
# @OfficialOnePesewa | github.com/OfficialOnePesewa/opudp-zivpn

# ── Colors ────────────────────────────────────────────────────
RED='\033[0;31m'   GREEN='\033[0;32m'  YELLOW='\033[1;33m'
BLUE='\033[0;34m'  PURPLE='\033[0;35m' CYAN='\033[0;36m'
WHITE='\033[1;37m' DIM='\033[2m'       BOLD='\033[1m'
NC='\033[0m'

# ── Paths ─────────────────────────────────────────────────────
PANEL_DIR="/opt/opudp"
USERS_DB="$PANEL_DIR/users.db"
ZIVPN_CONFIG="/etc/zivpn/config.json"
ZIVPN_CERT="/etc/zivpn/zivpn.crt"
ZIVPN_KEY="/etc/zivpn/zivpn.key"
ZIVPN_BIN="/usr/local/bin/zivpn"
OPUDP_CMD="/usr/local/bin/opudp"
LOG_FILE="$PANEL_DIR/panel.log"

# ── Constants ─────────────────────────────────────────────────
SERVICE_NAME="zivpn"
ZIVPN_PORT=5667
UDP_START=6000
UDP_END=19999
REPO_RAW="https://raw.githubusercontent.com/OfficialOnePesewa/opudp-zivpn/main"

# ── Logging ───────────────────────────────────────────────────
log()     { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE" 2>/dev/null; }
info()    { echo -e "${CYAN}ℹ  $*${NC}"; }
success() { echo -e "${GREEN}✓  $*${NC}"; }
warn()    { echo -e "${YELLOW}⚠  $*${NC}"; }
error()   { echo -e "${RED}✗  $*${NC}"; }

confirm() {
    echo -en "${YELLOW}${1:-Are you sure?} [y/N]: ${NC}"
    read -r _ans; [[ "$_ans" =~ ^[yY]$ ]]
}

press_enter() {
    echo -en "\n${DIM}Press Enter to continue...${NC}"
    read -r
}

# ── Network ───────────────────────────────────────────────────
get_server_ip() {
    curl -s --max-time 5 ifconfig.me 2>/dev/null ||
    curl -s --max-time 5 ipinfo.io/ip 2>/dev/null ||
    hostname -I | awk '{print $1}'
}

get_geo_info() {
    local data
    data=$(curl -s --max-time 5 "https://ipinfo.io/json" 2>/dev/null)
    GEO_COUNTRY=$(echo "$data" | grep -oP '"country":\s*"\K[^"]+' || echo "??")
    GEO_CITY=$(echo "$data"    | grep -oP '"city":\s*"\K[^"]+' || echo "Unknown")
    GEO_ISP=$(echo "$data"     | grep -oP '"org":\s*"\K[^"]+' || echo "Unknown")
    GEO_IP=$(echo "$data"      | grep -oP '"ip":\s*"\K[^"]+' || get_server_ip)
}

# ── Panel Init ────────────────────────────────────────────────
init_panel() {
    mkdir -p "$PANEL_DIR"
    [[ -f "$USERS_DB" ]] || touch "$USERS_DB"
    [[ -f "$LOG_FILE" ]] || touch "$LOG_FILE"
}

# ── users.db helpers ──────────────────────────────────────────
# Format: username:password:expiry_epoch:bandwidth_gb:max_conn:hwid:hwid_locked
#   expiry_epoch = 0 means never expires
#   hwid_locked  = 1 means password is encoded as "pass|hwid" in ZIVPN config

user_exists() { grep -q "^${1}:" "$USERS_DB" 2>/dev/null; }

get_user_field() {
    # get_user_field <username> <field_number (1-based)>
    awk -F: -v u="$1" -v f="$2" '$1==u{print $f; exit}' "$USERS_DB"
}

update_user_field() {
    # update_user_field <username> <field_number> <new_value>
    local u="$1" f="$2" v="$3"
    awk -F: -v OFS=: -v u="$u" -v f="$f" -v v="$v" \
        'BEGIN{} $1==u{$f=v} {print}' "$USERS_DB" > "$USERS_DB.tmp" \
        && mv "$USERS_DB.tmp" "$USERS_DB"
}

delete_user_line() {
    local tmp; tmp=$(grep -v "^${1}:" "$USERS_DB")
    echo "$tmp" > "$USERS_DB"
}

count_users() {
    [[ -s "$USERS_DB" ]] && grep -c '.' "$USERS_DB" || echo 0
}

# ── Expiry helpers ────────────────────────────────────────────
days_to_epoch() { echo $(( $(date +%s) + $1 * 86400 )); }

epoch_to_date() {
    local ts="$1"
    [[ "$ts" == "0" ]] && echo "Never" && return
    date -d "@$ts" '+%Y-%m-%d' 2>/dev/null || date -r "$ts" '+%Y-%m-%d' 2>/dev/null || echo "Unknown"
}

is_expired() {
    local exp; exp=$(get_user_field "$1" 3)
    [[ -n "$exp" && "$exp" != "0" && "$exp" -lt "$(date +%s)" ]]
}

days_left() {
    local exp; exp=$(get_user_field "$1" 3)
    [[ "$exp" == "0" ]] && { echo "∞"; return; }
    local left=$(( (exp - $(date +%s)) / 86400 ))
    [[ $left -le 0 ]] && echo "EXPIRED" || echo "${left}d"
}
