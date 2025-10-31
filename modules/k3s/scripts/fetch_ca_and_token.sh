#!/usr/bin/env bash
set -euo pipefail

HOST="$1"
USER="$2"
SSH_KEY="$3"
LOCAL_CA="$4"
LOCAL_TOKEN="$5"

CA_PATH="/var/lib/rancher/k3s/server/tls/server-ca.crt"
TOKEN_PATH="/var/lib/rancher/k3s/server/terraform-token.txt"

echo "[INFO] Fetching CA and Terraform token from master ($HOST)..."

# Fetch CA
if ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$USER@$HOST" "sudo test -f $CA_PATH"; then
  ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$USER@$HOST" "sudo cat $CA_PATH" > "$LOCAL_CA"
  echo "[OK] CA successfully retrieved → $LOCAL_CA"
else
  echo "[WARN] CA CA file not found at: $CA_PATH"
fi

# Fetch Token
if ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$USER@$HOST" "sudo test -f $TOKEN_PATH"; then
  ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$USER@$HOST" "sudo cat $TOKEN_PATH" > "$LOCAL_TOKEN"
  echo "[OK]  Token successfully retrieved → $LOCAL_TOKEN"
else
  echo "[ERROR] Token file not found at: $TOKEN_PATH" >&2
  exit 1
fi

echo "[DONE] CA and Token fetch operation completed successfully."