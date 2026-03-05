#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../lib/runbook.sh"

runbook_require_no_args "$@"
REPO_ROOT="$(runbook_detect_repo_root)"
INV="$REPO_ROOT/ops/ansible/inventory/nextcloud.ini"
PB="$REPO_ROOT/ops/ansible/playbooks/34-verify-nextcloud-core.yml"
GROUP_VARS="$REPO_ROOT/ops/ansible/group_vars/nextcloud.yml"

[ -f "$GROUP_VARS" ] || runbook_fail "missing group vars file at $GROUP_VARS"

echo "[INFO] Verifying nextcloud-core baseline"
ansible-playbook -i "$INV" "$PB" -e "@$GROUP_VARS"
