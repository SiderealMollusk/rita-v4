#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../lib/runbook.sh"

runbook_require_no_args "$@"
REPO_ROOT="$(runbook_detect_repo_root)"

INV="$REPO_ROOT/ops/ansible/inventory/vps.ini"
PB="$REPO_ROOT/ops/ansible/playbooks/40-apply-secret-bridge.yml"
GROUP_VARS="$REPO_ROOT/ops/ansible/group_vars/vps.yml"
ROUTES_VARS="$REPO_ROOT/ops/network/routes.yml"

runbook_require_env OP_SERVICE_ACCOUNT_TOKEN \
  "This token is required to create/update the op-token secret on the VPS cluster."

if [ ! -f "$GROUP_VARS" ]; then
  runbook_fail "missing group vars file at $GROUP_VARS"
fi

OP_VAULT_ID="$(runbook_yaml_get "$GROUP_VARS" "op_vault_id" || true)"
[ -n "$OP_VAULT_ID" ] || runbook_fail "op_vault_id missing in $GROUP_VARS"

PANGOLIN_ENDPOINT="$(runbook_yaml_get "$ROUTES_VARS" "pangolin_endpoint" || true)"
if [ -n "$PANGOLIN_ENDPOINT" ]; then
  echo "[INFO] Route endpoint from ops/network/routes.yml: $PANGOLIN_ENDPOINT"
fi

echo "[INFO] Applying SecretStore and ExternalSecret bridge"
ansible-playbook -i "$INV" "$PB" -e "@$GROUP_VARS" -e "op_vault_id=$OP_VAULT_ID"
