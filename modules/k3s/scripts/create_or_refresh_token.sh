#!/usr/bin/env bash
set -euo pipefail

SA_NAME="terraform-admin-static"
NAMESPACE="kube-system"
TOKEN_PATH="/var/lib/rancher/k3s/server/terraform-token.txt"

echo "[INFO] Creating or refreshing Terraform static token..."
echo "[INFO] ServiceAccount: ${SA_NAME}"
echo "[INFO] Namespace: ${NAMESPACE}"

# Ensure kubectl is available
if ! command -v k3s &>/dev/null; then
  echo "[ERROR] k3s command not found. Run this on master node."
  exit 1
fi

# Wait until API is ready
for i in {1..30}; do
  if sudo k3s kubectl get nodes &>/dev/null; then
    break
  fi
  echo "[WAIT] Kubernetes API not ready, retrying in 2s..."
  sleep 2
done

# Create ServiceAccount if missing
if ! sudo k3s kubectl -n "$NAMESPACE" get sa "$SA_NAME" >/dev/null 2>&1; then
  echo "[INFO] Creating ServiceAccount: $SA_NAME"
  sudo k3s kubectl -n "$NAMESPACE" create sa "$SA_NAME"
else
  echo "[OK] ServiceAccount already exists."
fi

# Bind to cluster-admin role if missing
if ! sudo k3s kubectl get clusterrolebinding "${SA_NAME}-binding" >/dev/null 2>&1; then
  echo "[INFO] Creating ClusterRoleBinding..."
  sudo k3s kubectl create clusterrolebinding "${SA_NAME}-binding" \
    --clusterrole=cluster-admin \
    --serviceaccount=${NAMESPACE}:${SA_NAME}
else
  echo "[OK] ClusterRoleBinding already exists."
fi

# Create long-lived token (10 years)
echo "[INFO] Generating long-lived token..."
TOKEN=$(sudo k3s kubectl -n "$NAMESPACE" create token "$SA_NAME" --duration=87600h || true)

if [[ -z "$TOKEN" ]]; then
  echo "[ERROR] Failed to create token."
  exit 1
fi

# Write token to expected path
echo "$TOKEN" | sudo tee "$TOKEN_PATH" >/dev/null
sudo chmod 644 "$TOKEN_PATH"

# Verify it exists
if sudo test -f "$TOKEN_PATH"; then
  echo "[OK] Token written to $TOKEN_PATH"
else
  echo "[WARN] Token file not found at $TOKEN_PATH — using /root fallback..."
  echo "$TOKEN" | sudo tee /root/terraform-token.txt >/dev/null
  sudo chmod 644 /root/terraform-token.txt
fi

echo "[DONE] Terraform ServiceAccount and static token are ready."