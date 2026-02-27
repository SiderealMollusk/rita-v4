#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../lib/runbook.sh"

runbook_require_no_args "$@"
REPO_ROOT="$(runbook_detect_repo_root)"

INV="$REPO_ROOT/ops/ansible/inventory/vps.ini"
GROUP_VARS="$REPO_ROOT/ops/ansible/group_vars/vps.yml"

if [ ! -f "$GROUP_VARS" ]; then
  runbook_fail "missing group vars file at $GROUP_VARS"
fi

ESO_NAMESPACE="$(runbook_yaml_get "$GROUP_VARS" "eso_namespace" || true)"
[ -n "$ESO_NAMESPACE" ] || runbook_fail "eso_namespace missing in $GROUP_VARS"
EXPECTED_SECRET_VALUE="$(runbook_yaml_get "$GROUP_VARS" "test_secret_expected_value" || true)"
[ -n "$EXPECTED_SECRET_VALUE" ] || runbook_fail "test_secret_expected_value missing in $GROUP_VARS"

echo "[INFO] Using inventory: $INV"
ansible-inventory -i "$INV" --list >/dev/null
ansible -i "$INV" vps -m ping -b >/dev/null
echo "[OK] ansible connectivity confirmed"

ansible -i "$INV" vps -b -m shell -a "kubectl version --request-timeout=10s >/dev/null"
echo "[OK] kubernetes API reachable on VPS"

ansible -i "$INV" vps -b -m shell -a "kubectl get secretstore onepassword-store -n $ESO_NAMESPACE -o jsonpath='{.status.conditions[?(@.type==\"Ready\")].status}' | grep -q '^True$'"
echo "[OK] SecretStore onepassword-store is Ready"

ansible -i "$INV" vps -b -m shell -a "kubectl get externalsecret lab-test-sync -n $ESO_NAMESPACE -o jsonpath='{.status.conditions[?(@.type==\"Ready\")].status}' | grep -q '^True$'"
echo "[OK] ExternalSecret lab-test-sync is Ready"

ansible -i "$INV" vps -b -m shell -a "val=\$(kubectl get secret rita-test-k8s-secret -n $ESO_NAMESPACE -o jsonpath='{.data.my-test-value}' | base64 -d); test \"\$val\" = \"$EXPECTED_SECRET_VALUE\""
echo "[OK] secret pipeline validated (decoded value: $EXPECTED_SECRET_VALUE)"

if ansible -i "$INV" vps -b -m shell -a "command -v pangolin >/dev/null"; then
  echo "[OK] pangolin CLI is installed on VPS"
else
  echo "[FAIL] pangolin CLI is not installed on VPS"
  echo "[INFO] Install it with:"
  echo "       ansible -i \"$INV\" vps -b -m shell -a 'curl -fsSL https://static.pangolin.net/get-cli.sh | bash'"
  exit 1
fi

echo "[OK] VPS preflight complete"
