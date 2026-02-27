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

echo "[INFO] Searching VPS logs for Pangolin setup token hints"
ansible -i "$INV" vps -b -m shell -a "set -e
if [ -d $PANGOLIN_INSTALL_DIR ]; then
  grep -R -Ei 'setup token|initial setup|auth/initial-setup' $PANGOLIN_INSTALL_DIR 2>/dev/null | tail -n 20 || true
fi
docker ps --no-trunc | awk 'NR>1 {print \$NF}' | grep -Ei 'pangolin|gerbil|traefik' | head -n 5 | while read -r n; do
  echo \"--- logs: \$n\"
  docker logs --tail 200 \"\$n\" 2>&1 | grep -Ei 'setup token|initial setup|auth/initial-setup' | tail -n 10 || true
done"

echo "[INFO] If token is shown above, store it in 1Password immediately."
echo "[OK] Token capture scan complete"
