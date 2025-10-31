#!/usr/bin/env bash
set -euo pipefail

echo "[Uninstall] Starting full K3s cleanup..."

echo "[Uninstall] Removing K3s services..."
if [ -f /usr/local/bin/k3s-uninstall.sh ]; then
  sudo /usr/local/bin/k3s-uninstall.sh || true
fi

if [ -f /usr/local/bin/k3s-agent-uninstall.sh ]; then
  sudo /usr/local/bin/k3s-agent-uninstall.sh || true
fi

echo "[Cleanup] Removing local storage data under /var/lib/rancher/k3s/storage ..."
sudo rm -rf /var/lib/rancher/k3s/storage/pvc-* || true

echo "[Cleanup] Removing kubeconfig, CA and token artifacts..."
sudo rm -f /etc/rancher/k3s/k3s.yaml || true
sudo rm -f /var/lib/rancher/k3s/server/terraform-token.txt || true
sudo rm -f /var/lib/rancher/k3s/server/node-token || true
sudo rm -f /var/lib/rancher/k3s/server/tls/server-ca.crt || true

if systemctl is-active --quiet containerd; then
  echo "[Cleanup] Pruning containerd cache..."
  sudo ctr -n k8s.io c rm -f $(sudo ctr -n k8s.io c ls -q) 2>/dev/null || true
  sudo ctr -n k8s.io i rm -f $(sudo ctr -n k8s.io i ls -q) 2>/dev/null || true
fi

echo "[Uninstall] Completed successfully."