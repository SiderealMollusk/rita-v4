#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../lib/runbook.sh"

runbook_require_no_args "$@"
REPO_ROOT="$(runbook_detect_repo_root)"
INV="$REPO_ROOT/ops/ansible/inventory/ops-brain.ini"
PB="$REPO_ROOT/ops/ansible/playbooks/27-sync-ops-brain-kubeconfig.yml"
GROUP_VARS="$REPO_ROOT/ops/ansible/group_vars/ops_brain.yml"

[ -f "$INV" ] || runbook_fail "inventory not found: $INV"
[ -f "$PB" ] || runbook_fail "playbook not found: $PB"
[ -f "$GROUP_VARS" ] || runbook_fail "missing group vars file at $GROUP_VARS"
runbook_refresh_known_hosts_from_inventory "$INV"

echo "[INFO] Syncing ops-brain kubeconfig for the ansible user"
ansible-playbook -i "$INV" "$PB" -e "@$GROUP_VARS"
