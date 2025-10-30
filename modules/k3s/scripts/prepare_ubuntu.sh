#!/usr/bin/env bash
set -euo pipefail

echo "[INFO] Ubuntu node preparation started..."

# Update packages
echo "[1/7] Updating system packages..."
sudo apt-get update -y >/dev/null
sudo apt-get install -y curl wget apt-transport-https ca-certificates software-properties-common >/dev/null

# Disable swap
echo "[2/7] Disabling swap..."
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab || true

# Adjust system parameters
echo "[3/7] Adjusting sysctl parameters..."
sudo modprobe br_netfilter || true
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf >/dev/null
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
sudo sysctl --system >/dev/null

# Disable firewall
echo "[4/7] Disabling UFW firewall..."
sudo systemctl disable ufw >/dev/null 2>&1 || true
sudo systemctl stop ufw >/dev/null 2>&1 || true

# Ensure Google DNS (force replace)
echo "[5/7] Ensuring DNS resolver (8.8.8.8)..."
sudo rm -f /etc/resolv.conf
cat <<EOF | sudo tee /etc/resolv.conf >/dev/null
nameserver 8.8.8.8
nameserver 1.1.1.1
EOF
echo "[OK] DNS resolvers set to 8.8.8.8 and 1.1.1.1"

# Install Helm CLI
echo "[6/7] Checking Helm installation..."
if ! command -v helm &>/dev/null; then
  echo "[INFO] Installing Helm 3..."
  curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash >/dev/null
  echo "[OK] Helm installed."
else
  echo "[OK] Helm already installed."
fi

# Verify connectivity
echo "[7/7] Verifying internet access..."
if ping -c 1 -W 2 google.com >/dev/null 2>&1; then
  echo "[OK] Internet connectivity verified."
else
  echo "[WARN] No Internet access detected!"
fi

echo "[DONE] Ubuntu node preparation complete."