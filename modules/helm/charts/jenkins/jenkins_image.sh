#!/bin/bash
set -euo pipefail

echo "[JENKINS IMG] Checking for existing Jenkins image..."
if sudo k3s ctr images ls | grep -q "jenkins-with-tools:lts"; then
  echo "[JENKINS IMG] Image already exists in containerd. Skipping build."
  exit 0
fi

WORKDIR=~/jenkins-image
IMAGENAME="jenkins-with-tools:lts"
TARFILE="/tmp/jenkins-with-tools.tar"

echo "[JENKINS IMG] Preparing build directory..."
sudo rm -rf "$WORKDIR"
mkdir -p "$WORKDIR"
cd "$WORKDIR"

echo "[JENKINS IMG] Creating Dockerfile..."
cat > Dockerfile <<'EOF'
FROM jenkins/jenkins:lts
USER root

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl ca-certificates gnupg lsb-release file redis-tools postgresql-client && \
    rm -rf /var/lib/apt/lists/*

# Install kubectl
RUN ARCH=$(uname -m); \
    case "$ARCH" in \
      x86_64) ARCH=amd64 ;; \
      aarch64) ARCH=arm64 ;; \
      *) echo "Unsupported architecture: $ARCH" && exit 1 ;; \
    esac; \
    curl -fsSLo /usr/local/bin/kubectl https://dl.k8s.io/release/v1.30.0/bin/linux/$ARCH/kubectl && \
    chmod +x /usr/local/bin/kubectl

# Install Helm
RUN curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

USER jenkins
EOF

echo "[JENKINS IMG] Building Docker image..."
sudo docker build --no-cache -t $IMAGENAME .

echo "[JENKINS IMG] Saving image to tarball..."
sudo docker save $IMAGENAME -o "$TARFILE"

if [ ! -f "$TARFILE" ]; then
  echo "[ERROR] Image tar file not found at $TARFILE"
  exit 1
fi

echo "[JENKINS IMG] Importing into containerd (k3s)..."
sudo k3s ctr images import "$TARFILE"

echo "[JENKINS IMG] Tagging for localhost/..."
sudo k3s ctr images tag "docker.io/library/jenkins-with-tools:lts" "localhost/jenkins-with-tools:lts"

echo "[JENKINS IMG] Cleaning up..."
sudo rm -f "$TARFILE"

echo "[JENKINS IMG] Jenkins image successfully built, imported, and tagged for localhost."