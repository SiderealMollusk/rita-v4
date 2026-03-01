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
MON_TIMEOUT="$(runbook_yaml_get "$GROUP_VARS" "monitoring_helm_timeout" || true)"

PROM_RELEASE="$(runbook_yaml_get "$GROUP_VARS" "monitoring_kube_prometheus_release_name" || true)"
PROM_REPO_NAME="$(runbook_yaml_get "$GROUP_VARS" "monitoring_kube_prometheus_repo_name" || true)"
PROM_REPO_URL="$(runbook_yaml_get "$GROUP_VARS" "monitoring_kube_prometheus_repo_url" || true)"
PROM_CHART="$(runbook_yaml_get "$GROUP_VARS" "monitoring_kube_prometheus_chart" || true)"
PROM_VALUES_REL="$(runbook_yaml_get "$GROUP_VARS" "monitoring_kube_prometheus_values_file" || true)"
PROM_VALUES="$REPO_ROOT/${PROM_VALUES_REL}"

LOKI_RELEASE="$(runbook_yaml_get "$GROUP_VARS" "monitoring_loki_release_name" || true)"
LOKI_REPO_NAME="$(runbook_yaml_get "$GROUP_VARS" "monitoring_loki_repo_name" || true)"
LOKI_REPO_URL="$(runbook_yaml_get "$GROUP_VARS" "monitoring_loki_repo_url" || true)"
LOKI_CHART="$(runbook_yaml_get "$GROUP_VARS" "monitoring_loki_chart" || true)"
LOKI_VALUES_REL="$(runbook_yaml_get "$GROUP_VARS" "monitoring_loki_values_file" || true)"
LOKI_VALUES="$REPO_ROOT/${LOKI_VALUES_REL}"

PROMTAIL_RELEASE="$(runbook_yaml_get "$GROUP_VARS" "monitoring_promtail_release_name" || true)"
PROMTAIL_REPO_NAME="$(runbook_yaml_get "$GROUP_VARS" "monitoring_promtail_repo_name" || true)"
PROMTAIL_REPO_URL="$(runbook_yaml_get "$GROUP_VARS" "monitoring_promtail_repo_url" || true)"
PROMTAIL_CHART="$(runbook_yaml_get "$GROUP_VARS" "monitoring_promtail_chart" || true)"
PROMTAIL_VALUES_REL="$(runbook_yaml_get "$GROUP_VARS" "monitoring_promtail_values_file" || true)"
PROMTAIL_VALUES="$REPO_ROOT/${PROMTAIL_VALUES_REL}"

[ -n "$MON_NS" ] || runbook_fail "monitoring_namespace missing in $GROUP_VARS"
[ -n "$MON_TIMEOUT" ] || runbook_fail "monitoring_helm_timeout missing in $GROUP_VARS"
[ -n "$PROM_RELEASE" ] || runbook_fail "monitoring_kube_prometheus_release_name missing in $GROUP_VARS"
[ -n "$PROM_REPO_NAME" ] || runbook_fail "monitoring_kube_prometheus_repo_name missing in $GROUP_VARS"
[ -n "$PROM_REPO_URL" ] || runbook_fail "monitoring_kube_prometheus_repo_url missing in $GROUP_VARS"
[ -n "$PROM_CHART" ] || runbook_fail "monitoring_kube_prometheus_chart missing in $GROUP_VARS"
[ -n "$PROM_VALUES_REL" ] || runbook_fail "monitoring_kube_prometheus_values_file missing in $GROUP_VARS"
[ -f "$PROM_VALUES" ] || runbook_fail "monitoring values file not found: $PROM_VALUES"
[ -n "$LOKI_RELEASE" ] || runbook_fail "monitoring_loki_release_name missing in $GROUP_VARS"
[ -n "$LOKI_REPO_NAME" ] || runbook_fail "monitoring_loki_repo_name missing in $GROUP_VARS"
[ -n "$LOKI_REPO_URL" ] || runbook_fail "monitoring_loki_repo_url missing in $GROUP_VARS"
[ -n "$LOKI_CHART" ] || runbook_fail "monitoring_loki_chart missing in $GROUP_VARS"
[ -n "$LOKI_VALUES_REL" ] || runbook_fail "monitoring_loki_values_file missing in $GROUP_VARS"
[ -f "$LOKI_VALUES" ] || runbook_fail "loki values file not found: $LOKI_VALUES"
[ -n "$PROMTAIL_RELEASE" ] || runbook_fail "monitoring_promtail_release_name missing in $GROUP_VARS"
[ -n "$PROMTAIL_REPO_NAME" ] || runbook_fail "monitoring_promtail_repo_name missing in $GROUP_VARS"
[ -n "$PROMTAIL_REPO_URL" ] || runbook_fail "monitoring_promtail_repo_url missing in $GROUP_VARS"
[ -n "$PROMTAIL_CHART" ] || runbook_fail "monitoring_promtail_chart missing in $GROUP_VARS"
[ -n "$PROMTAIL_VALUES_REL" ] || runbook_fail "monitoring_promtail_values_file missing in $GROUP_VARS"
[ -f "$PROMTAIL_VALUES" ] || runbook_fail "promtail values file not found: $PROMTAIL_VALUES"

REMOTE_PROM_VALUES="/tmp/rita-kube-prometheus-values.yaml"
REMOTE_LOKI_VALUES="/tmp/rita-loki-values.yaml"
REMOTE_PROMTAIL_VALUES="/tmp/rita-promtail-values.yaml"

echo "[INFO] Verifying Newt release is present before installing monitoring"
ansible -i "$INV" ops_brain -b -m shell -a "$KUBE_ENV && helm status ops-brain-newt -n newt >/dev/null"

echo "[INFO] Ensuring monitoring namespace exists"
ansible -i "$INV" ops_brain -b -m shell -a "$KUBE_ENV && kubectl create namespace $MON_NS --dry-run=client -o yaml | kubectl apply -f -"

echo "[INFO] Copying committed monitoring values to ops-brain"
ansible -i "$INV" ops_brain -b -m copy -a "src=$PROM_VALUES dest=$REMOTE_PROM_VALUES mode=0644"
ansible -i "$INV" ops_brain -b -m copy -a "src=$LOKI_VALUES dest=$REMOTE_LOKI_VALUES mode=0644"
ansible -i "$INV" ops_brain -b -m copy -a "src=$PROMTAIL_VALUES dest=$REMOTE_PROMTAIL_VALUES mode=0644"

echo "[INFO] Adding/updating monitoring Helm repos on ops-brain"
ansible -i "$INV" ops_brain -b -m shell -a "$KUBE_ENV && helm repo add $PROM_REPO_NAME $PROM_REPO_URL >/dev/null 2>&1 || true && helm repo update $PROM_REPO_NAME"
ansible -i "$INV" ops_brain -b -m shell -a "$KUBE_ENV && helm repo add $LOKI_REPO_NAME $LOKI_REPO_URL >/dev/null 2>&1 || true && helm repo update $LOKI_REPO_NAME"
if [ "$PROMTAIL_REPO_NAME" = "$LOKI_REPO_NAME" ]; then
  :
else
  ansible -i "$INV" ops_brain -b -m shell -a "$KUBE_ENV && helm repo add $PROMTAIL_REPO_NAME $PROMTAIL_REPO_URL >/dev/null 2>&1 || true && helm repo update $PROMTAIL_REPO_NAME"
fi

echo "[INFO] Clearing stuck monitoring Helm release state if needed"
for release in "$PROM_RELEASE" "$LOKI_RELEASE" "$PROMTAIL_RELEASE"; do
  ansible -i "$INV" ops_brain -b -m shell -a "set -e
$KUBE_ENV
if helm status $release -n $MON_NS >/tmp/rita-helm-status.txt 2>&1; then
  if grep -Eq '^STATUS: (pending-install|pending-upgrade|pending-rollback)' /tmp/rita-helm-status.txt; then
    echo '[INFO] Found pending Helm state for $release. Uninstalling before retry.'
    helm uninstall $release -n $MON_NS || true
  fi
fi
rm -f /tmp/rita-helm-status.txt"
done

echo "[INFO] Installing/upgrading kube-prometheus-stack"
if ! ansible -i "$INV" ops_brain -b -m shell -a "$KUBE_ENV && helm upgrade --install $PROM_RELEASE $PROM_CHART -n $MON_NS -f $REMOTE_PROM_VALUES --wait --timeout $MON_TIMEOUT"; then
  echo "[INFO] kube-prometheus-stack release failed or timed out. Dumping diagnostics."
  ansible -i "$INV" ops_brain -b -m shell -a "$KUBE_ENV && kubectl get pods -n $MON_NS -o wide" || true
  ansible -i "$INV" ops_brain -b -m shell -a "$KUBE_ENV && kubectl get pvc -n $MON_NS" || true
  ansible -i "$INV" ops_brain -b -m shell -a "$KUBE_ENV && kubectl get events -n $MON_NS --sort-by=.lastTimestamp | tail -n 30" || true
  ansible -i "$INV" ops_brain -b -m shell -a "$KUBE_ENV && helm status $PROM_RELEASE -n $MON_NS" || true
  runbook_fail "kube-prometheus-stack install failed or timed out. See diagnostics above."
fi

echo "[INFO] Installing/upgrading Loki"
if ! ansible -i "$INV" ops_brain -b -m shell -a "$KUBE_ENV && helm upgrade --install $LOKI_RELEASE $LOKI_CHART -n $MON_NS -f $REMOTE_LOKI_VALUES --wait --timeout $MON_TIMEOUT"; then
  echo "[INFO] Loki release failed or timed out. Dumping diagnostics."
  ansible -i "$INV" ops_brain -b -m shell -a "$KUBE_ENV && kubectl get pods -n $MON_NS -o wide" || true
  ansible -i "$INV" ops_brain -b -m shell -a "$KUBE_ENV && kubectl get pvc -n $MON_NS" || true
  ansible -i "$INV" ops_brain -b -m shell -a "$KUBE_ENV && kubectl get events -n $MON_NS --sort-by=.lastTimestamp | tail -n 30" || true
  ansible -i "$INV" ops_brain -b -m shell -a "$KUBE_ENV && helm status $LOKI_RELEASE -n $MON_NS" || true
  runbook_fail "Loki install failed or timed out. See diagnostics above."
fi

echo "[INFO] Installing/upgrading Promtail"
if ! ansible -i "$INV" ops_brain -b -m shell -a "$KUBE_ENV && helm upgrade --install $PROMTAIL_RELEASE $PROMTAIL_CHART -n $MON_NS -f $REMOTE_PROMTAIL_VALUES --wait --timeout $MON_TIMEOUT"; then
  echo "[INFO] Promtail release failed or timed out. Dumping diagnostics."
  ansible -i "$INV" ops_brain -b -m shell -a "$KUBE_ENV && kubectl get pods -n $MON_NS -o wide" || true
  ansible -i "$INV" ops_brain -b -m shell -a "$KUBE_ENV && kubectl get events -n $MON_NS --sort-by=.lastTimestamp | tail -n 30" || true
  ansible -i "$INV" ops_brain -b -m shell -a "$KUBE_ENV && helm status $PROMTAIL_RELEASE -n $MON_NS" || true
  runbook_fail "Promtail install failed or timed out. See diagnostics above."
fi

echo "[OK] Monitoring stack install submitted. Verify with 12-verify-monitoring-stack.sh"
