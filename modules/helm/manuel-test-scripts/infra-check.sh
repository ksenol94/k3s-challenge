#!/usr/bin/env bash
set -euo pipefail

# Locate terraform.tfvars dynamically (project root)
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
TFVARS_FILE="${TFVARS_FILE:-${ROOT_DIR}/terraform.tfvars}"

# Extract credentials from terraform.tfvars
REDIS_PASS=$(grep -E '^redis_password' "$TFVARS_FILE" | awk -F'=' '{gsub(/[[:space:]"]/,"",$2); print $2}')
PG_USER=$(grep -E '^postgres_user' "$TFVARS_FILE" | awk -F'=' '{gsub(/[[:space:]"]/,"",$2); print $2}')
PG_PASS=$(grep -E '^postgres_password' "$TFVARS_FILE" | awk -F'=' '{gsub(/[[:space:]"]/,"",$2); print $2}')
JENKINS_USER=$(grep -E '^jenkins_admin_user' "$TFVARS_FILE" | awk -F'=' '{gsub(/[[:space:]"]/,"",$2); print $2}')
JENKINS_PASS=$(grep -E '^jenkins_admin_pass' "$TFVARS_FILE" | awk -F'=' '{gsub(/[[:space:]"]/,"",$2); print $2}')

# Get cluster info dynamically
NODE_IP=${NODE_IP:-"$(kubectl get nodes -o wide --no-headers | awk 'NR==1{print $6}')"}
REDIS_PORT=${REDIS_PORT:-30379}
PG_PORT=${PG_PORT:-30432}
JENKINS_PORT=${JENKINS_PORT:-32000}

echo "[INFO] Using terraform vars from: $TFVARS_FILE"
echo "[INFO] NODE_IP=$NODE_IP"

# Redis Check
echo -e "\n=== [ REDIS CHECK ] ==="
kubectl get pods,pvc,svc -n infra -l app=redis
echo "[INFO] Redis endpoint: ${NODE_IP}:${REDIS_PORT}"
if redis-cli -h "$NODE_IP" -p "$REDIS_PORT" -a "$REDIS_PASS" PING >/dev/null 2>&1; then
  echo "✔ Redis PING successful"
else
  echo "✖ Redis PING failed"
fi

# Postgres Check
echo -e "\n=== [ POSTGRES CHECK ] ==="
kubectl get pods,pvc,svc -n infra -l app=postgresql
echo "[INFO] PostgreSQL endpoint: ${NODE_IP}:${PG_PORT}"
if PGPASSWORD="$PG_PASS" psql -h "$NODE_IP" -p "$PG_PORT" -U "$PG_USER" -d appdb -c "SELECT version();" >/dev/null 2>&1; then
  echo "✔ PostgreSQL reachable"
else
  echo "✖ PostgreSQL connection failed"
fi

# Jenkins Check
echo -e "\n=== [ JENKINS CHECK ] ==="
kubectl get pods,pvc,svc -n apps -l app=jenkins
echo "[INFO] Jenkins endpoint: ${NODE_IP}:${JENKINS_PORT}"
CODE=$(curl -s -u "${JENKINS_USER}:${JENKINS_PASS}" -o /dev/null -w "%{http_code}" http://${NODE_IP}:${JENKINS_PORT})
if [[ "$CODE" == "200" || "$CODE" == "403" ]]; then
  echo "✔ Jenkins HTTP ${CODE} (reachable)"
else
  echo "✖ Jenkins unexpected HTTP code: $CODE"
fi

# POD Status Validation
echo -e "\n=== [ POD STATUS VALIDATION ] ==="
kubectl get pods -A --no-headers | awk '{print $1,$2,$3}' | while read -r ns status rest; do
  if [[ "$status" == "1/1" ]]; then
    echo "✔ $ns pod ready ($status)"
  else
    echo "✖ $ns pod not ready ($status)"
  fi
done

# PVC Status Validation
echo -e "\n=== [ PVC STATUS VALIDATION ] ==="
kubectl get pvc -A --no-headers | awk '{print $1,$2,$3}' | while read -r ns pvc status; do
  if [[ "$status" == "Bound" ]]; then
    echo "✔ $ns/$pvc Bound"
  else
    echo "✖ $ns/$pvc $status"
  fi
done

echo -e "\n[INFO] Infrastructure validation completed successfully"