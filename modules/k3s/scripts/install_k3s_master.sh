#!/usr/bin/env bash
set -euo pipefail

echo "[INFO] Installing K3s master node..."

# Ensure curl available
if ! command -v curl >/dev/null 2>&1; then
  sudo apt-get update -y && sudo apt-get install -y curl
fi

# Install K3s only if not already installed -- Token no expire
if ! systemctl is-active --quiet k3s; then
  echo "[INFO] Installing K3s via get.k3s.io..."
  curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --write-kubeconfig-mode=644 " sh -
else
  echo "[INFO] K3s already installed. Skipping installation."
fi

# Wait for systemd service to be fully active
echo "[WAIT] Waiting for K3s service to start..."
for i in {1..30}; do
  if systemctl is-active --quiet k3s; then
    echo "[OK] K3s service is active."
    break
  fi
  echo "[WAIT] k3s service not yet active ($i)"
  sleep 2
done

# Wait until kubeconfig exists
echo "[WAIT] Waiting for /etc/rancher/k3s/k3s.yaml to appear..."
for i in {1..30}; do
  if sudo test -f /etc/rancher/k3s/k3s.yaml; then
    echo "[OK] kubeconfig file detected."
    break
  fi
  echo "[WAIT] kubeconfig not ready yet ($i)"
  sleep 2
done

sudo k3s kubectl patch storageclass local-path -p '{"volumeBindingMode":"Immediate"}' || true

# Verify API accessibility
echo "[INFO] Checking K3s API health..."
for i in {1..15}; do
  if sudo k3s kubectl get nodes >/dev/null 2>&1; then
    echo "[OK] K3s API responding."
    break
  fi
  echo "[WAIT] K3s API not ready yet ($i)"
  sleep 2
done

echo "[INFO] K3s master installation completed successfully."