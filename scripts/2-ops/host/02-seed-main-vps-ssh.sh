#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../lib/runbook.sh"

runbook_require_no_args "$@"
runbook_require_host_terminal
runbook_require_op_user_session

INV="$REPO_ROOT/ops/ansible/inventory/vps.ini"
SEED_SCRIPT="$REPO_ROOT/scripts/0-local-setup/03-vps/01-seed-ssh-admin-from-op.sh"

[ -f "$INV" ] || runbook_fail "missing inventory: $INV"
[ -x "$SEED_SCRIPT" ] || runbook_fail "missing executable script: $SEED_SCRIPT"

read -r HOST ADMIN_USER <<EOF2
$(awk '
  BEGIN { in_group=0 }
  /^\[vps\]/ { in_group=1; next }
  /^\[/ { in_group=0 }
  in_group && $0 !~ /^[[:space:]]*#/ && NF > 0 {
    user="virgil"
    host=""
    for (i=1; i<=NF; i++) {
      if ($i ~ /^ansible_host=/) { split($i,a,"="); host=a[2] }
      if ($i ~ /^ansible_user=/) { split($i,a,"="); user=a[2] }
    }
    if (host != "") { print host, user; exit }
  }
' "$INV")
EOF2

[ -n "${HOST:-}" ] || runbook_fail "could not derive host from $INV"
[ -n "${ADMIN_USER:-}" ] || ADMIN_USER="virgil"

echo "[INFO] Seeding main-vps SSH/admin access from canonical inventory: $HOST ($ADMIN_USER)"
exec "$SEED_SCRIPT" "$HOST" "$ADMIN_USER"
