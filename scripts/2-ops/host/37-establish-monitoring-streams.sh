#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../lib/runbook.sh"

runbook_require_no_args "$@"
runbook_require_host_terminal

echo "[INFO] Establishing monitoring stream lane"

echo "[INFO] Step 1/5: install/upgrade monitoring stack"
"$REPO_ROOT/scripts/2-ops/observatory/11-install-monitoring-stack.sh"

echo "[INFO] Step 2/5: verify monitoring stack health"
"$REPO_ROOT/scripts/2-ops/observatory/12-verify-monitoring-stack.sh"

echo "[INFO] Step 3/5: apply monitoring public routing blueprint"
"$REPO_ROOT/scripts/2-ops/host/20-apply-observatory-monitoring-blueprint.sh"

echo "[INFO] Step 4/5: reconcile required Pangolin sites (best effort)"
if [ -n "${OP_SERVICE_ACCOUNT_TOKEN:-}" ]; then
  echo "[WARN] Skipping reconcile: OP_SERVICE_ACCOUNT_TOKEN is set (service-account mode)."
  echo "[WARN] Run manually after host auth:"
  echo "       unset OP_SERVICE_ACCOUNT_TOKEN && op signin && ./scripts/2-ops/host/27-reconcile-pangolin-sites.sh"
elif op whoami >/dev/null 2>&1; then
  "$REPO_ROOT/scripts/2-ops/host/27-reconcile-pangolin-sites.sh"
else
  echo "[WARN] Skipping reconcile: op CLI not authenticated in human-session mode."
  echo "[WARN] Run manually after host auth:"
  echo "       op signin && ./scripts/2-ops/host/27-reconcile-pangolin-sites.sh"
fi

echo "[INFO] Step 5/5: catalog + verify stream contract"
"$REPO_ROOT/scripts/2-ops/host/35-catalog-monitoring-streams.sh"
"$REPO_ROOT/scripts/2-ops/host/36-verify-monitoring-streams.sh"

echo "[OK] Monitoring stream lane establish run completed"
