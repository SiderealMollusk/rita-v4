#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
cd "${REPO_ROOT}"

runbook_source_labrc "${REPO_ROOT}"
runbook_export_default_kubeconfig

NAMESPACE="${NEXTCLOUD_NAMESPACE:-workload}"
DEPLOYMENT="${NEXTCLOUD_DEPLOYMENT:-nextcloud}"
FLOW_VERSION="${NEXTCLOUD_FLOW_VERSION:-1.3.1}"
FLOW_TARBALL_URL="${NEXTCLOUD_FLOW_TARBALL_URL:-https://github.com/nextcloud-releases/flow/releases/download/v${FLOW_VERSION}/flow-v${FLOW_VERSION}.tar.gz}"

APPS=(
  app_api
  webhook_listeners
)

occ() {
  kubectl exec -n "${NAMESPACE}" deployment/"${DEPLOYMENT}" -- bash -lc "$1"
}

echo "[INFO] Using kubeconfig: ${KUBECONFIG}"
echo "[INFO] Enabling Nextcloud Flow prerequisites on ${NAMESPACE}/${DEPLOYMENT}"

kubectl rollout status deployment/"${DEPLOYMENT}" -n "${NAMESPACE}" --timeout=10m

install_status="$(occ "php occ status --output=json_pretty 2>/dev/null || php occ status" || true)"
echo "${install_status}"

if ! grep -q '"installed": true' <<<"${install_status}" && ! grep -q 'installed: true' <<<"${install_status}"; then
  echo "[INFO] Nextcloud is not installed yet; running maintenance:install with the deployment environment"
  occ '
    php occ maintenance:install -n \
      --admin-user "$NEXTCLOUD_ADMIN_USER" \
      --admin-pass "$NEXTCLOUD_ADMIN_PASSWORD" \
      --database pgsql \
      --database-name "$POSTGRES_DB" \
      --database-user "$POSTGRES_USER" \
      --database-pass "$POSTGRES_PASSWORD" \
      --database-host "$POSTGRES_HOST"
  '
fi

for app in "${APPS[@]}"; do
  echo "[INFO] Installing/enabling app: ${app}"
  occ "php occ app:install ${app} || php occ app:enable ${app}"
done

flow_enabled="$(occ "php occ app:list | sed -n '/Enabled:/,/Disabled:/p' | grep -c '^  - flow:' || true")"

if [ "${flow_enabled}" = "0" ]; then
  echo "[INFO] Installing Flow release tarball ${FLOW_VERSION}"
  kubectl exec -n "${NAMESPACE}" deployment/"${DEPLOYMENT}" -- bash -lc "
    set -euo pipefail
    cd /tmp
    curl -fL --retry 3 --connect-timeout 20 -o flow-v${FLOW_VERSION}.tar.gz '${FLOW_TARBALL_URL}'
    if [ -d /var/www/html/custom_apps/flow ]; then
      mv /var/www/html/custom_apps/flow /var/www/html/custom_apps/flow.preinstall.\$(date +%s)
    fi
    mkdir -p /var/www/html/custom_apps
    tar -xzf flow-v${FLOW_VERSION}.tar.gz -C /var/www/html/custom_apps
    cd /var/www/html
    php occ app:enable flow
  "
else
  echo "[INFO] Flow is already enabled"
fi

echo "[INFO] Checking AppAPI deploy daemon registration"
set +e
daemon_status="$(occ "php occ app_api:daemon:list" 2>&1)"
daemon_rc=$?
set -e
echo "${daemon_status}"

if [ "${daemon_rc}" -ne 0 ]; then
  echo "[WARN] Unable to query AppAPI deploy daemons via occ."
  echo "[WARN] Flow is installed, but it will not be usable until AppAPI has a working deploy daemon."
  exit 0
fi

echo "[INFO] Flow app list status"
occ "php occ app:list | sed -n '/Enabled:/,/Disabled:/p' | grep -E 'app_api|flow|webhook_listeners' || true"

echo "[INFO] Flow install step completed"
echo "[INFO] If no deploy daemon is listed above, register one before deploying the Flow ExApp."
echo "[INFO] Canonical next steps:"
echo "       1. scripts/2-ops/workload/18-register-nextcloud-appapi-daemon.sh"
echo "       2. scripts/2-ops/workload/19-deploy-nextcloud-flow-exapp.sh"
