#!/usr/bin/env bash
set -euo pipefail

MASTER_IP="$1"
SSH_USER="$2"
PRIVATE_KEY="$3"
DEST_PATH="$4"

echo "[Fetch] Retrieving kubeconfig from master..."

# Copy kubeconfig
scp -i "${PRIVATE_KEY}" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
  "${SSH_USER}@${MASTER_IP}:/etc/rancher/k3s/k3s.yaml" "${DEST_PATH}"

# Replace localhost with master IP (cross-platform safe)
if [[ "$OSTYPE" == "darwin"* ]]; then
# macOS BSD sed syntax
  sed -i '' "s/127\.0\.0\.1/${MASTER_IP}/g" "${DEST_PATH}"
else
# GNU sed (Linux)
  sed -i "s/127\.0\.0\.1/${MASTER_IP}/g" "${DEST_PATH}"
fi

echo "[OK] Kubeconfig successfully saved to ${DEST_PATH}"