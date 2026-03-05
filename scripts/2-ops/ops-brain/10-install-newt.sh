#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../lib/runbook.sh"

runbook_require_no_args "$@"
REPO_ROOT="$(runbook_detect_repo_root)"
INV="$REPO_ROOT/ops/ansible/inventory/ops-brain.ini"
GROUP_VARS="$REPO_ROOT/ops/ansible/group_vars/ops_brain.yml"
ROUTES_FILE="$REPO_ROOT/ops/network/routes.yml"
VALUES_FILE_REL="$(runbook_yaml_get "$GROUP_VARS" "pangolin_newt_values_file" || true)"
VALUES_FILE="$REPO_ROOT/${VALUES_FILE_REL}"

[ -f "$INV" ] || runbook_fail "inventory not found: $INV"
[ -f "$GROUP_VARS" ] || runbook_fail "missing group vars file at $GROUP_VARS"
[ -f "$ROUTES_FILE" ] || runbook_fail "routes file not found: $ROUTES_FILE"
[ -n "$VALUES_FILE_REL" ] || runbook_fail "pangolin_newt_values_file missing in $GROUP_VARS"
[ -f "$VALUES_FILE" ] || runbook_fail "values file not found: $VALUES_FILE"

runbook_require_cmd ansible
runbook_require_cmd op
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

PANGOLIN_ENDPOINT="$(runbook_yaml_get "$ROUTES_FILE" "pangolin_endpoint" || true)"
[ -n "$PANGOLIN_ENDPOINT" ] || runbook_fail "pangolin_endpoint missing in $ROUTES_FILE"

NEWT_NAMESPACE="$(runbook_yaml_get "$GROUP_VARS" "pangolin_newt_namespace" || true)"
NEWT_RELEASE="$(runbook_yaml_get "$GROUP_VARS" "pangolin_newt_release_name" || true)"
NEWT_SECRET_NAME="$(runbook_yaml_get "$GROUP_VARS" "pangolin_newt_secret_name" || true)"
NEWT_HELM_REPO_NAME="$(runbook_yaml_get "$GROUP_VARS" "pangolin_newt_helm_repo_name" || true)"
NEWT_HELM_REPO_URL="$(runbook_yaml_get "$GROUP_VARS" "pangolin_newt_helm_repo_url" || true)"
NEWT_HELM_CHART="$(runbook_yaml_get "$GROUP_VARS" "pangolin_newt_helm_chart" || true)"
NEWT_HELM_TIMEOUT="$(runbook_yaml_get "$GROUP_VARS" "pangolin_newt_helm_timeout" || true)"
NEWT_CRED_VAULT_ID="$(runbook_yaml_get "$GROUP_VARS" "pangolin_newt_credentials_vault_id" || true)"
NEWT_CRED_ITEM="$(runbook_yaml_get "$GROUP_VARS" "pangolin_newt_credentials_item" || true)"

[ -n "$NEWT_NAMESPACE" ] || runbook_fail "pangolin_newt_namespace missing in $GROUP_VARS"
[ -n "$NEWT_RELEASE" ] || runbook_fail "pangolin_newt_release_name missing in $GROUP_VARS"
[ -n "$NEWT_SECRET_NAME" ] || runbook_fail "pangolin_newt_secret_name missing in $GROUP_VARS"
[ -n "$NEWT_HELM_REPO_NAME" ] || runbook_fail "pangolin_newt_helm_repo_name missing in $GROUP_VARS"
[ -n "$NEWT_HELM_REPO_URL" ] || runbook_fail "pangolin_newt_helm_repo_url missing in $GROUP_VARS"
[ -n "$NEWT_HELM_CHART" ] || runbook_fail "pangolin_newt_helm_chart missing in $GROUP_VARS"
[ -n "$NEWT_HELM_TIMEOUT" ] || runbook_fail "pangolin_newt_helm_timeout missing in $GROUP_VARS"
[ -n "$NEWT_CRED_VAULT_ID" ] || runbook_fail "pangolin_newt_credentials_vault_id missing in $GROUP_VARS"
[ -n "$NEWT_CRED_ITEM" ] || runbook_fail "pangolin_newt_credentials_item missing in $GROUP_VARS"

runbook_require_op_access
if [ -n "${OP_SERVICE_ACCOUNT_TOKEN:-}" ]; then
  echo "[INFO] Using 1Password service-account context"
else
  echo "[INFO] Using 1Password human session"
fi

echo "[INFO] Reading Newt site credentials from vault=$NEWT_CRED_VAULT_ID item=$NEWT_CRED_ITEM"
NEWT_ID="$(op item get "$NEWT_CRED_ITEM" --vault "$NEWT_CRED_VAULT_ID" --fields label='newt_id' 2>/dev/null || true)"
if [ -z "$NEWT_ID" ]; then
  NEWT_ID="$(op item get "$NEWT_CRED_ITEM" --vault "$NEWT_CRED_VAULT_ID" --fields label='id' 2>/dev/null || true)"
fi
NEWT_SECRET="$(op item get "$NEWT_CRED_ITEM" --vault "$NEWT_CRED_VAULT_ID" --reveal --fields label='secret')"

[ -n "$NEWT_ID" ] || runbook_fail "failed to read field 'newt_id' (or legacy 'id') from 1Password item $NEWT_CRED_ITEM"
[ -n "$NEWT_SECRET" ] || runbook_fail "failed to read field 'secret' from 1Password item $NEWT_CRED_ITEM"
case "$NEWT_SECRET" in
  "[use '"*" --reveal' to reveal]")
    runbook_fail "1Password returned a concealed-field placeholder instead of the real secret. The secret read path must use --reveal."
    ;;
esac

PANGOLIN_ENDPOINT_B64="$(printf '%s' "$PANGOLIN_ENDPOINT" | base64 | tr -d '\n')"
NEWT_ID_B64="$(printf '%s' "$NEWT_ID" | base64 | tr -d '\n')"
NEWT_SECRET_B64="$(printf '%s' "$NEWT_SECRET" | base64 | tr -d '\n')"

REMOTE_VALUES_FILE="/tmp/rita-newt-values.yaml"

echo "[INFO] Copying committed Newt values to ops-brain"
ansible -i "$INV" ops_brain -b -m copy -a "src=$VALUES_FILE dest=$REMOTE_VALUES_FILE mode=0644"

echo "[INFO] Ensuring Newt namespace exists"
ansible -i "$INV" ops_brain -b -m shell -a "$KUBE_ENV && kubectl create namespace $NEWT_NAMESPACE --dry-run=client -o yaml | kubectl apply -f -"

echo "[INFO] Creating/updating Newt credentials secret"
ansible -i "$INV" ops_brain -b -m shell -a "set -e
$KUBE_ENV
PANGOLIN_ENDPOINT=\"\$(printf '%s' '$PANGOLIN_ENDPOINT_B64' | base64 -d)\"
NEWT_ID=\"\$(printf '%s' '$NEWT_ID_B64' | base64 -d)\"
NEWT_SECRET=\"\$(printf '%s' '$NEWT_SECRET_B64' | base64 -d)\"
cat > /tmp/newt-cred.env <<EOF_SECRET
PANGOLIN_ENDPOINT=\${PANGOLIN_ENDPOINT}
NEWT_ID=\${NEWT_ID}
NEWT_SECRET=\${NEWT_SECRET}
EOF_SECRET
kubectl create secret generic $NEWT_SECRET_NAME -n $NEWT_NAMESPACE --from-env-file=/tmp/newt-cred.env --dry-run=client -o yaml | kubectl apply -f -
rm -f /tmp/newt-cred.env"

echo "[INFO] Adding/updating Fossorial Helm repo on ops-brain"
ansible -i "$INV" ops_brain -b -m shell -a "$KUBE_ENV && helm repo add $NEWT_HELM_REPO_NAME $NEWT_HELM_REPO_URL >/dev/null 2>&1 || true && helm repo update $NEWT_HELM_REPO_NAME"

echo "[INFO] Clearing stuck Newt Helm release state if needed"
ansible -i "$INV" ops_brain -b -m shell -a "set -e
$KUBE_ENV
if helm status $NEWT_RELEASE -n $NEWT_NAMESPACE >/tmp/rita-newt-helm-status.txt 2>&1; then
  if grep -Eq '^STATUS: (pending-install|pending-upgrade|pending-rollback)' /tmp/rita-newt-helm-status.txt; then
    echo '[INFO] Found pending Helm state for $NEWT_RELEASE. Uninstalling before retry.'
    helm uninstall $NEWT_RELEASE -n $NEWT_NAMESPACE || true
  fi
fi
rm -f /tmp/rita-newt-helm-status.txt"

echo "[INFO] Installing/upgrading Newt Helm release"
if ! ansible -i "$INV" ops_brain -b -m shell -a "$KUBE_ENV && helm upgrade --install $NEWT_RELEASE $NEWT_HELM_CHART -n $NEWT_NAMESPACE -f $REMOTE_VALUES_FILE --wait --timeout $NEWT_HELM_TIMEOUT"; then
  echo "[INFO] Newt release did not become ready before timeout. Dumping diagnostics."
  ansible -i "$INV" ops_brain -b -m shell -a "$KUBE_ENV && kubectl get pods -n $NEWT_NAMESPACE -o wide" || true
  ansible -i "$INV" ops_brain -b -m shell -a "$KUBE_ENV && kubectl get events -n $NEWT_NAMESPACE --sort-by=.lastTimestamp | tail -n 20" || true
  ansible -i "$INV" ops_brain -b -m shell -a "$KUBE_ENV && helm status $NEWT_RELEASE -n $NEWT_NAMESPACE" || true
  ansible -i "$INV" ops_brain -b -m shell -a "$KUBE_ENV && kubectl get secret $NEWT_SECRET_NAME -n $NEWT_NAMESPACE -o jsonpath='{.data}'" || true
  ansible -i "$INV" ops_brain -b -m shell -a "$KUBE_ENV && kubectl describe deployment ${NEWT_RELEASE}-newt-main -n $NEWT_NAMESPACE" || true
  ansible -i "$INV" ops_brain -b -m shell -a "$KUBE_ENV && kubectl logs -n $NEWT_NAMESPACE deployment/${NEWT_RELEASE}-newt-main --tail=200" || true
  ansible -i "$INV" ops_brain -b -m shell -a "$KUBE_ENV && kubectl describe pod -n $NEWT_NAMESPACE \$(kubectl get pod -n $NEWT_NAMESPACE -l app.kubernetes.io/component=newt -o jsonpath='{.items[0].metadata.name}')" || true
  runbook_fail "Newt Helm release failed or timed out. See diagnostics above."
fi

echo "[OK] Newt install/upgrade submitted. Verify with kubectl and Pangolin site status."
