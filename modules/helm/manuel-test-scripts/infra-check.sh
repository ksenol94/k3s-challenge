#!/usr/bin/env bash
set -euo pipefail

# --- Redis Check ---
echo "=== [ REDIS CHECK ] ==="
kubectl get pods,pvc,svc -n infra -l app=redis
REDIS_PASS=$(kubectl get secret -n infra redis-secret -o jsonpath='{.data.redis-password}' | base64 -d)
REDIS_HOST="192.168.64.22"; REDIS_PORT="30079"
echo "[INFO] Redis: ${REDIS_HOST}:${REDIS_PORT}"
redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" -a "$REDIS_PASS" PING || echo "Redis PING failed"

# --- PostgreSQL Check ---
echo -e "\n=== [ POSTGRES CHECK ] ==="
kubectl get pods,pvc,svc -n infra -l app=postgres
POSTGRES_PASS=$(kubectl get secret -n infra postgresql-secret -o jsonpath='{.data.postgres-password}' | base64 -d)
PG_HOST="192.168.64.22"; PG_PORT="30432"
echo "[INFO] PostgreSQL: ${PG_HOST}:${PG_PORT}"
PGPASSWORD="$POSTGRES_PASS" psql -h "$PG_HOST" -p "$PG_PORT" -U postgres -d postgres -c "SELECT version();" >/dev/null 2>&1 && echo "✔ PostgreSQL OK" || echo "✖ PostgreSQL unreachable"

# --- Jenkins Check ---
echo -e "\n=== [ JENKINS CHECK ] ==="
kubectl get pods,pvc,svc -n apps -l app=jenkins
JENKINS_HOST="192.168.64.22"; JENKINS_PORT="30808"
echo "[INFO] Jenkins: ${JENKINS_HOST}:${JENKINS_PORT}"
CODE=$(curl -s -o /dev/null -w "%{http_code}" http://${JENKINS_HOST}:${JENKINS_PORT})
[[ "$CODE" == "403" ]] && echo "✔ Jenkins login active (HTTP 403)" || echo "✖ Jenkins unexpected HTTP code: $CODE"

# 1️⃣ Validate pod replica count
echo -e "\n=== [ POD STATUS VALIDATION ] ==="
kubectl get pods -A --no-headers | awk '{print $1,$2,$3}' | while read -r ns status rest; do
  [[ "$status" == "1/1" ]] && echo "✔ $ns OK" || echo "✖ $ns pod not ready ($status)"
done

# 2️⃣ Validate PVC states
echo -e "\n=== [ PVC STATUS VALIDATION ] ==="
kubectl get pvc -A --no-headers | awk '{print $1,$2,$3}' | while read -r ns pvc status; do
  [[ "$status" == "Bound" ]] && echo "✔ $ns/$pvc Bound" || echo "✖ $ns/$pvc $status"
done

echo -e "\n[INFO] Validation completed successfully."