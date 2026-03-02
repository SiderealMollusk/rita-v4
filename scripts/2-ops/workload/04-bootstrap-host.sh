#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../lib/runbook.sh"

runbook_require_no_args "$@"
REPO_ROOT="$(runbook_detect_repo_root)"
INV="$REPO_ROOT/ops/ansible/inventory/workload.ini"
PB="$REPO_ROOT/ops/ansible/playbooks/14-bootstrap-workload.yml"
WORKLOAD_VARS="$REPO_ROOT/ops/ansible/group_vars/workload.yml"

[ -f "$WORKLOAD_VARS" ] || runbook_fail "missing group vars file at $WORKLOAD_VARS"
runbook_refresh_known_hosts_from_inventory "$INV"

echo "[INFO] Running workload bootstrap playbook"
ansible-playbook -i "$INV" "$PB" -e "@$WORKLOAD_VARS"
