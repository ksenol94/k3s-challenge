#!/usr/bin/env bash
set -euo pipefail

# Locate terraform.tfvars dynamically (project root)
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
TFVARS_FILE="${TFVARS_FILE:-${ROOT_DIR}/terraform.tfvars}"

# Extract Redis credentials
REDIS_PASS=$(grep -E '^redis_password' "$TFVARS_FILE" | awk -F'=' '{gsub(/[[:space:]"]/,"",$2); print $2}')

# Cluster connection info
NODE_IP=${NODE_IP:-"$(kubectl get nodes -o wide --no-headers | awk 'NR==1{print $6}')"}
REDIS_PORT=${REDIS_PORT:-30379}

echo "[INFO] Using terraform vars from: $TFVARS_FILE"
echo "[INFO] Testing Redis at ${NODE_IP}:${REDIS_PORT}"

# Connectivity test
echo -e "\n[1] Checking PING..."
PING_OUT=$(redis-cli -h "$NODE_IP" -p "$REDIS_PORT" -a "$REDIS_PASS" PING 2>&1 || true)
PING_LAST=$(echo "$PING_OUT" | tail -n 1)
echo "↳ redis-cli PING output: $PING_LAST"
if [[ "$PING_LAST" == "PONG" ]]; then
  echo "[OK] Redis connection successful"
else
  echo "[ERROR] Redis connection failed"
  exit 1
fi

# Basic SET/GET test
echo -e "\n[2] Testing SET/GET..."
SET_OUT=$(redis-cli -h "$NODE_IP" -p "$REDIS_PORT" -a "$REDIS_PASS" SET testkey "Redis_OK" 2>&1 || true)
GET_OUT=$(redis-cli -h "$NODE_IP" -p "$REDIS_PORT" -a "$REDIS_PASS" GET testkey 2>&1 || true)
SET_LAST=$(echo "$SET_OUT" | tail -n 1)
GET_LAST=$(echo "$GET_OUT" | tail -n 1)
echo "↳ SET output: $SET_LAST"
echo "↳ GET output: $GET_LAST"

if [[ "$GET_LAST" == "Redis_OK" ]]; then
  echo "[OK] Redis SET/GET successful"
else
  echo "[ERROR] Redis SET/GET failed"
  exit 1
fi

# PVC validation
echo -e "\n[3] Checking PVC..."
kubectl get pvc -n infra -l app=redis || echo "[WARN] PVC not found"

# NodePort reachability
echo -e "\n[4] Checking NodePort reachability..."
if nc -zv "$NODE_IP" "$REDIS_PORT" >/dev/null 2>&1; then
  echo "[OK] NodePort reachable"
else
  echo "[ERROR] NodePort unreachable"
  exit 1
fi

echo -e "\n[DONE] Redis validation completed successfully"