#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../lib/runbook.sh"

runbook_require_no_args "$@"
runbook_require_host_terminal
runbook_require_cmd ansible-playbook

INV="$REPO_ROOT/ops/ansible/inventory/vps.ini"
PB="$REPO_ROOT/ops/ansible/playbooks/43-security-maintenance-vps.yml"
VARS="$REPO_ROOT/ops/ansible/group_vars/vps.yml"

[ -f "$INV" ] || runbook_fail "inventory not found: $INV"
[ -f "$PB" ] || runbook_fail "playbook not found: $PB"
[ -f "$VARS" ] || runbook_fail "group vars not found: $VARS"

runbook_refresh_known_hosts_from_inventory "$INV"

echo "[INFO] Running VPS security maintenance playbook"
ansible-playbook -i "$INV" "$PB" -e "@$VARS"

echo "[OK] VPS security maintenance completed"
echo "[INFO] Remote status file: /var/lib/rita/security-maintenance.status"
echo "[INFO] Remote log file: /var/log/security-maintenance.log"
