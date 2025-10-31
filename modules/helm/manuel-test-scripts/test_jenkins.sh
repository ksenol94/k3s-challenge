#!/usr/bin/env bash
set -euo pipefail

# --- Locate terraform.tfvars dynamically (project root)
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
TFVARS_FILE="${TFVARS_FILE:-${ROOT_DIR}/terraform.tfvars}"

# --- Extract Jenkins credentials
JENKINS_USER=$(grep -E '^jenkins_admin_user' "$TFVARS_FILE" | awk -F'=' '{gsub(/[[:space:]"]/,"",$2); print $2}')
JENKINS_PASS=$(grep -E '^jenkins_admin_pass' "$TFVARS_FILE" | awk -F'=' '{gsub(/[[:space:]"]/,"",$2); print $2}')

# --- Cluster connection info
NODE_IP=${NODE_IP:-"$(kubectl get nodes -o wide --no-headers | awk 'NR==1{print $6}')"}
JENKINS_PORT=${JENKINS_PORT:-32000}

echo "[INFO] Using terraform vars from: $TFVARS_FILE"
echo "[INFO] Testing Jenkins at ${NODE_IP}:${JENKINS_PORT}"

# === [1] Check HTTP status ===
echo -e "\n[1] Checking HTTP response..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://${NODE_IP}:${JENKINS_PORT}" || echo "000")
echo "↳ HTTP status code: $HTTP_CODE"

if [[ "$HTTP_CODE" == "403" || "$HTTP_CODE" == "200" ]]; then
  echo "[OK] Jenkins service reachable"
else
  echo "[ERROR] Jenkins service unreachable or invalid response"
  exit 1
fi

# === [2] Try basic authentication (optional sanity check) ===
echo -e "\n[2] Testing authentication..."
AUTH_CODE=$(curl -s -o /dev/null -w "%{http_code}" -u "${JENKINS_USER}:${JENKINS_PASS}" "http://${NODE_IP}:${JENKINS_PORT}/login" || echo "000")
echo "↳ Auth test response code: $AUTH_CODE"

if [[ "$AUTH_CODE" == "200" || "$AUTH_CODE" == "403" ]]; then
  echo "[OK] Jenkins authentication endpoint responding"
else
  echo "[WARN] Jenkins authentication endpoint not reachable (HTTP $AUTH_CODE)"
fi

# === [3] Verify Pod and PVC ===
echo -e "\n[3] Checking Jenkins pod and PVC..."
kubectl get pods,pvc,svc -n apps -l app=jenkins || echo "[WARN] Jenkins resources not found"

echo -e "\n[DONE] Jenkins validation completed successfully"