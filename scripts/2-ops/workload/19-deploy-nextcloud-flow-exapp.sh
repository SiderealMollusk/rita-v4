#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
cd "${REPO_ROOT}"

LABRC="${REPO_ROOT}/.labrc"
if [ -f "${LABRC}" ]; then
  # shellcheck source=/dev/null
  source "${LABRC}"
fi

KUBECONFIG_PATH="${KUBECONFIG:-${KUBECONFIG_INTERNAL:-$HOME/.kube/config-rita-ops-brain}}"
export KUBECONFIG="${KUBECONFIG_PATH}"

NAMESPACE="${NEXTCLOUD_NAMESPACE:-workload}"
DEPLOYMENT="${NEXTCLOUD_DEPLOYMENT:-nextcloud}"

APPAPI_DAEMON_NAME="${APPAPI_DAEMON_NAME:-harp_workload}"
FLOW_NUM_WORKERS="${FLOW_NUM_WORKERS:-}"
FLOW_EXTERNAL_DATABASE="${FLOW_EXTERNAL_DATABASE:-}"
FLOW_RUST_LOG="${FLOW_RUST_LOG:-}"

occ() {
  kubectl exec -n "${NAMESPACE}" deployment/"${DEPLOYMENT}" -- bash -lc "cd /var/www/html && $1"
}

shell_quote() {
  printf '%q' "$1"
}

echo "[INFO] Using kubeconfig: ${KUBECONFIG}"
echo "[INFO] Deploying Flow ExApp via daemon ${APPAPI_DAEMON_NAME}"
kubectl rollout status deployment/"${DEPLOYMENT}" -n "${NAMESPACE}" --timeout=10m

enabled_apps="$(occ "php occ app:list | sed -n '/Enabled:/,/Disabled:/p'" || true)"
if ! grep -q '^  - flow:' <<<"${enabled_apps}"; then
  echo "[FAIL] Flow app is not enabled yet."
  echo "[INFO] Run scripts/2-ops/workload/17-enable-nextcloud-flow.sh first."
  exit 1
fi

daemon_list="$(occ "php occ app_api:daemon:list" || true)"
if ! grep -q "${APPAPI_DAEMON_NAME}" <<<"${daemon_list}"; then
  echo "[FAIL] AppAPI daemon ${APPAPI_DAEMON_NAME} is not registered."
  echo "[INFO] Run scripts/2-ops/workload/18-register-nextcloud-appapi-daemon.sh first."
  exit 1
fi

if occ "php occ app_api:app:list" | grep -q 'flow'; then
  echo "[INFO] Flow already appears in AppAPI app list."
  occ "php occ app_api:app:list"
  exit 0
fi

register_cmd="php occ app_api:app:register flow $(shell_quote "${APPAPI_DAEMON_NAME}") --wait-finish"

if [ -n "${FLOW_NUM_WORKERS}" ]; then
  register_cmd="${register_cmd} --env=$(shell_quote "NUM_WORKERS=${FLOW_NUM_WORKERS}")"
fi

if [ -n "${FLOW_EXTERNAL_DATABASE}" ]; then
  register_cmd="${register_cmd} --env=$(shell_quote "EXTERNAL_DATABASE=${FLOW_EXTERNAL_DATABASE}")"
fi

if [ -n "${FLOW_RUST_LOG}" ]; then
  register_cmd="${register_cmd} --env=$(shell_quote "RUST_LOG=${FLOW_RUST_LOG}")"
fi

echo "[INFO] Running Flow ExApp registration"
occ "${register_cmd}"

echo "[INFO] Current AppAPI app list"
occ "php occ app_api:app:list"
