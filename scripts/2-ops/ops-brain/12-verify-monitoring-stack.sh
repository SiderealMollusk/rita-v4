#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../lib/runbook.sh"

runbook_require_no_args "$@"
REPO_ROOT="$(runbook_detect_repo_root)"
INV="$REPO_ROOT/ops/ansible/inventory/ops-brain.ini"
GROUP_VARS="$REPO_ROOT/ops/ansible/group_vars/ops_brain.yml"

[ -f "$INV" ] || runbook_fail "inventory not found: $INV"
[ -f "$GROUP_VARS" ] || runbook_fail "missing group vars file at $GROUP_VARS"

runbook_require_cmd ansible
runbook_refresh_known_hosts_from_inventory "$INV"

OPS_BRAIN_ANSIBLE_USER="$(awk '
  /^\[/ { next }
  $0 !~ /^[[:space:]]*#/ && NF > 0 {
    for (i=1; i<=NF; i++) {
      if ($i ~ /^ansible_user=/) {
        split($i, a, "=")
        print a[2]
        exit
      }
    }
  }
' "$INV")"
[ -n "$OPS_BRAIN_ANSIBLE_USER" ] || runbook_fail "ansible_user missing in $INV"
OPS_BRAIN_KUBECONFIG="/home/${OPS_BRAIN_ANSIBLE_USER}/.kube/config"
KUBE_ENV="export KUBECONFIG=${OPS_BRAIN_KUBECONFIG}"

MON_NS="$(runbook_yaml_get "$GROUP_VARS" "monitoring_namespace" || true)"
PROM_RELEASE="$(runbook_yaml_get "$GROUP_VARS" "monitoring_kube_prometheus_release_name" || true)"
LOKI_RELEASE="$(runbook_yaml_get "$GROUP_VARS" "monitoring_loki_release_name" || true)"
PROMTAIL_RELEASE="$(runbook_yaml_get "$GROUP_VARS" "monitoring_promtail_release_name" || true)"
KUMA_RELEASE="$(runbook_yaml_get "$GROUP_VARS" "monitoring_kuma_release_name" || true)"

[ -n "$MON_NS" ] || runbook_fail "monitoring_namespace missing in $GROUP_VARS"
[ -n "$PROM_RELEASE" ] || runbook_fail "monitoring_kube_prometheus_release_name missing in $GROUP_VARS"
[ -n "$LOKI_RELEASE" ] || runbook_fail "monitoring_loki_release_name missing in $GROUP_VARS"
[ -n "$PROMTAIL_RELEASE" ] || runbook_fail "monitoring_promtail_release_name missing in $GROUP_VARS"
[ -n "$KUMA_RELEASE" ] || runbook_fail "monitoring_kuma_release_name missing in $GROUP_VARS"

echo "[INFO] Verifying monitoring Helm releases"
ansible -i "$INV" ops_brain -b -m shell -a "$KUBE_ENV && helm status $PROM_RELEASE -n $MON_NS >/dev/null"
ansible -i "$INV" ops_brain -b -m shell -a "$KUBE_ENV && helm status $LOKI_RELEASE -n $MON_NS >/dev/null"
ansible -i "$INV" ops_brain -b -m shell -a "$KUBE_ENV && helm status $PROMTAIL_RELEASE -n $MON_NS >/dev/null"
ansible -i "$INV" ops_brain -b -m shell -a "$KUBE_ENV && helm status $KUMA_RELEASE -n $MON_NS >/dev/null"

KUMA_SERVICE_NAME="$(ansible -i "$INV" ops_brain -b -m shell -a "$KUBE_ENV && kubectl get svc -n $MON_NS -l app.kubernetes.io/instance=$KUMA_RELEASE,app.kubernetes.io/name=uptime-kuma -o jsonpath='{.items[0].metadata.name}'" \
  | awk -F'>>' 'NF > 1 {gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2); print $2}' \
  | tail -n 1)"
[ -n "$KUMA_SERVICE_NAME" ] || runbook_fail "could not determine Uptime Kuma service name in namespace $MON_NS"

echo "[INFO] Verifying monitoring namespace pods are not crashlooping"
ansible -i "$INV" ops_brain -b -m shell -a "$KUBE_ENV && kubectl get pods -n $MON_NS --no-headers | awk 'NF { if (\$3 ~ /(CrashLoopBackOff|Error|ImagePullBackOff|ErrImagePull|Pending)/) bad=1 } END { exit bad }'"

echo "[INFO] Verifying monitoring PVCs are bound"
ansible -i "$INV" ops_brain -b -m shell -a "$KUBE_ENV && kubectl get pvc -n $MON_NS --no-headers | awk 'NF { if (\$2 != \"Bound\") bad=1 } END { exit bad }'"

echo "[INFO] Capturing monitoring service inventory"
ansible -i "$INV" ops_brain -b -m shell -a "$KUBE_ENV && kubectl get svc -n $MON_NS"

echo "[INFO] Capturing monitoring pod inventory"
ansible -i "$INV" ops_brain -b -m shell -a "$KUBE_ENV && kubectl get pods -n $MON_NS -o wide"

echo "[INFO] Verifying Promtail is shipping logs to Loki"
ansible -i "$INV" ops_brain -b -m shell -a "$KUBE_ENV && kubectl logs -n $MON_NS -l app.kubernetes.io/instance=${PROMTAIL_RELEASE} --tail=50 | tail -n 20"

echo "[INFO] Grafana admin password retrieval command"
echo "       ssh virgil@192.168.6.16 'export KUBECONFIG=/home/${OPS_BRAIN_ANSIBLE_USER}/.kube/config && kubectl get secret -n ${MON_NS} ${PROM_RELEASE}-grafana -o jsonpath=\"{.data.admin-password}\" | base64 -d; echo'"
echo "[INFO] Run the following port-forward commands from the Mac host terminal, not inside the devcontainer."
echo "[INFO] Grafana port-forward command"
echo "       ssh virgil@192.168.6.16 'export KUBECONFIG=/home/${OPS_BRAIN_ANSIBLE_USER}/.kube/config && kubectl port-forward -n ${MON_NS} svc/${PROM_RELEASE}-grafana 3000:80'"
echo "[INFO] Prometheus port-forward command"
echo "       ssh virgil@192.168.6.16 'export KUBECONFIG=/home/${OPS_BRAIN_ANSIBLE_USER}/.kube/config && kubectl port-forward -n ${MON_NS} svc/${PROM_RELEASE}-prometheus 9090:9090'"
echo "[INFO] Loki port-forward command"
echo "       ssh virgil@192.168.6.16 'export KUBECONFIG=/home/${OPS_BRAIN_ANSIBLE_USER}/.kube/config && kubectl port-forward -n ${MON_NS} svc/${LOKI_RELEASE} 3100:3100'"
echo "[INFO] Uptime Kuma port-forward command"
echo "       ssh virgil@192.168.6.16 'export KUBECONFIG=/home/${OPS_BRAIN_ANSIBLE_USER}/.kube/config && kubectl port-forward -n ${MON_NS} svc/${KUMA_SERVICE_NAME} 3001:80'"

echo "[OK] Monitoring stack verification complete"
