#!/usr/bin/env bash
set -euo pipefail

echo "[INFO] Ubuntu node preparation started..."

# Update system packages
sudo apt-get update -y >/dev/null
sudo apt-get install -y \
  curl wget apt-transport-https ca-certificates software-properties-common gnupg lsb-release >/dev/null

# Disable swap
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab || true

# Adjust sysctl parameters
sudo modprobe br_netfilter || true
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf >/dev/null
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
sudo sysctl --system >/dev/null

# Disable firewall
sudo systemctl disable ufw >/dev/null 2>&1 || true
sudo systemctl stop ufw >/dev/null 2>&1 || true

# Configure DNS resolvers
sudo rm -f /etc/resolv.conf
cat <<EOF | sudo tee /etc/resolv.conf >/dev/null
nameserver 8.8.8.8
nameserver 1.1.1.1
EOF
echo "[OK] DNS resolvers set to 8.8.8.8 and 1.1.1.1"

# Install Docker Engine
if ! command -v docker &>/dev/null; then
  echo "[INFO] Installing Docker Engine..."
  curl -fsSL https://get.docker.com | sudo bash >/dev/null
  sudo systemctl enable docker >/dev/null
  sudo systemctl start docker >/dev/null
  sudo usermod -aG docker "$USER" || true
  echo "[OK] Docker installed and running."
else
  echo "[OK] Docker already installed."
fi

# Install Helm and Redis/PostgreSQL clients
if ! command -v helm &>/dev/null; then
  echo "[INFO] Installing Helm 3..."
  curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash >/dev/null
  echo "[OK] Helm installed."
else
  echo "[OK] Helm already installed."
fi
sudo apt-get install -y redis-tools postgresql-client >/dev/null
echo "[OK] redis-cli and psql installed."

# Verify Internet connectivity
if ping -c 1 -W 2 google.com >/dev/null 2>&1; then
  echo "[OK] Internet connectivity verified."
else
  echo "[WARN] No Internet access detected!"
fi

echo "[DONE] Ubuntu node preparation complete."