#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../lib/runbook.sh"

runbook_require_no_args "$@"
REPO_ROOT="$(runbook_detect_repo_root)"

INV="$REPO_ROOT/ops/ansible/inventory/vps.ini"
PB="$REPO_ROOT/ops/ansible/playbooks/40-apply-secret-bridge.yml"
LABRC="$REPO_ROOT/.labrc"

runbook_require_env OP_SERVICE_ACCOUNT_TOKEN \
  "This token is required to create/update the op-token secret on the VPS cluster."

if [ ! -f "$LABRC" ]; then
  runbook_fail "missing .labrc at $LABRC"
fi

# shellcheck source=/dev/null
source "$LABRC"
runbook_require_env OP_VAULT_ID "Set OP_VAULT_ID in .labrc."

if [ -z "${PANGOLIN_ENDPOINT:-}" ]; then
  echo "[INFO] PANGOLIN_ENDPOINT is unset in current shell."
  echo "[INFO] Run: source \"$REPO_ROOT/scripts/1-session/01-load-variables.sh\""
fi

echo "[INFO] Applying SecretStore and ExternalSecret bridge"
ansible-playbook -i "$INV" "$PB" -e "op_vault_id=$OP_VAULT_ID"
