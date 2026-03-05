#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../lib/runbook.sh"

runbook_require_no_args "$@"
runbook_require_host_terminal
runbook_require_cmd ansible
runbook_require_cmd op
runbook_require_op_write_access

REPO_ROOT="$(runbook_detect_repo_root)"
INVENTORY_PATH="$REPO_ROOT/ops/ansible/inventory/nextcloud.ini"
HOST_ALIAS="nextcloud-vm"
OCC_PATH="/var/www/nextcloud/occ"
OP_VAULT_ID_DEFAULT="5vr4hef2746tpplvjx424xafvu"
OP_ITEM_TITLE="nextcloud-talk-runtime"

[ -f "$INVENTORY_PATH" ] || runbook_fail "missing inventory: $INVENTORY_PATH"

echo "[INFO] Reading live Talk signaling secret from Nextcloud host: $HOST_ALIAS"
SIGNALING_SECRET="$(ansible -i "$INVENTORY_PATH" "$HOST_ALIAS" -b -m shell -a "sudo -u www-data php $OCC_PATH talk:signaling:list" \
  | sed -n 's/^secret:[[:space:]]*//p' | head -n1)"

[ -n "$SIGNALING_SECRET" ] || runbook_fail "unable to read signaling secret from occ talk:signaling:list"

echo "[INFO] Writing signaling secret to 1Password"
echo "[INFO] Vault: $OP_VAULT_ID_DEFAULT"
echo "[INFO] Item: $OP_ITEM_TITLE"

if op item get "$OP_ITEM_TITLE" --vault "$OP_VAULT_ID_DEFAULT" >/dev/null 2>&1; then
  op item edit "$OP_ITEM_TITLE" --vault "$OP_VAULT_ID_DEFAULT" "password=$SIGNALING_SECRET" >/dev/null
  echo "[OK] Updated OP item password field."
else
  op item create --category login --vault "$OP_VAULT_ID_DEFAULT" --title "$OP_ITEM_TITLE" \
    "username=nextcloud-talk-runtime" "password=$SIGNALING_SECRET" >/dev/null
  echo "[OK] Created OP item with password field."
fi

echo "[INFO] Canonical OP reference:"
echo "       op://$OP_VAULT_ID_DEFAULT/$OP_ITEM_TITLE/password"
echo "[OK] Talk signaling secret seed complete."
