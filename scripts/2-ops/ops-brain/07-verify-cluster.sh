#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../lib/runbook.sh"

runbook_require_no_args "$@"
REPO_ROOT="$(runbook_detect_repo_root)"
INV="$REPO_ROOT/ops/ansible/inventory/ops-brain.ini"
GROUP_VARS="$REPO_ROOT/ops/ansible/group_vars/ops_brain.yml"

[ -f "$GROUP_VARS" ] || runbook_fail "missing group vars file at $GROUP_VARS"
[ -f "$INV" ] || runbook_fail "inventory not found: $INV"
runbook_refresh_known_hosts_from_inventory "$INV"

OPS_BRAIN_ROLE_LABEL="$(runbook_yaml_get "$GROUP_VARS" "ops_brain_k3s_role_label" || true)"
[ -n "$OPS_BRAIN_ROLE_LABEL" ] || runbook_fail "ops_brain_k3s_role_label missing in $GROUP_VARS"

OPS_BRAIN_ANSIBLE_USER="$(awk '
  /^\[/ { next }
  $0 !~ /^[[:space:]]*#/ && NF > 0 {
    for (i=1; i<=NF; i++) {
      if ($i ~ /^ansible_user=/) { split($i,a,"="); print a[2]; exit }
    }
  }
' "$INV")"
[ -n "$OPS_BRAIN_ANSIBLE_USER" ] || runbook_fail "could not determine ansible_user from $INV"

OPS_BRAIN_KUBECONFIG="/home/${OPS_BRAIN_ANSIBLE_USER}/.kube/config"
KUBE_ENV="export KUBECONFIG=${OPS_BRAIN_KUBECONFIG}"

echo "[INFO] Verifying kubeconfig exists for virgil"
ansible -i "$INV" ops_brain -m shell -a "test -f \"$OPS_BRAIN_KUBECONFIG\""

echo "[INFO] Verifying kubectl can see nodes"
ansible -i "$INV" ops_brain -m shell -a "$KUBE_ENV && kubectl get nodes -o wide"

echo "[INFO] Verifying ops-brain label is present"
ansible -i "$INV" ops_brain -m shell -a "$KUBE_ENV && kubectl get nodes --show-labels | grep -q '$OPS_BRAIN_ROLE_LABEL'"

echo "[INFO] Verifying Helm is installed"
ansible -i "$INV" ops_brain -m shell -a "helm version --short"

echo "[OK] Ops-brain cluster verification complete"
