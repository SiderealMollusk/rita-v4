#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
cd "${REPO_ROOT}"
# shellcheck source=/dev/null
source "${REPO_ROOT}/scripts/lib/runbook.sh"

runbook_source_labrc "${REPO_ROOT}"

INSTANCES_FILE="${REPO_ROOT}/ops/nextcloud/instances.yaml"
OCC_PATH="${NEXTCLOUD_OCC_PATH:-/var/www/nextcloud/occ}"
APPAPI_MODE="${APPAPI_MODE:-docker-local}"

APPAPI_DAEMON_NAME="${APPAPI_DAEMON_NAME:-}"
APPAPI_DAEMON_DISPLAY_NAME="${APPAPI_DAEMON_DISPLAY_NAME:-}"
APPAPI_DAEMON_ACCEPTS_DEPLOY_ID="${APPAPI_DAEMON_ACCEPTS_DEPLOY_ID:-}"
APPAPI_DAEMON_PROTOCOL="${APPAPI_DAEMON_PROTOCOL:-}"
APPAPI_DAEMON_HOST="${APPAPI_DAEMON_HOST:-}"
APPAPI_DAEMON_NET="${APPAPI_DAEMON_NET:-}"
APPAPI_COMPUTE_DEVICE="${APPAPI_COMPUTE_DEVICE:-}"
APPAPI_SET_DEFAULT="${APPAPI_SET_DEFAULT:-1}"
APPAPI_REPLACE_EXISTING="${APPAPI_REPLACE_EXISTING:-0}"
APPAPI_PREPARE_DOCKER_LOCAL="${APPAPI_PREPARE_DOCKER_LOCAL:-0}"
APPAPI_POST_VERIFY="${APPAPI_POST_VERIFY:-1}"
NEXTCLOUD_AUTO_SNAPSHOT_PRE="${NEXTCLOUD_AUTO_SNAPSHOT_PRE:-1}"

usage() {
  cat <<'EOF'
Usage:
  18-register-nextcloud-appapi-daemon.sh [options]

Options:
  --mode <mode>                daemon mode: docker-local|manual-install (default: docker-local)
  --inventory <path>            Inventory path (default: from official instance)
  --host-alias <alias>          Host alias (default: from official instance)
  --occ-path <path>             occ path (default: /var/www/nextcloud/occ)
  --daemon-name <name>          Daemon name (mode default if omitted)
  --display-name <name>         Display name (mode default if omitted)
  --accepts-deploy-id <id>      manual-install|docker-install (mode default if omitted)
  --protocol <proto>            http|https (mode default if omitted)
  --host <host>                 Daemon host/path (mode default if omitted)
  --prepare-docker-local        Install/enable Docker on target VM and grant www-data docker socket access
  --nextcloud-url <url>         Nextcloud URL (default: official instance domain)
  --net <name>                  Optional docker net
  --compute-device <device>     Optional compute device (cpu|cuda|rocm)
  --set-default                 Set as default daemon (default behavior)
  --no-set-default              Do not set as default
  --replace-existing            Replace daemon if it already exists
  --help                        Show help
EOF
}

INVENTORY_PATH=""
HOST_ALIAS=""
APPAPI_NEXTCLOUD_URL=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --mode) APPAPI_MODE="${2:-}"; shift 2 ;;
    --inventory) INVENTORY_PATH="${2:-}"; shift 2 ;;
    --host-alias) HOST_ALIAS="${2:-}"; shift 2 ;;
    --occ-path) OCC_PATH="${2:-}"; shift 2 ;;
    --daemon-name) APPAPI_DAEMON_NAME="${2:-}"; shift 2 ;;
    --display-name) APPAPI_DAEMON_DISPLAY_NAME="${2:-}"; shift 2 ;;
    --accepts-deploy-id) APPAPI_DAEMON_ACCEPTS_DEPLOY_ID="${2:-}"; shift 2 ;;
    --protocol) APPAPI_DAEMON_PROTOCOL="${2:-}"; shift 2 ;;
    --host) APPAPI_DAEMON_HOST="${2:-}"; shift 2 ;;
    --nextcloud-url) APPAPI_NEXTCLOUD_URL="${2:-}"; shift 2 ;;
    --net) APPAPI_DAEMON_NET="${2:-}"; shift 2 ;;
    --compute-device) APPAPI_COMPUTE_DEVICE="${2:-}"; shift 2 ;;
    --set-default) APPAPI_SET_DEFAULT="1"; shift ;;
    --no-set-default) APPAPI_SET_DEFAULT="0"; shift ;;
    --replace-existing) APPAPI_REPLACE_EXISTING="1"; shift ;;
    --prepare-docker-local) APPAPI_PREPARE_DOCKER_LOCAL="1"; shift ;;
    --help|-h) usage; exit 0 ;;
    *) runbook_fail "Unknown argument: $1" ;;
  esac
done

case "${APPAPI_MODE}" in
  docker-local)
    [ -n "${APPAPI_DAEMON_NAME}" ] || APPAPI_DAEMON_NAME="docker_local_vm"
    [ -n "${APPAPI_DAEMON_DISPLAY_NAME}" ] || APPAPI_DAEMON_DISPLAY_NAME="Docker Local VM"
    [ -n "${APPAPI_DAEMON_ACCEPTS_DEPLOY_ID}" ] || APPAPI_DAEMON_ACCEPTS_DEPLOY_ID="docker-install"
    [ -n "${APPAPI_DAEMON_PROTOCOL}" ] || APPAPI_DAEMON_PROTOCOL="http"
    [ -n "${APPAPI_DAEMON_HOST}" ] || APPAPI_DAEMON_HOST="/var/run/docker.sock"
    ;;
  manual-install)
    [ -n "${APPAPI_DAEMON_NAME}" ] || APPAPI_DAEMON_NAME="manual_install_vm"
    [ -n "${APPAPI_DAEMON_DISPLAY_NAME}" ] || APPAPI_DAEMON_DISPLAY_NAME="Manual Install VM"
    [ -n "${APPAPI_DAEMON_ACCEPTS_DEPLOY_ID}" ] || APPAPI_DAEMON_ACCEPTS_DEPLOY_ID="manual-install"
    [ -n "${APPAPI_DAEMON_PROTOCOL}" ] || APPAPI_DAEMON_PROTOCOL="http"
    [ -n "${APPAPI_DAEMON_HOST}" ] || APPAPI_DAEMON_HOST="null"
    ;;
  *)
    runbook_fail "Unsupported --mode '${APPAPI_MODE}'. Use docker-local or manual-install."
    ;;
esac

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
    str(inst.get("domain", "")),
]))
PY
)"
IFS=$'\t' read -r OFFICIAL_MODE OFFICIAL_INV_REL OFFICIAL_HOST_ALIAS OFFICIAL_DOMAIN <<<"${instance_row}"
[ "${OFFICIAL_MODE}" = "vm" ] || runbook_fail "official instance is not vm-backed in ${INSTANCES_FILE}"

[ -n "${INVENTORY_PATH}" ] || INVENTORY_PATH="${REPO_ROOT}/${OFFICIAL_INV_REL}"
[ -n "${HOST_ALIAS}" ] || HOST_ALIAS="${OFFICIAL_HOST_ALIAS}"
[ -n "${APPAPI_NEXTCLOUD_URL}" ] || APPAPI_NEXTCLOUD_URL="https://${OFFICIAL_DOMAIN}"

[ -f "${INVENTORY_PATH}" ] || runbook_fail "inventory file not found: ${INVENTORY_PATH}"
[ -n "${HOST_ALIAS}" ] || runbook_fail "host alias resolved empty"
[ -n "${APPAPI_NEXTCLOUD_URL}" ] || runbook_fail "nextcloud url resolved empty"

runbook_require_cmd ansible

if [ "${NEXTCLOUD_AUTO_SNAPSHOT_PRE}" = "1" ]; then
  echo "[INFO] Creating pre-change Nextcloud VM pair snapshot"
  NEXTCLOUD_SNAPSHOT_CHANGE_ID="18-register-nextcloud-appapi-daemon" \
    "${REPO_ROOT}/scripts/2-ops/workload/35-snapshot-nextcloud-pair.sh"
fi

if [ "${APPAPI_MODE}" = "docker-local" ] && [ "${APPAPI_PREPARE_DOCKER_LOCAL}" = "1" ]; then
  echo "[INFO] Preparing docker-local runtime on ${HOST_ALIAS}"
  ansible -i "${INVENTORY_PATH}" "${HOST_ALIAS}" -b -m shell -a "set -eu
    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get install -y ca-certificates curl gnupg lsb-release
    curl -fsSL https://get.docker.com | sh
    systemctl enable --now docker
    usermod -aG docker www-data || true
    php_fpm_service=\$(systemctl list-units --type=service --all 'php*-fpm.service' --no-legend | awk '{print \$1}' | head -n1)
    if [ -n \"\$php_fpm_service\" ]; then
      systemctl restart \"\$php_fpm_service\"
    fi
  "
fi

if [ "${APPAPI_MODE}" = "docker-local" ]; then
  ansible -i "${INVENTORY_PATH}" "${HOST_ALIAS}" -b -m shell -a "set -eu
    command -v docker >/dev/null 2>&1 || { echo 'docker missing'; exit 1; }
    sudo -u www-data docker version >/dev/null 2>&1 || { echo 'www-data cannot access docker'; exit 1; }
    api_ver=\$(sudo -u www-data docker version | awk -F': *' '/Server: Docker Engine - Community/{server=1} server && /API version:/{print \$2; exit}' | awk '{print \$1}')
    [ -n \"\$api_ver\" ] || { echo 'unable to parse docker server api version'; exit 1; }
    python3 - \"\$api_ver\" <<'PY'
import sys
v = sys.argv[1].strip()
def parse(x):
    return tuple(int(p) for p in x.split('.'))
if parse(v) < parse('1.44'):
    raise SystemExit(1)
PY
  " >/dev/null || runbook_fail "docker-local mode not ready on ${HOST_ALIAS}. Re-run with --prepare-docker-local."
fi

daemon_list="$(ansible -i "${INVENTORY_PATH}" "${HOST_ALIAS}" -b -m shell -a "set -eu; sudo -u www-data php '${OCC_PATH}' app_api:daemon:list" | sed '/^\s*$/d' || true)"
echo "${daemon_list}"

if printf '%s\n' "${daemon_list}" | grep -q "${APPAPI_DAEMON_NAME}"; then
  if [ "${APPAPI_REPLACE_EXISTING}" != "1" ]; then
    echo "[INFO] Daemon ${APPAPI_DAEMON_NAME} is already registered; leaving it unchanged."
    if [ "${APPAPI_POST_VERIFY}" = "1" ]; then
      echo "[INFO] Running ExApps health verification (daemon-only)"
      APPAPI_EXPECTED_DAEMON="${APPAPI_DAEMON_NAME}" EXAPP_REQUIRE_APP_ENABLED=0 \
        "${REPO_ROOT}/scripts/2-ops/workload/34-verify-nextcloud-exapps-health.sh"
    fi
    exit 0
  fi
  echo "[INFO] Replacing existing daemon ${APPAPI_DAEMON_NAME}"
  ansible -i "${INVENTORY_PATH}" "${HOST_ALIAS}" -b -m shell -a "set -eu; sudo -u www-data php '${OCC_PATH}' app_api:daemon:unregister '${APPAPI_DAEMON_NAME}'"
fi

register_cmd="sudo -u www-data php '${OCC_PATH}' app_api:daemon:register \
  '${APPAPI_DAEMON_NAME}' \
  '${APPAPI_DAEMON_DISPLAY_NAME}' \
  '${APPAPI_DAEMON_ACCEPTS_DEPLOY_ID}' \
  '${APPAPI_DAEMON_PROTOCOL}' \
  '${APPAPI_DAEMON_HOST}' \
  '${APPAPI_NEXTCLOUD_URL}'"

if [ -n "${APPAPI_DAEMON_NET}" ]; then
  register_cmd="${register_cmd} --net='${APPAPI_DAEMON_NET}'"
fi

if [ -n "${APPAPI_COMPUTE_DEVICE}" ]; then
  register_cmd="${register_cmd} --compute_device='${APPAPI_COMPUTE_DEVICE}'"
fi

if [ "${APPAPI_SET_DEFAULT}" = "1" ]; then
  register_cmd="${register_cmd} --set-default"
fi

echo "[INFO] Registering daemon ${APPAPI_DAEMON_NAME} on ${HOST_ALIAS}"
ansible -i "${INVENTORY_PATH}" "${HOST_ALIAS}" -b -m shell -a "set -eu; ${register_cmd}"

echo "[INFO] Current daemon list"
ansible -i "${INVENTORY_PATH}" "${HOST_ALIAS}" -b -m shell -a "set -eu; sudo -u www-data php '${OCC_PATH}' app_api:daemon:list"

if [ "${APPAPI_POST_VERIFY}" = "1" ]; then
  echo "[INFO] Running ExApps health verification (daemon-only)"
  APPAPI_EXPECTED_DAEMON="${APPAPI_DAEMON_NAME}" EXAPP_REQUIRE_APP_ENABLED=0 \
    "${REPO_ROOT}/scripts/2-ops/workload/34-verify-nextcloud-exapps-health.sh"
fi
