#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
cd "${REPO_ROOT}"
# shellcheck source=/dev/null
source "${REPO_ROOT}/scripts/lib/runbook.sh"

runbook_source_labrc "${REPO_ROOT}"

INSTANCES_FILE="${REPO_ROOT}/ops/nextcloud/instances.yaml"
INVENTORY_PATH=""
HOST_ALIAS=""
OCC_PATH="${NEXTCLOUD_OCC_PATH:-/var/www/nextcloud/occ}"
APPAPI_DAEMON_NAME="${APPAPI_DAEMON_NAME:-manual_install_vm}"
FLOW_NUM_WORKERS="${FLOW_NUM_WORKERS:-}"
FLOW_EXTERNAL_DATABASE="${FLOW_EXTERNAL_DATABASE:-}"
FLOW_RUST_LOG="${FLOW_RUST_LOG:-}"
FLOW_PURGE_DATA="${FLOW_PURGE_DATA:-1}"
FLOW_POST_VERIFY="${FLOW_POST_VERIFY:-1}"
NEXTCLOUD_SNAPSHOT_MODE="${NEXTCLOUD_SNAPSHOT_MODE:-critical}"
if [ -n "${NEXTCLOUD_AUTO_SNAPSHOT_PRE:-}" ]; then
  if [ "${NEXTCLOUD_AUTO_SNAPSHOT_PRE}" = "1" ]; then
    NEXTCLOUD_SNAPSHOT_MODE="critical"
  else
    NEXTCLOUD_SNAPSHOT_MODE="off"
  fi
fi

while [ "$#" -gt 0 ]; do
  case "$1" in
    --inventory) INVENTORY_PATH="${2:-}"; shift 2 ;;
    --host-alias) HOST_ALIAS="${2:-}"; shift 2 ;;
    --occ-path) OCC_PATH="${2:-}"; shift 2 ;;
    --daemon-name) APPAPI_DAEMON_NAME="${2:-}"; shift 2 ;;
    --help|-h)
      echo "Usage: 19-deploy-nextcloud-flow-exapp.sh [--inventory <path>] [--host-alias <alias>] [--occ-path <path>] [--daemon-name <name>]"
      echo "Env: FLOW_PURGE_DATA=1 (default) purges nc_app_flow container + nc_app_flow_data volume before register."
      exit 0
      ;;
    *) runbook_fail "Unknown argument: $1" ;;
  esac
done

[ -f "${INSTANCES_FILE}" ] || runbook_fail "missing nextcloud instances file: ${INSTANCES_FILE}"

instance_row="$(python3 - "$INSTANCES_FILE" <<'PY'
import json, sys
path = sys.argv[1]
with open(path, "r", encoding="utf-8") as f:
    obj = json.load(f)
official = obj.get("official_instance", "")
inst = (obj.get("instances", {}) or {}).get(official, {}) or {}
print("\t".join([
    str(inst.get("connector_mode", "")),
    str(inst.get("inventory_file", "")),
    str(inst.get("host_alias", "")),
]))
PY
)"
IFS=$'\t' read -r OFFICIAL_MODE OFFICIAL_INV_REL OFFICIAL_HOST_ALIAS <<<"${instance_row}"
[ "${OFFICIAL_MODE}" = "vm" ] || runbook_fail "official instance is not vm-backed in ${INSTANCES_FILE}"

[ -n "${INVENTORY_PATH}" ] || INVENTORY_PATH="${REPO_ROOT}/${OFFICIAL_INV_REL}"
[ -n "${HOST_ALIAS}" ] || HOST_ALIAS="${OFFICIAL_HOST_ALIAS}"
[ -f "${INVENTORY_PATH}" ] || runbook_fail "inventory file not found: ${INVENTORY_PATH}"
[ -n "${HOST_ALIAS}" ] || runbook_fail "host alias resolved empty"

runbook_require_cmd ansible

occ() {
  local cmd="$1"
  ansible -i "${INVENTORY_PATH}" "${HOST_ALIAS}" -b -m shell -a "set -eu; sudo -u www-data php '${OCC_PATH}' ${cmd}"
}

daemon_list="$(occ "app_api:daemon:list" || true)"
if ! grep -q "${APPAPI_DAEMON_NAME}" <<<"${daemon_list}"; then
  runbook_fail "AppAPI daemon '${APPAPI_DAEMON_NAME}' not found. Run scripts/2-ops/workload/18-register-nextcloud-appapi-daemon.sh first."
fi

daemon_row="$(printf '%s\n' "${daemon_list}" | grep -F "| ${APPAPI_DAEMON_NAME} " | head -n1 || true)"
daemon_deploy_id=""
if [ -n "${daemon_row}" ]; then
  daemon_deploy_id="$(printf '%s\n' "${daemon_row}" | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $5); print $5}')"
fi

app_list="$(occ "app_api:app:list" || true)"
if grep -q '^flow ' <<<"${app_list}" && ! grep -q '^flow .*\[disabled\]' <<<"${app_list}"; then
  echo "[INFO] Flow ExApp already enabled."
  echo "${app_list}"
  exit 0
fi

if [ "${NEXTCLOUD_SNAPSHOT_MODE}" = "critical" ]; then
  echo "[INFO] Creating pre-change Nextcloud VM pair snapshot"
  NEXTCLOUD_SNAPSHOT_CHANGE_ID="19-deploy-nextcloud-flow-exapp" \
    "${REPO_ROOT}/scripts/2-ops/workload/35-snapshot-nextcloud-pair.sh"
fi

if grep -q '^flow ' <<<"${app_list}"; then
  echo "[INFO] Removing stale disabled Flow ExApp registration"
  set +e
  unregister_output="$(occ "app_api:app:unregister flow" 2>&1)"
  unregister_rc=$?
  set -e
  if [ "${unregister_rc}" -ne 0 ]; then
    if printf '%s\n' "${unregister_output}" | grep -q "No such container: nc_app_flow"; then
      echo "[WARN] Flow container already absent during unregister; continuing."
    else
      printf '%s\n' "${unregister_output}"
      runbook_fail "failed to unregister stale Flow ExApp registration."
    fi
  else
    printf '%s\n' "${unregister_output}"
  fi
fi

if [ "${FLOW_PURGE_DATA}" = "1" ]; then
  echo "[INFO] Purging stale Flow runtime state (container + volume)"
  ansible -i "${INVENTORY_PATH}" "${HOST_ALIAS}" -b -m shell -a "\
set -eu
sudo docker rm -f nc_app_flow >/dev/null 2>&1 || true
sudo docker volume rm -f nc_app_flow_data >/dev/null 2>&1 || true"
fi

register_cmd="app_api:app:register flow '${APPAPI_DAEMON_NAME}'"
register_timeout_seconds=75
if [ "${daemon_deploy_id}" != "manual-install" ]; then
  register_cmd="${register_cmd} --wait-finish"
  register_timeout_seconds=600
else
  echo "[INFO] Daemon '${APPAPI_DAEMON_NAME}' uses manual-install; skipping --wait-finish."
fi
if [ -n "${FLOW_NUM_WORKERS}" ]; then
  register_cmd="${register_cmd} --env='NUM_WORKERS=${FLOW_NUM_WORKERS}'"
fi
if [ -n "${FLOW_EXTERNAL_DATABASE}" ]; then
  register_cmd="${register_cmd} --env='EXTERNAL_DATABASE=${FLOW_EXTERNAL_DATABASE}'"
fi
if [ -n "${FLOW_RUST_LOG}" ]; then
  register_cmd="${register_cmd} --env='RUST_LOG=${FLOW_RUST_LOG}'"
fi

echo "[INFO] Registering Flow ExApp against daemon ${APPAPI_DAEMON_NAME}"
set +e
register_output="$(ansible -i "${INVENTORY_PATH}" "${HOST_ALIAS}" -b -m shell -a "set -eu; timeout ${register_timeout_seconds} sudo -u www-data php '${OCC_PATH}' ${register_cmd}" 2>&1)"
register_rc=$?
set -e
printf '%s\n' "${register_output}"

if [ "${register_rc}" -ne 0 ]; then
  if [ "${daemon_deploy_id}" = "manual-install" ] && { [ "${register_rc}" -eq 2 ] || [ "${register_rc}" -eq 124 ]; }; then
    echo "[WARN] Flow registration command timed out in manual-install mode; registration may remain pending until manual deploy completes."
  elif printf '%s\n' "${register_output}" | grep -q "ExApp flow is already registered"; then
    echo "[WARN] Flow already registered according to AppAPI; continuing to state verification."
  else
    runbook_fail "Flow ExApp registration failed (rc=${register_rc})."
  fi
fi

echo "[INFO] Current ExApp list"
occ "app_api:app:list"

if [ "${FLOW_POST_VERIFY}" = "1" ]; then
  echo "[INFO] Running ExApps health verification"
  APPAPI_EXPECTED_DAEMON="${APPAPI_DAEMON_NAME}" EXAPP_APP_ID="flow" \
    "${REPO_ROOT}/scripts/2-ops/workload/34-verify-nextcloud-exapps-health.sh"
fi
