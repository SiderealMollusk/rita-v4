#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../lib/runbook.sh"

runbook_require_no_args "$@"

REPO_ROOT="$(runbook_detect_repo_root)"
INVENTORY_PATH="$REPO_ROOT/ops/ansible/inventory/nextcloud.ini"
LOGIC_SCRIPT="$SCRIPT_DIR/22-rotate-nextcloud-user-password.sh"

VAULT_ID="sf7a6ejbujriiv6eyicexsp4yi"
ITEM_TITLE="virgil-admin"
HOST_ALIAS="nextcloud-vm"

[ -x "$LOGIC_SCRIPT" ] || runbook_fail "missing executable logic script: $LOGIC_SCRIPT"

echo "[INFO] Rotating Nextcloud user password from canonical nextcloud-main-users item"
echo "[INFO] Vault: $VAULT_ID"
echo "[INFO] Item: $ITEM_TITLE"

"$LOGIC_SCRIPT" \
  --vault-id "$VAULT_ID" \
  --item-title "$ITEM_TITLE" \
  --nextcloud-user "virgil-admin" \
  --create-if-missing \
  --ensure-admin \
  --inventory "$INVENTORY_PATH" \
  --host-alias "$HOST_ALIAS"
