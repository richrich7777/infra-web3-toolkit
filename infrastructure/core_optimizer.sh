#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "[ERROR] Run as root (sudo) to apply kernel, limits, and firewall settings." >&2
  exit 1
fi

SYSCTL_FILE="/etc/sysctl.d/99-core-optimizer.conf"
LIMITS_FILE="/etc/security/limits.d/99-infra-web3-toolkit.conf"

cat > "${SYSCTL_FILE}" <<'SYSCTL_EOF'
# infra-web3-toolkit: high-throughput Linux network tuning
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr

# Descriptor and queue capacity for high connection volume
fs.file-max=2097152
net.core.somaxconn=65535
net.core.netdev_max_backlog=16384

# Persistent connection keepalive tuning
net.ipv4.tcp_keepalive_time=300
net.ipv4.tcp_keepalive_intvl=30
net.ipv4.tcp_keepalive_probes=5

# Hardening and stale socket safety
net.ipv4.tcp_syncookies=1
net.ipv4.tcp_fin_timeout=15
SYSCTL_EOF

cat > "${LIMITS_FILE}" <<'LIMITS_EOF'
# infra-web3-toolkit: descriptor limits for service accounts
* soft nofile 1048576
* hard nofile 1048576
root soft nofile 1048576
root hard nofile 1048576
LIMITS_EOF

sysctl --system >/dev/null

if command -v ufw >/dev/null 2>&1; then
  ufw --force reset
  ufw default deny incoming
  ufw default allow outgoing
  ufw allow 22/tcp comment 'SSH management'
  ufw allow 443/tcp comment 'HTTPS edge'
  # Skeleton examples for custom proxy routing panel; scope to trusted CIDRs before production use.
  ufw allow from 10.0.0.0/8 to any port 7000 proto tcp comment 'internal proxy control panel'
  ufw allow 7443/tcp comment 'public proxy ingress'
  ufw --force enable
fi

if command -v iptables >/dev/null 2>&1; then
  iptables -N PROXY_PANEL 2>/dev/null || true
  iptables -F PROXY_PANEL
  iptables -A PROXY_PANEL -s 10.0.0.0/8 -p tcp --dport 7000 -j ACCEPT
  iptables -A PROXY_PANEL -p tcp --dport 7000 -j DROP
  iptables -C INPUT -j PROXY_PANEL 2>/dev/null || iptables -A INPUT -j PROXY_PANEL
fi

echo "[OK] Core optimizer settings applied. Re-login or restart services to pick up nofile limits."
