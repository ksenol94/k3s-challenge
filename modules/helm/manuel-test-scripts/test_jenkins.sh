#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../" && pwd)"
TFVARS_FILE="${TFVARS_FILE:-${ROOT_DIR}/terraform.tfvars}"

JENKINS_USER=$(grep -E '^jenkins_user' "$TFVARS_FILE" | awk -F'=' '{gsub(/[[:space:]"]/,"",$2); print $2}')
JENKINS_PASS=$(grep -E '^jenkins_password' "$TFVARS_FILE" | awk -F'=' '{gsub(/[[:space:]"]/,"",$2); print $2}')
NODE_IP=${NODE_IP:-"$(kubectl get nodes -o wide --no-headers | awk 'NR==1{print $6}')"}
JENKINS_PORT=${JENKINS_PORT:-32000}

echo "[INFO] Testing Jenkins at ${NODE_IP}:${JENKINS_PORT}"

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://${NODE_IP}:${JENKINS_PORT}")
echo "↳ HTTP status: $HTTP_CODE"

if [[ "$HTTP_CODE" == "403" || "$HTTP_CODE" == "200" ]]; then
  echo "[OK] Jenkins service reachable"
else
  echo "[ERROR] Jenkins not reachable (HTTP $HTTP_CODE)"
  exit 1
fi

AUTH_CODE=$(curl -s -o /dev/null -w "%{http_code}" -u "${JENKINS_USER}:${JENKINS_PASS}" "http://${NODE_IP}:${JENKINS_PORT}/login")
echo "↳ Auth test: HTTP $AUTH_CODE"

if [[ "$AUTH_CODE" == "200" || "$AUTH_CODE" == "403" ]]; then
  echo "[OK] Jenkins authentication endpoint responding"
else
  echo "[WARN] Jenkins auth failed (HTTP $AUTH_CODE)"
fi

kubectl get pods,pvc,svc -n apps -l app=jenkins || echo "[WARN] Jenkins resources not found"

echo -e "\n[DONE] Jenkins validation completed successfully"