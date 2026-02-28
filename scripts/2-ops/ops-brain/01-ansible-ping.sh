#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../lib/runbook.sh"

runbook_require_no_args "$@"
REPO_ROOT="$(runbook_detect_repo_root)"
INV="$REPO_ROOT/ops/ansible/inventory/ops-brain.ini"

runbook_require_cmd ansible
[ -f "$INV" ] || runbook_fail "inventory not found: $INV"

runbook_refresh_known_hosts_from_inventory "$INV"

echo "[INFO] Using inventory: $INV"
ansible-inventory -i "$INV" --list >/dev/null
if ! ansible -i "$INV" ops_brain -m ping; then
  echo "[INFO] If SSH/admin access needs to be re-seeded from the Mac host, run:"
  echo "       scripts/2-ops/host/01-seed-ops-brain-ssh.sh"
  exit 1
fi
