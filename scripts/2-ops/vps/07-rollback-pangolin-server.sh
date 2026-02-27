#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../lib/runbook.sh"

runbook_require_no_args "$@"
REPO_ROOT="$(runbook_detect_repo_root)"

INV="$REPO_ROOT/ops/ansible/inventory/vps.ini"
GROUP_VARS="$REPO_ROOT/ops/ansible/group_vars/vps.yml"

[ -f "$GROUP_VARS" ] || runbook_fail "missing group vars file at $GROUP_VARS"

runbook_refresh_known_hosts_from_inventory "$INV"

PANGOLIN_INSTALL_DIR="$(runbook_yaml_get "$GROUP_VARS" "pangolin_install_dir" || true)"
[ -n "$PANGOLIN_INSTALL_DIR" ] || runbook_fail "pangolin_install_dir missing in $GROUP_VARS"

echo "[INFO] Rolling back Pangolin server (compose down if compose file exists)"
ansible -i "$INV" vps -b -m shell -a "set -e
if [ -f $PANGOLIN_INSTALL_DIR/docker-compose.yml ]; then
  cd $PANGOLIN_INSTALL_DIR
  docker compose down
else
  echo 'No docker-compose.yml found; stopping Pangolin-related containers by name pattern.'
  docker ps --no-trunc | awk 'NR>1 && \$NF ~ /(pangolin|gerbil|traefik)/ {print \$1}' | xargs -r docker stop
fi"

echo "[OK] Rollback command complete"
