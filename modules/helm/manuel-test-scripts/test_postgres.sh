#!/usr/bin/env bash
set -euo pipefail

PG_HOST="${1:-192.168.64.22}"
PG_PORT="${2:-30432}"
PG_USER="${3:-postgres}"
PG_PASS="${4:-postgres123}"
PG_DB="${5:-postgres}"

export PGPASSWORD="$PG_PASS"

echo "[INFO] Testing PostgreSQL at ${PG_HOST}:${PG_PORT}"

# Connection and version check
echo "[1] Checking connection and version..."
if psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$PG_DB" -c "SELECT version();" >/dev/null 2>&1; then
  echo "[OK] PostgreSQL reachable"
else
  echo "[ERROR] Cannot connect to PostgreSQL"
  exit 1
fi

# CRUD validation
echo "[2] Testing CRUD operations..."
psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$PG_DB" -c "CREATE DATABASE tf_test;" >/dev/null 2>&1 || true
psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d tf_test -c "
CREATE TABLE IF NOT EXISTS sanity_check (id SERIAL PRIMARY KEY, message TEXT);
INSERT INTO sanity_check (message) VALUES ('PostgreSQL OK');
SELECT * FROM sanity_check;" >/dev/null
echo "[OK] CRUD test executed successfully"

# PVC status
echo "[3] Checking PVC..."
kubectl get pvc -n infra -l app=postgres || echo "[WARN] PVC not found"

# Pod restart + data persistence
echo "[4] Restarting PostgreSQL pod..."
POD=$(kubectl get pod -n infra -l app=postgres -o jsonpath='{.items[0].metadata.name}')
kubectl delete pod "$POD" -n infra --wait >/dev/null
sleep 15
NEW_POD=$(kubectl get pod -n infra -l app=postgres -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n infra "$NEW_POD" -- psql -U "$PG_USER" -d tf_test -c "SELECT * FROM sanity_check;" >/dev/null && \
echo "[OK] Data persisted successfully after pod restart"

# NodePort connectivity
echo "[5] Checking NodePort reachability..."
if nc -zv "$PG_HOST" "$PG_PORT" >/dev/null 2>&1; then
  echo "[OK] NodePort reachable"
else
  echo "[ERROR] NodePort unreachable"
  exit 1
fi

echo "[DONE] PostgreSQL validation completed successfully."