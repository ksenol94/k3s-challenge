#!/usr/bin/env bash
set -euo pipefail

TOKEN_PATH="$1"
TIMEOUT="${2:-60}"
INTERVAL=2

echo "[INFO] Waiting for Terraform token to appear at: $TOKEN_PATH"

count=0
while [ ! -s "$TOKEN_PATH" ]; do
  if [ $count -ge "$TIMEOUT" ]; then
    echo "HATA: Token ${TIMEOUT} saniyede oluşturulamadı." >&2
    exit 1
  fi
  echo "[WAIT] Token oluşturulması bekleniyor... (${count}s)"
  sleep "$INTERVAL"
  count=$((count + INTERVAL))
done

echo "[OK] Token bulundu: $TOKEN_PATH"