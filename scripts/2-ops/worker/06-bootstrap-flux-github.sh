#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../lib/runbook.sh"

runbook_require_no_args "$@"
runbook_require_host_terminal
runbook_require_cmd flux
runbook_require_cmd kubectl
runbook_require_cmd ansible-playbook
REPO_ROOT="$(runbook_detect_repo_root)"
cd "$REPO_ROOT"
BOOTSTRAP_CFG="$REPO_ROOT/ops/gitops/flux-bootstrap.yml"
OPS_BRAIN_INV="$REPO_ROOT/ops/ansible/inventory/ops-brain.ini"
LABRC="$REPO_ROOT/.labrc"

[ -f "$BOOTSTRAP_CFG" ] || runbook_fail "missing bootstrap config: $BOOTSTRAP_CFG"
[ -f "$OPS_BRAIN_INV" ] || runbook_fail "missing inventory: $OPS_BRAIN_INV"
[ -f "$LABRC" ] || runbook_fail "missing lab config: $LABRC"

# shellcheck source=/dev/null
source "$LABRC"

FLUX_GITHUB_BRANCH="${FLUX_GITHUB_BRANCH:-$(runbook_yaml_get "$BOOTSTRAP_CFG" github_branch)}"
FLUX_GITHUB_PATH="${FLUX_GITHUB_PATH:-$(runbook_yaml_get "$BOOTSTRAP_CFG" github_path)}"
GITHUB_TOKEN_ITEM="${GITHUB_TOKEN_ITEM:-$(runbook_yaml_get "$BOOTSTRAP_CFG" github_token_item)}"
GITHUB_TOKEN_FIELD="${GITHUB_TOKEN_FIELD:-$(runbook_yaml_get "$BOOTSTRAP_CFG" github_token_field)}"

if [ -z "${GITHUB_TOKEN_OP_REF:-}" ] && [ -n "${OP_VAULT_ID:-}" ] && [ -n "${GITHUB_TOKEN_ITEM:-}" ] && [ -n "${GITHUB_TOKEN_FIELD:-}" ]; then
  GITHUB_TOKEN_OP_REF="op://${OP_VAULT_ID}/${GITHUB_TOKEN_ITEM}/${GITHUB_TOKEN_FIELD}"
fi

if [ -z "${FLUX_GITHUB_OWNER:-}" ] || [ -z "${FLUX_GITHUB_REPO:-}" ]; then
  ORIGIN_URL="$(git remote get-url origin 2>/dev/null || true)"
  [ -n "$ORIGIN_URL" ] || runbook_fail "Could not resolve git remote origin. Set FLUX_GITHUB_OWNER and FLUX_GITHUB_REPO explicitly."

  REMOTE_SLUG="$(printf '%s\n' "$ORIGIN_URL" | sed -E 's#^https://github.com/##; s#^git@github.com:##; s#\.git$##')"
  case "$REMOTE_SLUG" in
    */*)
      FLUX_GITHUB_OWNER="${FLUX_GITHUB_OWNER:-${REMOTE_SLUG%%/*}}"
      FLUX_GITHUB_REPO="${FLUX_GITHUB_REPO:-${REMOTE_SLUG##*/}}"
      ;;
    *)
      runbook_fail "Could not derive GitHub owner/repo from origin: $ORIGIN_URL"
      ;;
  esac
fi

if [ -z "${GITHUB_TOKEN:-}" ]; then
  if [ -n "${GITHUB_TOKEN_OP_REF:-}" ]; then
    runbook_require_cmd op
    GITHUB_TOKEN="$(op read "$GITHUB_TOKEN_OP_REF")"
  else
    runbook_fail "Set GITHUB_TOKEN or GITHUB_TOKEN_OP_REF before running Flux bootstrap."
  fi
fi

export GITHUB_TOKEN

OPS_BRAIN_HOST="$(runbook_inventory_get_field "$OPS_BRAIN_INV" "ops-brain" "ansible_host")"
OPS_BRAIN_USER="$(runbook_inventory_get_field "$OPS_BRAIN_INV" "ops-brain" "ansible_user")"
[ -n "$OPS_BRAIN_HOST" ] || runbook_fail "Could not resolve ops-brain ansible_host from $OPS_BRAIN_INV"
[ -n "$OPS_BRAIN_USER" ] || runbook_fail "Could not resolve ops-brain ansible_user from $OPS_BRAIN_INV"

runbook_refresh_known_hosts_from_inventory "$OPS_BRAIN_INV"

LOCAL_INTERNAL_KUBECONFIG="${KUBECONFIG_INTERNAL:-${HOME}/.kube/config-rita-ops-brain}"
if ! kubectl get nodes --request-timeout=10s >/dev/null 2>&1; then
  echo "[INFO] Local kubectl is not currently pointed at the internal cluster"
  echo "[INFO] Refreshing canonical ops-brain kubeconfig before copy"
  "$REPO_ROOT/scripts/2-ops/ops-brain/08-sync-kubeconfig.sh"
  echo "[INFO] Pulling kubeconfig from ops-brain to ${LOCAL_INTERNAL_KUBECONFIG}"
  mkdir -p "${HOME}/.kube"
  scp "${OPS_BRAIN_USER}@${OPS_BRAIN_HOST}:/home/${OPS_BRAIN_USER}/.kube/config" "${LOCAL_INTERNAL_KUBECONFIG}"
  chmod 600 "${LOCAL_INTERNAL_KUBECONFIG}"
  export KUBECONFIG="${LOCAL_INTERNAL_KUBECONFIG}"
fi

kubectl get nodes --request-timeout=10s >/dev/null 2>&1 || runbook_fail "kubectl cannot reach the internal cluster even after kubeconfig setup."

echo "[INFO] Using GitHub owner: ${FLUX_GITHUB_OWNER}"
echo "[INFO] Using GitHub repo: ${FLUX_GITHUB_REPO}"
echo "[INFO] Using GitOps path: ${FLUX_GITHUB_PATH}"
if [ -n "${GITHUB_TOKEN_OP_REF:-}" ]; then
  echo "[INFO] Using token ref: ${GITHUB_TOKEN_OP_REF}"
fi
if [ -n "${KUBECONFIG:-}" ]; then
  echo "[INFO] Using kubeconfig: ${KUBECONFIG}"
fi
echo "[INFO] Bootstrapping Flux from GitHub"
flux bootstrap github \
  --owner="$FLUX_GITHUB_OWNER" \
  --repository="$FLUX_GITHUB_REPO" \
  --branch="$FLUX_GITHUB_BRANCH" \
  --path="$FLUX_GITHUB_PATH" \
  --personal

echo "[INFO] Running post-bootstrap verification"
flux check
kubectl get pods -n flux-system
kubectl get gitrepositories -A
kubectl get kustomizations -A
