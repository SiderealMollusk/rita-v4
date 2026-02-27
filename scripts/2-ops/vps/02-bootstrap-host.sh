#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../lib/runbook.sh"

runbook_require_no_args "$@"
REPO_ROOT="$(runbook_detect_repo_root)"

INV="$REPO_ROOT/ops/ansible/inventory/vps.ini"
PB="$REPO_ROOT/ops/ansible/playbooks/10-bootstrap-host.yml"
GROUP_VARS="$REPO_ROOT/ops/ansible/group_vars/vps.yml"

if [ ! -f "$GROUP_VARS" ]; then
  runbook_fail "missing group vars file at $GROUP_VARS"
fi

echo "[INFO] Running host bootstrap playbook"
ansible-playbook -i "$INV" "$PB" -e "@$GROUP_VARS"
