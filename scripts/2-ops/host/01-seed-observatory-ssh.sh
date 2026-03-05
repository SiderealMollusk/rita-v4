#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../lib/runbook.sh"

runbook_require_no_args "$@"
runbook_require_host_terminal
runbook_require_op_access

SEED_SCRIPT="$REPO_ROOT/scripts/0-local-setup/01-lan/10-seed-observatory-ssh.sh"
[ -x "$SEED_SCRIPT" ] || runbook_fail "missing executable script: $SEED_SCRIPT"

echo "[INFO] Seeding observatory SSH/admin access from canonical inventory"
exec "$SEED_SCRIPT"
