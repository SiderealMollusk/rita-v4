#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../lib/runbook.sh"

runbook_require_no_args "$@"
REPO_ROOT="$(runbook_detect_repo_root)"
INV="$REPO_ROOT/ops/ansible/inventory/n8n-cluster.ini"
PB="$REPO_ROOT/ops/ansible/playbooks/28-install-k3s-workload-agent.yml"
INTERNAL_VARS="$REPO_ROOT/ops/ansible/group_vars/internal_cluster.yml"
WORKLOAD_VARS="$REPO_ROOT/ops/ansible/group_vars/workload.yml"
N8N_WORKER_VARS="$REPO_ROOT/ops/ansible/group_vars/n8n_worker.yml"

[ -f "$INTERNAL_VARS" ] || runbook_fail "missing group vars file at $INTERNAL_VARS"
[ -f "$WORKLOAD_VARS" ] || runbook_fail "missing group vars file at $WORKLOAD_VARS"
[ -f "$N8N_WORKER_VARS" ] || runbook_fail "missing group vars file at $N8N_WORKER_VARS"
runbook_refresh_known_hosts_from_inventory "$INV"

echo "[INFO] Joining n8n worker to the internal k3s cluster"
ansible-playbook -i "$INV" "$PB" -e "@$INTERNAL_VARS" -e "@$WORKLOAD_VARS" -e "@$N8N_WORKER_VARS"
