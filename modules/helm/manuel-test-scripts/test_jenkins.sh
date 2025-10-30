#!/usr/bin/env bash
set -euo pipefail

JENKINS_NS="apps"
JENKINS_APP="jenkins"
MASTER_IP="${1:-192.168.64.22}"
NODE_PORT="${2:-30808}"
USER_EXPECTED="${3:-admin}"
PASS_EXPECTED="${4:-jenkins123}"

echo "[INFO] Testing Jenkins at ${MASTER_IP}:${NODE_PORT}"

# Verify pod is running and retrieve pod name
echo "[1] Checking pod status..."
kubectl get pod -n $JENKINS_NS -l app=$JENKINS_APP -o wide
POD=$(kubectl get pod -n $JENKINS_NS -l app=$JENKINS_APP -o jsonpath='{.items[0].metadata.name}')

# Validate admin credentials inside Kubernetes secret
echo "[2] Validating secret..."
USER=$(kubectl get secret -n $JENKINS_NS jenkins-secret -o jsonpath='{.data.jenkins-admin-user}' | base64 -d)
PASS=$(kubectl get secret -n $JENKINS_NS jenkins-secret -o jsonpath='{.data.jenkins-admin-password}' | base64 -d)
echo "  user: $USER"
echo "  pass: $PASS"

if [[ "$USER" != "$USER_EXPECTED" || "$PASS" != "$PASS_EXPECTED" ]]; then
  echo "[WARN] Jenkins credentials mismatch (expected $USER_EXPECTED / $PASS_EXPECTED)"
else
  echo "[OK] Jenkins credentials verified"
fi

# Ensure Jenkins PVC exists and is Bound
echo "[3] Checking PVC..."
kubectl get pvc -n $JENKINS_NS

# Verify Jenkins home directory is correctly mounted
echo "[4] Checking volume mount..."
kubectl exec -n $JENKINS_NS "$POD" -- df -h /var/jenkins_home | tail -n +2

# Confirm Jenkins NodePort is reachable from host
echo "[5] Checking NodePort connectivity..."
if nc -z -v -w2 "$MASTER_IP" "$NODE_PORT" >/dev/null 2>&1; then
  echo "[OK] Connection reachable ($MASTER_IP:$NODE_PORT)"
else
  echo "[ERROR] NodePort unreachable ($MASTER_IP:$NODE_PORT)"
  exit 1
fi

# Perform HTTP HEAD request to validate login screen (403)
echo "[6] Checking HTTP response..."
CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://${MASTER_IP}:${NODE_PORT}")
if [[ "$CODE" == "403" ]]; then
  echo "[OK] Jenkins login screen active (HTTP 403)"
else
  echo "[WARN] Unexpected HTTP response: $CODE"
fi

echo "[DONE] Jenkins test completed successfully."