#!/usr/bin/env bash
set -e

if [ "$(id -u)" -ne 0 ]; then
  echo "error: this script requires root."
  exit 1
fi

SSHD_CONFIG=/etc/ssh/sshd_config

patch_option() {
  local key="$1"
  local val="$2"
  if grep -qE "^#*\s*${key}\s" "$SSHD_CONFIG"; then
    sed -i "s/^#*\s*${key}\s.*/${key} ${val}/" "$SSHD_CONFIG"
  else
    echo "${key} ${val}" >> "$SSHD_CONFIG"
  fi
}

echo "patching sshd config..."
patch_option AllowTcpForwarding yes
patch_option GatewayPorts clientspecified
patch_option ClientAliveInterval 3
patch_option ClientAliveCountMax 3
patch_option PermitTunnel yes

echo "restarting sshd..."
systemctl daemon-reload
if systemctl is-active --quiet ssh.socket; then
  systemctl restart ssh.socket
else
  systemctl restart sshd 2>/dev/null || systemctl restart ssh
fi

echo "done. this node is ready to accept reverse tunnels and L3 tunnels."
