#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../lib/runbook.sh"

runbook_require_no_args "$@"
REPO_ROOT="$(runbook_detect_repo_root)"

INV="$REPO_ROOT/ops/ansible/inventory/vps.ini"
PB="$REPO_ROOT/ops/ansible/playbooks/30-install-eso.yml"

echo "[INFO] Installing External Secrets Operator"
ansible-playbook -i "$INV" "$PB"
