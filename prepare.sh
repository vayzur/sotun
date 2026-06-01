#!/usr/bin/env bash
# prepare.sh — run this on the RESTRICTED node (the one behind censorship)
# enables ssh tcp forwarding, gateway ports and L3 tunnels, then restarts sshd
#
# if this node has no internet access, run these two commands manually:
#   sed -i 's/^#*AllowTcpForwarding.*/AllowTcpForwarding yes/' /etc/ssh/sshd_config && sed -i 's/^#*GatewayPorts.*/GatewayPorts clientspecified/' /etc/ssh/sshd_config && sed -i 's/^#*ClientAliveInterval.*/ClientAliveInterval 3/' /etc/ssh/sshd_config && sed -i 's/^#*ClientAliveCountMax.*/ClientAliveCountMax 3/' /etc/ssh/sshd_config && sed -i 's/^#*PermitTunnel.*/PermitTunnel yes/' /etc/ssh/sshd_config && systemctl restart sshd
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
if command -v systemctl >/dev/null 2>&1; then
  systemctl restart sshd
elif command -v service >/dev/null 2>&1; then
  service ssh restart || service sshd restart
else
  echo "error: cannot restart sshd — do it manually."
  exit 1
fi

echo "done. this node is ready to accept reverse tunnels and L3 tunnels."
