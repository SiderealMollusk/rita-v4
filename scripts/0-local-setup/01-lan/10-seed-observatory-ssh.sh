#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

INV="$REPO_ROOT/ops/ansible/inventory/observatory.ini"
SEED_SCRIPT="$SCRIPT_DIR/01-seed-ssh-admin-from-op.sh"

[ -f "$INV" ] || { echo "[FAIL] missing inventory: $INV"; exit 1; }
[ -x "$SEED_SCRIPT" ] || { echo "[FAIL] missing executable script: $SEED_SCRIPT"; exit 1; }

read -r HOST ADMIN_USER <<EOF
$(awk '
  BEGIN { in_group=0 }
  /^\[observatory\]/ { in_group=1; next }
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
EOF

[ -n "${HOST:-}" ] || { echo "[FAIL] could not derive host from $INV"; exit 1; }
[ -n "${ADMIN_USER:-}" ] || ADMIN_USER="virgil"

echo "[INFO] Seeding observatory SSH from canonical inventory: $HOST ($ADMIN_USER)"
exec "$SEED_SCRIPT" "$HOST" "$ADMIN_USER"
