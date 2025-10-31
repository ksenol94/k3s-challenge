#!/usr/bin/env bash
set -euo pipefail

# Locate terraform.tfvars dynamically (project root)
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
TFVARS_FILE="${TFVARS_FILE:-${ROOT_DIR}/terraform.tfvars}"

# Namespace (default: infra)
NS=${NS:-infra}

# Read postgres_user and postgres_password from terraform.tfvars
PG_USER=$(grep -E '^postgres_user' "$TFVARS_FILE" | awk -F'=' '{gsub(/[[:space:]"]/,"",$2); print $2}')
PGPASSWORD=$(grep -E '^postgres_password' "$TFVARS_FILE" | awk -F'=' '{gsub(/[[:space:]"]/,"",$2); print $2}')

# Cluster information
NODE_IP=${NODE_IP:-"$(kubectl get nodes -o wide --no-headers | awk 'NR==1{print $6}')"}
PORT=${PORT:-30432}
DB=${DB:-appdb}

echo "[INFO] Using terraform vars from: $TFVARS_FILE"
echo "[INFO] PG_USER=$PG_USER"
echo "[INFO] NODE_IP=$NODE_IP PORT=$PORT DB=$DB"

# Connection test
echo "[STEP 1] Testing PostgreSQL connection..."
if psql "postgresql://$PG_USER:$PGPASSWORD@$NODE_IP:$PORT/$DB" -c '\l' | head -n 20; then
  echo "[OK] PostgreSQL connection successful."
else
  echo "[ERROR] Cannot connect to PostgreSQL at $NODE_IP:$PORT"
  exit 1
fi

# Backup directory check
echo "[STEP 2] Checking backup directory inside PVC..."
if ! kubectl -n "$NS" exec -it statefulset/postgresql -- ls -l /var/lib/postgresql/data/backups; then
  echo "[WARN] No backup directory found (possibly first run or backup not triggered yet)."
fi

echo "[DONE] PostgreSQL health and backup verification completed successfully"