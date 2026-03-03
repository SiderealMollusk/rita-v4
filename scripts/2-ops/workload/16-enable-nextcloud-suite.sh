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
)

echo "[INFO] Using kubeconfig: ${KUBECONFIG}"
echo "[INFO] Enabling Nextcloud collaboration suite apps on ${NAMESPACE}/${DEPLOYMENT}"

kubectl rollout status deployment/"${DEPLOYMENT}" -n "${NAMESPACE}" --timeout=10m

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
