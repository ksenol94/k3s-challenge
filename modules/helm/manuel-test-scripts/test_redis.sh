#!/usr/bin/env bash
set -euo pipefail

REDIS_HOST="${1:-192.168.64.22}"
REDIS_PORT="${2:-30379}"
REDIS_PASS="${3:-redis123}"

echo "[INFO] Testing Redis at ${REDIS_HOST}:${REDIS_PORT}"

# === [1] Ping test ===
echo "[1] Checking connectivity..."
if redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" -a "$REDIS_PASS" PING | grep -q "PONG"; then
  echo "[OK] Redis connection successful"
else
  echo "[ERROR] Redis connection failed"
  exit 1
fi

# === [2] SET + GET validation ===
echo "[2] Testing basic SET/GET..."
redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" -a "$REDIS_PASS" SET testkey "Redis_OK" >/dev/null
VALUE=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" -a "$REDIS_PASS" GET testkey)
if [[ "$VALUE" == "Redis_OK" ]]; then
  echo "[OK] Redis SET/GET successful"
else
  echo "[ERROR] Redis SET/GET failed"
  exit 1
fi

# PVC status
echo "[3] Checking PVC..."
kubectl get pvc -n infra -l app=redis || echo "[WARN] PVC not found"

# Pod restart + data persistence
echo "[4] Restarting Redis pod..."
POD=$(kubectl get pod -n infra -l app=redis -o jsonpath='{.items[0].metadata.name}')
kubectl delete pod "$POD" -n infra --wait >/dev/null
sleep 10
NEW_POD=$(kubectl get pod -n infra -l app=redis -o jsonpath='{.items[0].metadata.name}')
VALUE_AFTER=$(kubectl exec -n infra "$NEW_POD" -- redis-cli -a "$REDIS_PASS" GET testkey)
if [[ "$VALUE_AFTER" == "Redis_OK" ]]; then
  echo "[OK] Data persisted successfully after pod restart"
else
  echo "[WARN] Data not persisted after pod restart"
fi

# NodePort connectivity
echo "[5] Checking NodePort reachability..."
if nc -zv "$REDIS_HOST" "$REDIS_PORT" >/dev/null 2>&1; then
  echo "[OK] NodePort reachable"
else
  echo "[ERROR] NodePort unreachable"
  exit 1
fi

echo "[DONE] Redis validation completed successfully."