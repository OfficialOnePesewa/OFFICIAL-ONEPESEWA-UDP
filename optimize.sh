#!/bin/bash
# VPS Network Optimizer – BBR + TCP/UDP Tuning
set -e

G='\e[1;32m' Y='\e[1;33m' NC='\e[0m'
echo -e "${Y}[*] Applying VPS network optimizations...${NC}"

# Enable BBR congestion control (requires kernel >= 4.9)
KVER=$(uname -r | cut -d. -f1-2)
if [ "$(printf '%s\n' "4.9" "$KVER" | sort -V | head -n1)" = "4.9" ]; then
    modprobe tcp_bbr 2>/dev/null || true
    echo "tcp_bbr" > /etc/modules-load.d/bbr.conf
    sysctl -w net.core.default_qdisc=fq
    sysctl -w net.ipv4.tcp_congestion_control=bbr
    echo -e "${G}[✓] BBR congestion control enabled${NC}"
else
    echo -e "${Y}[!] Kernel too old for BBR (requires 4.9+)${NC}"
fi

# Apply comprehensive sysctl optimizations
cat >> /etc/sysctl.conf << 'EOF'

# VPN / High-Performance Network Optimizations
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.core.rmem_default = 16777216
net.core.wmem_default = 16777216
net.core.optmem_max = 134217728
net.core.netdev_max_backlog = 250000
net.core.somaxconn = 65535

net.ipv4.tcp_rmem = 4096 87380 134217728
net.ipv4.tcp_wmem = 4096 65536 134217728
net.ipv4.tcp_mem = 786432 1048576 26777216
net.ipv4.tcp_max_syn_backlog = 16384
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_keepalive_intvl = 30
net.ipv4.tcp_keepalive_probes = 5
net.ipv4.tcp_max_tw_buckets = 2000000
net.ipv4.tcp_syn_retries = 2
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_notsent_lowat = 16384

net.ipv4.udp_rmem_min = 8192
net.ipv4.udp_wmem_min = 8192
net.ipv4.udp_mem = 786432 1048576 26777216

net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.ip_forward = 1

net.ipv4.neigh.default.gc_thresh1 = 1024
net.ipv4.neigh.default.gc_thresh2 = 4096
net.ipv4.neigh.default.gc_thresh3 = 8192

net.netfilter.nf_conntrack_max = 1048576
net.netfilter.nf_conntrack_tcp_timeout_established = 86400
net.netfilter.nf_conntrack_tcp_timeout_time_wait = 30
EOF

sysctl -p > /dev/null 2>&1

# Increase open file limits
cat >> /etc/security/limits.conf << 'EOF'
* soft nofile 1048576
* hard nofile 1048576
* soft nproc 1048576
* hard nproc 1048576
root soft nofile 1048576
root hard nofile 1048576
EOF

echo "session required pam_limits.so" >> /etc/pam.d/common-session 2>/dev/null || true

echo -e "${G}[✓] Network optimizations applied${NC}"
