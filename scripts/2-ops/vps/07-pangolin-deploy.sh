#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../lib/runbook.sh"

runbook_require_no_args "$@"
REPO_ROOT="$(runbook_detect_repo_root)"

"$REPO_ROOT/scripts/2-ops/vps/06-pangolin-preflight.sh"
INV="$REPO_ROOT/ops/ansible/inventory/vps.ini"
ROUTES_VARS="$REPO_ROOT/ops/network/routes.yml"

if [ -f "$ROUTES_VARS" ]; then
  PANGOLIN_ENDPOINT="$(runbook_yaml_get "$ROUTES_VARS" "pangolin_endpoint" || true)"
  [ -n "$PANGOLIN_ENDPOINT" ] && echo "[INFO] Target route endpoint: $PANGOLIN_ENDPOINT"
fi

echo "[INFO] running on VPS: pangolin up"
ansible -i "$INV" vps -b -m shell -a "pangolin up"
echo "[OK] pangolin deploy command completed"
