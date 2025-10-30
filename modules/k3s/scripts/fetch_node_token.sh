#!/usr/bin/env bash
set -euo pipefail

MASTER_IP="$1"
SSH_USER="$2"
PRIVATE_KEY="$3"
TOKEN_DEST="$4"

echo "[Fetch] Retrieving K3s node-token..."

# Retrieve the K3s node-token from master node (handles multiple version paths)
TOKEN_PATHS=(
  "/var/lib/rancher/k3s/server/node-token"
  "/var/lib/rancher/k3s/agent/token"
  "/var/lib/rancher/k3s/server/agent-token"
)

TOKEN_FOUND=false
for path in "${TOKEN_PATHS[@]}"; do
  if ssh -i "$PRIVATE_KEY" -o StrictHostKeyChecking=no "$SSH_USER@$MASTER_IP" "sudo test -f $path"; then
    echo "[INFO] Found node token at $path"
    ssh -i "$PRIVATE_KEY" -o StrictHostKeyChecking=no "$SSH_USER@$MASTER_IP" "sudo cat $path" > "$TOKEN_DEST"
    TOKEN_FOUND=true
    break
  fi
done

if [ "$TOKEN_FOUND" = false ]; then
  echo "[ERROR] No node-token found on master node!" >&2
  exit 1
fi

echo "[OK] Node token saved to $TOKEN_DEST"