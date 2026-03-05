#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../lib/runbook.sh"

runbook_require_no_args "$@"
runbook_require_host_terminal
runbook_require_cmd ssh
runbook_require_cmd kubectl
REPO_ROOT="$(runbook_detect_repo_root)"
INV="$REPO_ROOT/ops/ansible/inventory/n8n-cluster.ini"
N8N_INV="$REPO_ROOT/ops/ansible/inventory/n8n.ini"
PB="$REPO_ROOT/ops/ansible/playbooks/28-install-k3s-workload-agent.yml"
INTERNAL_VARS="$REPO_ROOT/ops/ansible/group_vars/internal_cluster.yml"
WORKLOAD_VARS="$REPO_ROOT/ops/ansible/group_vars/workload.yml"
N8N_WORKER_VARS="$REPO_ROOT/ops/ansible/group_vars/n8n_worker.yml"

[ -f "$INTERNAL_VARS" ] || runbook_fail "missing group vars file at $INTERNAL_VARS"
[ -f "$WORKLOAD_VARS" ] || runbook_fail "missing group vars file at $WORKLOAD_VARS"
[ -f "$N8N_WORKER_VARS" ] || runbook_fail "missing group vars file at $N8N_WORKER_VARS"
[ -f "$N8N_INV" ] || runbook_fail "inventory not found: $N8N_INV"
runbook_source_labrc "$REPO_ROOT"
runbook_export_default_kubeconfig
runbook_refresh_known_hosts_from_inventory "$INV"

N8N_HOST="$(runbook_inventory_get_field "$N8N_INV" "n8n-vm" "ansible_host")"
NODE_NAME="$(runbook_yaml_get "$N8N_WORKER_VARS" "workload_expected_hostname" || true)"
[ -n "$N8N_HOST" ] || runbook_fail "Could not resolve n8n-vm ansible_host from $N8N_INV"
[ -n "$NODE_NAME" ] || runbook_fail "Could not resolve workload_expected_hostname from $N8N_WORKER_VARS"

run_join_playbook() {
  ansible-playbook -i "$INV" "$PB" -e "@$INTERNAL_VARS" -e "@$WORKLOAD_VARS" -e "@$N8N_WORKER_VARS"
}

recover_duplicate_node_identity() {
  echo "[WARN] k3s agent join failed; attempting duplicate-node identity recovery for ${NODE_NAME}"
  ssh "virgil@${N8N_HOST}" "sudo systemctl stop k3s-agent || true; sudo rm -rf /etc/rancher/node /var/lib/rancher/k3s/agent"
  kubectl delete node "$NODE_NAME" --ignore-not-found=true >/dev/null 2>&1 || true
  kubectl -n kube-system delete secret "${NODE_NAME}.node-password.k3s" --ignore-not-found=true >/dev/null 2>&1 || true
  sleep 4
}

echo "[INFO] Joining n8n worker to the internal k3s cluster"
if ! run_join_playbook; then
  recover_duplicate_node_identity
  echo "[INFO] Retrying n8n worker join after identity recovery"
  run_join_playbook || runbook_fail "n8n worker join failed after automatic duplicate-node recovery"
fi
