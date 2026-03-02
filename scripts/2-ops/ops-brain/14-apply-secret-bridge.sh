#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../lib/runbook.sh"

runbook_require_no_args "$@"
REPO_ROOT="$(runbook_detect_repo_root)"
INV="$REPO_ROOT/ops/ansible/inventory/ops-brain.ini"
PB="$REPO_ROOT/ops/ansible/playbooks/42-apply-secret-bridge-internal.yml"
GROUP_VARS="$REPO_ROOT/ops/ansible/group_vars/ops_brain.yml"

[ -f "$GROUP_VARS" ] || runbook_fail "missing group vars file at $GROUP_VARS"
[ -n "${OP_SERVICE_ACCOUNT_TOKEN:-}" ] || runbook_fail "Set OP_SERVICE_ACCOUNT_TOKEN before applying the internal secret bridge."
runbook_refresh_known_hosts_from_inventory "$INV"

echo "[INFO] Applying 1Password secret bridge on internal cluster"
ansible-playbook -i "$INV" "$PB" -e "@$GROUP_VARS"
