#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../lib/runbook.sh"

runbook_require_no_args "$@"
REPO_ROOT="$(runbook_detect_repo_root)"
INV="$REPO_ROOT/ops/ansible/inventory/observatory.ini"
PB="$REPO_ROOT/ops/ansible/playbooks/22-install-helm-observatory.yml"
GROUP_VARS="$REPO_ROOT/ops/ansible/group_vars/observatory.yml"

[ -f "$GROUP_VARS" ] || runbook_fail "missing group vars file at $GROUP_VARS"
runbook_refresh_known_hosts_from_inventory "$INV"

echo "[INFO] Installing Helm on observatory"
ansible-playbook -i "$INV" "$PB" -e "@$GROUP_VARS"
