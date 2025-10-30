#!/usr/bin/env bash
set -euo pipefail

SERVER_URL="$1"
NODE_TOKEN_FILE="$2"

echo "[INFO] Installing K3s worker node..."

if [ ! -f "$NODE_TOKEN_FILE" ]; then
  echo "[ERROR] Node token file not found: $NODE_TOKEN_FILE" >&2
  exit 1
fi

NODE_TOKEN=$(cat "$NODE_TOKEN_FILE")

# Install K3s worker node and connect it to master
(
  curl -sfL https://get.k3s.io | \
    K3S_URL="$SERVER_URL" \
    K3S_TOKEN="$NODE_TOKEN" \
    INSTALL_K3S_EXEC="agent" \
    sh -s - agent

  systemctl enable k3s-agent
  systemctl start k3s-agent
  echo "[OK] K3s agent installation finished in background."
) >/tmp/k3s-agent-install.log 2>&1 &

sleep 10
if systemctl is-active --quiet k3s-agent; then
  echo "[OK] K3s agent service is active."
else
  echo "[WARN] k3s-agent service not yet active. Check logs:"
  echo "       journalctl -u k3s-agent -f"
fi

echo "[DONE] Worker node installation completed (non-blocking)."
exit 0