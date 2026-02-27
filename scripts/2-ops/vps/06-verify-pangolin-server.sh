#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../lib/runbook.sh"

runbook_require_no_args "$@"
REPO_ROOT="$(runbook_detect_repo_root)"

INV="$REPO_ROOT/ops/ansible/inventory/vps.ini"
GROUP_VARS="$REPO_ROOT/ops/ansible/group_vars/vps.yml"
ROUTES_VARS="$REPO_ROOT/ops/network/routes.yml"

[ -f "$GROUP_VARS" ] || runbook_fail "missing group vars file at $GROUP_VARS"

runbook_refresh_known_hosts_from_inventory "$INV"

PANGOLIN_INSTALL_DIR="$(runbook_yaml_get "$GROUP_VARS" "pangolin_install_dir" || true)"
[ -n "$PANGOLIN_INSTALL_DIR" ] || runbook_fail "pangolin_install_dir missing in $GROUP_VARS"

echo "[INFO] Verifying Docker is active"
ansible -i "$INV" vps -b -m shell -a "systemctl is-active --quiet docker"
echo "[OK] Docker service is active"

echo "[INFO] Verifying Pangolin-related containers exist"
if ansible -i "$INV" vps -b -m shell -a "docker ps --no-trunc | awk 'NR>1 {print \$NF}' | grep -Eiq 'pangolin|gerbil|traefik'"; then
  echo "[OK] Pangolin-related container detected"
else
  echo "[WARN] No Pangolin-related running containers found."
  echo "[INFO] No-op: installer likely has not completed yet."
  echo "[INFO] Run installer, then rerun this verify step:"
  echo "       sudo bash $PANGOLIN_INSTALL_DIR/get-installer.sh"
  exit 0
fi

echo "[INFO] Showing container status"
ansible -i "$INV" vps -b -m shell -a "docker ps"

if [ -f "$ROUTES_VARS" ]; then
  PANGOLIN_ENDPOINT="$(runbook_yaml_get "$ROUTES_VARS" "pangolin_endpoint" || true)"
  if [ -n "$PANGOLIN_ENDPOINT" ]; then
    echo "[INFO] Checking endpoint from VPS: $PANGOLIN_ENDPOINT"
    ansible -i "$INV" vps -b -m shell -a "curl -kfsS --max-time 10 $PANGOLIN_ENDPOINT >/dev/null"
    echo "[OK] endpoint responds: $PANGOLIN_ENDPOINT"
  fi
fi

echo "[OK] Verification complete"
