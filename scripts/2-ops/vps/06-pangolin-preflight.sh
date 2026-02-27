#!/bin/bash
set -euo pipefail

if [ "$#" -ne 0 ]; then
  echo "[FAIL] This runbook script takes no arguments."
  echo "Use: $(basename "$0")"
  exit 1
fi

if [ -d /workspaces/rita-v4 ]; then
  REPO_ROOT="/workspaces/rita-v4"
elif [ -d /Users/virgil/Dev/rita-v4 ]; then
  REPO_ROOT="/Users/virgil/Dev/rita-v4"
else
  echo "[FAIL] Could not locate repo root."
  exit 1
fi

INV="$REPO_ROOT/ops/ansible/inventory/vps.ini"

echo "[INFO] Using inventory: $INV"
ansible-inventory -i "$INV" --list >/dev/null
ansible -i "$INV" vps -m ping -b >/dev/null
echo "[OK] ansible connectivity confirmed"

ansible -i "$INV" vps -b -m shell -a "kubectl version --request-timeout=10s >/dev/null"
echo "[OK] kubernetes API reachable on VPS"

ansible -i "$INV" vps -b -m shell -a "kubectl get secretstore onepassword-store -n external-secrets -o jsonpath='{.status.conditions[?(@.type==\"Ready\")].status}' | grep -q '^True$'"
echo "[OK] SecretStore onepassword-store is Ready"

ansible -i "$INV" vps -b -m shell -a "kubectl get externalsecret lab-test-sync -n external-secrets -o jsonpath='{.status.conditions[?(@.type==\"Ready\")].status}' | grep -q '^True$'"
echo "[OK] ExternalSecret lab-test-sync is Ready"

ansible -i "$INV" vps -b -m shell -a "val=\$(kubectl get secret rita-test-k8s-secret -n external-secrets -o jsonpath='{.data.my-test-value}' | base64 -d); test \"\$val\" = \"bar\""
echo "[OK] secret pipeline validated (decoded value: bar)"

echo "[OK] VPS preflight complete"
