#!/usr/bin/env bash
set -euo pipefail
 
# === Path setup ===
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../" && pwd)"
TFVARS_FILE="${TFVARS_FILE:-${ROOT_DIR}/terraform.tfvars}"
 
# === Extract values from terraform.tfvars ===
REDIS_PASS=$(awk -F'=' '/redis_password/ {gsub(/[[:space:]"]/,"",$2); print $2}' "$TFVARS_FILE")
PG_USER=$(awk -F'=' '/postgres_user/ {gsub(/[[:space:]"]/,"",$2); print $2}' "$TFVARS_FILE")
PG_PASS=$(awk -F'=' '/postgres_password/ {gsub(/[[:space:]"]/,"",$2); print $2}' "$TFVARS_FILE")
JENKINS_USER=$(awk -F'=' '/jenkins_admin_user/ {gsub(/[[:space:]"]/,"",$2); print $2}' "$TFVARS_FILE")
JENKINS_PASS=$(awk -F'=' '/jenkins_admin_pass/ {gsub(/[[:space:]"]/,"",$2); print $2}' "$TFVARS_FILE")
 
# === Get cluster info dynamically ===
NODE_IP=${NODE_IP:-"$(kubectl get nodes -o wide --no-headers | awk 'NR==1{print $6}')"}
REDIS_PORT=${REDIS_PORT:-30379}
PG_PORT=${PG_PORT:-30432}
JENKINS_PORT=${JENKINS_PORT:-32000}
 
echo "[INFO] Using terraform vars from: $TFVARS_FILE"
echo "[INFO] NODE_IP=$NODE_IP"
 
# === REDIS CHECK ===
echo
echo "=== [ REDIS CHECK ] ==="
kubectl get pods,pvc,svc -n infra -l app=redis
echo "[INFO] Redis endpoint: ${NODE_IP}:${REDIS_PORT}"
if redis-cli -h "$NODE_IP" -p "$REDIS_PORT" -a "$REDIS_PASS" PING >/dev/null 2>&1; then
  echo "✔ Redis PING successful"
else
  echo "✖ Redis PING failed"
fi
 
# === POSTGRES CHECK ===
echo
echo "=== [ POSTGRES CHECK ] ==="
kubectl get pods,pvc,svc -n infra -l app=postgresql
echo "[INFO] PostgreSQL endpoint: ${NODE_IP}:${PG_PORT}"
if PGPASSWORD="$PG_PASS" psql -h "$NODE_IP" -p "$PG_PORT" -U "$PG_USER" -d appdb -c "SELECT version();" >/dev/null 2>&1; then
  echo "✔ PostgreSQL reachable"
else
  echo "✖ PostgreSQL connection failed"
fi
 
# === JENKINS CHECK ===
echo
echo "=== [ JENKINS CHECK ] ==="
kubectl get pods,pvc,svc -n apps -l app=jenkins
echo "[INFO] Jenkins endpoint: ${NODE_IP}:${JENKINS_PORT}"
CODE=$(curl -s -u "${JENKINS_USER}:${JENKINS_PASS}" -o /dev/null -w "%{http_code}" http://${NODE_IP}:${JENKINS_PORT})
if [[ "$CODE" == "200" || "$CODE" == "403" ]]; then
  echo "✔ Jenkins HTTP ${CODE} (reachable)"
else
  echo "✖ Jenkins unexpected HTTP code: $CODE"
fi
 
# === POD STATUS VALIDATION ===
echo
echo "=== [ POD STATUS VALIDATION ] ==="
kubectl get pods -A --no-headers | awk '{ns=$1; pod=$2; ready=$3; status=$4; print ns,pod,ready,status}' | \
while read -r ns pod ready status; do
  if [[ "$ready" == "1/1" || "$ready" == "2/2" ]]; then
    echo "✔ $ns/$pod ready ($ready $status)"
  else
    echo "✖ $ns/$pod not ready ($ready $status)"
  fi
done
 
# === PVC STATUS VALIDATION ===
echo
echo "=== [ PVC STATUS VALIDATION ] ==="
kubectl get pvc -A --no-headers | awk '{ns=$1; pvc=$2; status=$3; print ns,pvc,status}' | \
while read -r ns pvc status; do
  if [[ "$status" == "Bound" ]]; then
    echo "✔ $ns/$pvc Bound"
  else
    echo "✖ $ns/$pvc $status"
  fi
done
 
echo
echo "[INFO] Infrastructure validation completed successfully"
 