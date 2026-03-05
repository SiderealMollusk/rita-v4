#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
cd "${REPO_ROOT}"

runbook_source_labrc "${REPO_ROOT}"
runbook_export_default_kubeconfig

NAMESPACE="${NEXTCLOUD_NAMESPACE:-workload}"
DEPLOYMENT="${NEXTCLOUD_DEPLOYMENT:-nextcloud}"

APPAPI_DAEMON_NAME="${APPAPI_DAEMON_NAME:-harp_workload}"
APPAPI_DAEMON_DISPLAY_NAME="${APPAPI_DAEMON_DISPLAY_NAME:-HaRP Workload}"
APPAPI_DAEMON_ACCEPTS_DEPLOY_ID="${APPAPI_DAEMON_ACCEPTS_DEPLOY_ID:-docker-install}"
APPAPI_DAEMON_PROTOCOL="${APPAPI_DAEMON_PROTOCOL:-http}"
APPAPI_DAEMON_HOST="${APPAPI_DAEMON_HOST:-nextcloud-appapi-harp.workload.svc.cluster.local:8780}"
APPAPI_NEXTCLOUD_URL="${APPAPI_NEXTCLOUD_URL:-https://app.virgil.info}"
APPAPI_DAEMON_NET="${APPAPI_DAEMON_NET:-}"
APPAPI_USE_HARP="${APPAPI_USE_HARP:-1}"
APPAPI_HARP_FRP_ADDRESS="${APPAPI_HARP_FRP_ADDRESS:-}"
APPAPI_HARP_SHARED_KEY="${APPAPI_HARP_SHARED_KEY:-}"
APPAPI_HARP_DOCKER_SOCKET_PORT="${APPAPI_HARP_DOCKER_SOCKET_PORT:-24001}"
APPAPI_SET_DEFAULT="${APPAPI_SET_DEFAULT:-1}"
APPAPI_REPLACE_EXISTING="${APPAPI_REPLACE_EXISTING:-0}"

occ() {
  kubectl exec -n "${NAMESPACE}" deployment/"${DEPLOYMENT}" -- bash -lc "cd /var/www/html && $1"
}

shell_quote() {
  printf '%q' "$1"
}

require_env() {
  local var_name="$1"
  local hint="$2"
  if [ -z "${!var_name:-}" ]; then
    echo "[FAIL] ${var_name} is not set."
    echo "[INFO] ${hint}"
    exit 1
  fi
}

if [ "${APPAPI_USE_HARP}" = "1" ]; then
  require_env APPAPI_HARP_FRP_ADDRESS "Set it to the FRP endpoint reachable from the remote Docker host, for example 192.168.6.181:30782."
  require_env APPAPI_HARP_SHARED_KEY "Set it to the shared key used by HaRP and the remote FRP client."
fi

echo "[INFO] Using kubeconfig: ${KUBECONFIG}"
echo "[INFO] Registering AppAPI daemon on ${NAMESPACE}/${DEPLOYMENT}"
kubectl rollout status deployment/"${DEPLOYMENT}" -n "${NAMESPACE}" --timeout=10m

existing_daemons="$(occ "php occ app_api:daemon:list" || true)"
echo "${existing_daemons}"

if grep -q "${APPAPI_DAEMON_NAME}" <<<"${existing_daemons}"; then
  if [ "${APPAPI_REPLACE_EXISTING}" != "1" ]; then
    echo "[INFO] Daemon ${APPAPI_DAEMON_NAME} is already registered; leaving it unchanged."
    exit 0
  fi

  echo "[INFO] Replacing existing daemon ${APPAPI_DAEMON_NAME}"
  occ "php occ app_api:daemon:unregister ${APPAPI_DAEMON_NAME}"
fi

register_cmd="php occ app_api:daemon:register \
  $(shell_quote "${APPAPI_DAEMON_NAME}") \
  $(shell_quote "${APPAPI_DAEMON_DISPLAY_NAME}") \
  $(shell_quote "${APPAPI_DAEMON_ACCEPTS_DEPLOY_ID}") \
  $(shell_quote "${APPAPI_DAEMON_PROTOCOL}") \
  $(shell_quote "${APPAPI_DAEMON_HOST}") \
  $(shell_quote "${APPAPI_NEXTCLOUD_URL}")"

if [ -n "${APPAPI_DAEMON_NET}" ]; then
  register_cmd="${register_cmd} --net=$(shell_quote "${APPAPI_DAEMON_NET}")"
fi

if [ "${APPAPI_USE_HARP}" = "1" ]; then
  register_cmd="${register_cmd} --harp --harp_frp_address $(shell_quote "${APPAPI_HARP_FRP_ADDRESS}") --harp_shared_key $(shell_quote "${APPAPI_HARP_SHARED_KEY}") --harp_docker_socket_port $(shell_quote "${APPAPI_HARP_DOCKER_SOCKET_PORT}")"
fi

if [ "${APPAPI_SET_DEFAULT}" = "1" ]; then
  register_cmd="${register_cmd} --set-default"
fi

echo "[INFO] Running daemon registration"
occ "${register_cmd}"

echo "[INFO] Registered daemon list"
occ "php occ app_api:daemon:list"
