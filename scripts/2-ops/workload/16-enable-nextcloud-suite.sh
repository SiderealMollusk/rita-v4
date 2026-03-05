#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
cd "${REPO_ROOT}"
# shellcheck source=/dev/null
source "${REPO_ROOT}/scripts/lib/runbook.sh"

runbook_source_labrc "${REPO_ROOT}"
runbook_export_default_kubeconfig
NEXTCLOUD_SNAPSHOT_MODE="${NEXTCLOUD_SNAPSHOT_MODE:-critical}"
if [ -n "${NEXTCLOUD_AUTO_SNAPSHOT_PRE:-}" ]; then
  if [ "${NEXTCLOUD_AUTO_SNAPSHOT_PRE}" = "1" ]; then
    NEXTCLOUD_SNAPSHOT_MODE="critical"
  else
    NEXTCLOUD_SNAPSHOT_MODE="off"
  fi
fi

NAMESPACE="${NEXTCLOUD_NAMESPACE:-workload}"
DEPLOYMENT="${NEXTCLOUD_DEPLOYMENT:-nextcloud}"

APPS=(
  circles
  text
  viewer
  files_versions
  contacts
  calendar
  deck
  notes
  tasks
  collectives
  spreed
)

echo "[INFO] Using kubeconfig: ${KUBECONFIG}"
echo "[INFO] Enabling Nextcloud collaboration suite apps on ${NAMESPACE}/${DEPLOYMENT}"

if [ "${NEXTCLOUD_SNAPSHOT_MODE}" = "critical" ]; then
  echo "[INFO] Creating pre-change Nextcloud VM pair snapshot"
  NEXTCLOUD_SNAPSHOT_CHANGE_ID="16-enable-nextcloud-suite" \
    "${REPO_ROOT}/scripts/2-ops/workload/35-snapshot-nextcloud-pair.sh"
fi

kubectl rollout status deployment/"${DEPLOYMENT}" -n "${NAMESPACE}" --timeout=10m

install_status="$(kubectl exec -n "${NAMESPACE}" deployment/"${DEPLOYMENT}" -- bash -lc "php occ status --output=json_pretty 2>/dev/null || php occ status" || true)"
echo "${install_status}"

if ! grep -q '"installed": true' <<<"${install_status}" && ! grep -q 'installed: true' <<<"${install_status}"; then
  echo "[INFO] Nextcloud is not installed yet; running maintenance:install with the deployment environment"
  kubectl exec -n "${NAMESPACE}" deployment/"${DEPLOYMENT}" -- bash -lc '
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
  kubectl exec -n "${NAMESPACE}" deployment/"${DEPLOYMENT}" -- bash -lc \
    "php occ app:install ${app} || php occ app:enable ${app}"
done

echo "[INFO] Setting cron background mode"
kubectl exec -n "${NAMESPACE}" deployment/"${DEPLOYMENT}" -- bash -lc \
  "php occ background:cron"

echo "[INFO] Enabled app list"
kubectl exec -n "${NAMESPACE}" deployment/"${DEPLOYMENT}" -- bash -lc \
  "php occ app:list"
