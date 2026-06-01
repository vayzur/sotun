#!/usr/bin/env bash
# install.sh — installs sotun on the exit node
# usage: curl -fsSL https://raw.githubusercontent.com/vayzur/sotun/main/install.sh | bash

set -e

SOTUN_URL="https://raw.githubusercontent.com/vayzur/sotun/main/sotun"

if [ "$(id -u)" -ne 0 ]; then
  echo "error: this installer requires root."
  exit 1
fi

if [ "$(uname -s)" != "Linux" ]; then
  echo "error: sotun only supports linux."
  exit 1
fi

if ! command -v ssh >/dev/null 2>&1; then
  echo "error: ssh is required but not found. install openssh-client and try again."
  exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "error: curl is required but not found. install curl and try again."
  exit 1
fi

echo "downloading sotun..."
tmp="$(mktemp)"
if ! curl -fsSL "$SOTUN_URL" -o "$tmp"; then
  echo "error: failed to download sotun from $SOTUN_URL"
  rm -f "$tmp"
  exit 1
fi

chmod +x "$tmp"
install -m 0755 "$tmp" /usr/local/bin/sotun
rm -f "$tmp"

mkdir -p /etc/sotun/proxy /etc/sotun/tunnel

echo "sotun installed at /usr/local/bin/sotun"
echo ""
echo "next steps:"
echo "  1. run 'sotun init' to generate your ssh key"
echo "  2. copy the printed public key to the remote (restricted) node"
echo "  3. add a proxy:  sotun proxy add 1080 root@127.0.0.1 22"
echo "  4. add a tunnel: sotun tunnel add 1080 root@<remote-ip> 22"
echo ""
echo "run 'sotun help' to see all commands."
