#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../lib/runbook.sh"

runbook_require_no_args "$@"
REPO_ROOT="$(runbook_detect_repo_root)"

INV="$REPO_ROOT/ops/ansible/inventory/vps.ini"

"$REPO_ROOT/scripts/2-ops/vps/06-pangolin-preflight.sh"

ansible -i "$INV" vps -b -m shell -a "pangolin status >/dev/null"
echo "[OK] pangolin status reports healthy on VPS"

echo "[OK] verification complete"
