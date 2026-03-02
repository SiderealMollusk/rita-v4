#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../lib/runbook.sh"

runbook_require_no_args "$@"
REPO_ROOT="$(runbook_detect_repo_root)"
INV="$REPO_ROOT/ops/ansible/inventory/internal-cluster.ini"
PB="$REPO_ROOT/ops/ansible/playbooks/24-install-k3s-platform-agent.yml"
INTERNAL_VARS="$REPO_ROOT/ops/ansible/group_vars/internal_cluster.yml"
PLATFORM_VARS="$REPO_ROOT/ops/ansible/group_vars/platform.yml"

[ -f "$INTERNAL_VARS" ] || runbook_fail "missing group vars file at $INTERNAL_VARS"
[ -f "$PLATFORM_VARS" ] || runbook_fail "missing group vars file at $PLATFORM_VARS"
runbook_refresh_known_hosts_from_inventory "$INV"

echo "[INFO] Joining platform to the internal k3s cluster"
ansible-playbook -i "$INV" "$PB" -e "@$INTERNAL_VARS" -e "@$PLATFORM_VARS"
