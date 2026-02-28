#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../lib/runbook.sh"

runbook_require_no_args "$@"
REPO_ROOT="$(runbook_detect_repo_root)"

INV="$REPO_ROOT/ops/ansible/inventory/vps.ini"

runbook_require_cmd ansible

if [ ! -f "$INV" ]; then
  runbook_fail "Inventory not found: $INV"
fi

runbook_refresh_known_hosts_from_inventory "$INV"

echo "[INFO] Using inventory: $INV"
ansible-inventory -i "$INV" --list >/dev/null
if ! ansible -i "$INV" vps -m ping -b; then
  echo "[INFO] If SSH/admin access needs to be re-seeded from the Mac host, run:"
  echo "       scripts/2-ops/host/02-seed-main-vps-ssh.sh"
  exit 1
fi
