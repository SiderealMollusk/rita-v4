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
NEXTCLOUD_AUTO_SNAPSHOT_PRE="${NEXTCLOUD_AUTO_SNAPSHOT_PRE:-1}"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --inventory) INVENTORY_PATH="${2:-}"; shift 2 ;;
    --host-alias) HOST_ALIAS="${2:-}"; shift 2 ;;
    --occ-path) OCC_PATH="${2:-}"; shift 2 ;;
    --flow-version) shift 2 ;; # deprecated
    --flow-tarball-url) shift 2 ;; # deprecated
    --help|-h)
      echo "Usage: 17-enable-nextcloud-flow.sh [--inventory <path>] [--host-alias <alias>] [--occ-path <path>]"
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

echo "[INFO] Enabling Flow prerequisites on ${HOST_ALIAS}"

if [ "${NEXTCLOUD_AUTO_SNAPSHOT_PRE}" = "1" ]; then
  echo "[INFO] Creating pre-change Nextcloud VM pair snapshot"
  NEXTCLOUD_SNAPSHOT_CHANGE_ID="17-enable-nextcloud-flow" \
    "${REPO_ROOT}/scripts/2-ops/workload/35-snapshot-nextcloud-pair.sh"
fi

for app in app_api webhook_listeners; do
  echo "[INFO] Installing/enabling app: ${app}"
  if ! occ "app:install ${app}"; then
    occ "app:enable ${app}"
  fi
done

echo "[INFO] AppAPI daemon list"
occ "app_api:daemon:list" || true
echo "[INFO] Flow prerequisite step completed"
