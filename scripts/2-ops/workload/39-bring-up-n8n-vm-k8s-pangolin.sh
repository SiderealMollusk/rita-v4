#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../lib/runbook.sh"

runbook_require_no_args "$@"
runbook_require_host_terminal
runbook_require_cmd kubectl
runbook_require_cmd flux
runbook_require_cmd bash
runbook_require_op_access
runbook_source_labrc "$REPO_ROOT"
runbook_export_default_kubeconfig

run_step() {
  local step="$1"
  echo "[INFO] >>> ${step}"
  "${REPO_ROOT}/${step}"
}

if [ "${PROXMOX_REBUILD_CONFIRM:-}" != "n8n-vm-9303" ]; then
  runbook_fail "Set PROXMOX_REBUILD_CONFIRM=n8n-vm-9303 before running full n8n rebuild chain."
fi

echo "[INFO] Starting end-to-end n8n VM + k8s + Pangolin chain"
echo "[INFO] Repo root: $REPO_ROOT"
echo "[INFO] KUBECONFIG: $KUBECONFIG"

# VM substrate and k3s worker join
run_step "scripts/2-ops/workload/29-rebuild-n8n-vm.sh"
run_step "scripts/2-ops/workload/30-bootstrap-n8n-host.sh"
run_step "scripts/2-ops/workload/31-install-n8n-k3s-agent.sh"
run_step "scripts/2-ops/workload/32-label-n8n-node.sh"
run_step "scripts/2-ops/workload/33-verify-n8n-node.sh"

# Secret substrate + n8n app state
run_step "scripts/2-ops/observatory/14-apply-secret-bridge.sh"
kubectl apply -f "$REPO_ROOT/ops/gitops/platform/apps/platform-postgres/postgres-auth-externalsecret.yaml"
kubectl apply -k "$REPO_ROOT/ops/gitops/platform/apps/n8n"
kubectl wait externalsecret/platform-postgres-auth -n platform --for='jsonpath={.status.conditions[0].status}'=True --timeout=180s || true
kubectl wait externalsecret/n8n-secrets -n platform --for='jsonpath={.status.conditions[0].status}'=True --timeout=180s || true
for _ in $(seq 1 60); do
  if kubectl get secret n8n-secrets -n platform >/dev/null 2>&1; then
    break
  fi
  sleep 2
done
kubectl get secret n8n-secrets -n platform >/dev/null 2>&1 || runbook_fail "n8n-secrets did not materialize after ExternalSecret apply"
run_step "scripts/2-ops/host/22-bootstrap-n8n-db.sh"
kubectl rollout status deploy/n8n -n platform --timeout=180s

# Pangolin site + VM Newt + n8n resource
run_step "scripts/2-ops/host/27-reconcile-pangolin-sites.sh"
run_step "scripts/2-ops/workload/21-wire-vm-newt-connectors.sh"
run_step "scripts/2-ops/host/31-apply-n8n-blueprint.sh"
run_step "scripts/2-ops/host/28-verify-pangolin-sites-and-newt.sh"

# Final validation snapshot
flux get all -A
kubectl get nodes -o wide
kubectl get deploy,svc,pvc,externalsecret,secret -n platform

echo "[OK] n8n VM + k8s + Pangolin chain completed."
echo "[INFO] Expected public entrypoint: https://n8n.virgil.info"
