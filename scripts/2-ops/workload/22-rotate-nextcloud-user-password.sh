#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../lib/runbook.sh"

REPO_ROOT="$(runbook_detect_repo_root)"

INVENTORY_PATH="$REPO_ROOT/ops/ansible/inventory/nextcloud.ini"
HOST_ALIAS="nextcloud-vm"
VAULT_ID=""
ITEM_TITLE="virgil-admin"
OP_USERNAME_FIELD="username"
OP_PASSWORD_FIELD="password"
NEXTCLOUD_USER=""
NEXTCLOUD_OCC_PATH="/var/www/nextcloud/occ"
CREATE_IF_MISSING="false"
ENSURE_ADMIN_GROUP="false"

usage() {
  cat <<'EOF'
Usage:
  22-rotate-nextcloud-user-password.sh [options]

Options:
  --vault-id <id>              1Password vault ID (required)
  --item-title <title>         1Password item title (default: virgil-admin)
  --op-username-field <field>  OP username field label (default: username)
  --op-password-field <field>  OP password field label (default: password)
  --nextcloud-user <user>      Nextcloud username override (default: OP username field value)
  --inventory <path>           Ansible inventory path (default: ops/ansible/inventory/nextcloud.ini)
  --host-alias <host>          Inventory host alias (default: nextcloud-vm)
  --occ-path <path>            Remote occ path (default: /var/www/nextcloud/occ)
  --create-if-missing          Create the Nextcloud user if missing
  --ensure-admin               Ensure user is a member of Nextcloud admin group
  --help                       Show this help
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --vault-id)
      VAULT_ID="${2:-}"
      shift 2
      ;;
    --item-title)
      ITEM_TITLE="${2:-}"
      shift 2
      ;;
    --op-username-field)
      OP_USERNAME_FIELD="${2:-}"
      shift 2
      ;;
    --op-password-field)
      OP_PASSWORD_FIELD="${2:-}"
      shift 2
      ;;
    --nextcloud-user)
      NEXTCLOUD_USER="${2:-}"
      shift 2
      ;;
    --inventory)
      INVENTORY_PATH="${2:-}"
      shift 2
      ;;
    --host-alias)
      HOST_ALIAS="${2:-}"
      shift 2
      ;;
    --occ-path)
      NEXTCLOUD_OCC_PATH="${2:-}"
      shift 2
      ;;
    --create-if-missing)
      CREATE_IF_MISSING="true"
      shift
      ;;
    --ensure-admin)
      ENSURE_ADMIN_GROUP="true"
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      runbook_fail "Unknown argument: $1"
      ;;
  esac
done

[ -n "$VAULT_ID" ] || runbook_fail "--vault-id is required"
[ -f "$INVENTORY_PATH" ] || runbook_fail "missing inventory file: $INVENTORY_PATH"
[ -n "$HOST_ALIAS" ] || runbook_fail "--host-alias must not be empty"
[ -n "$ITEM_TITLE" ] || runbook_fail "--item-title must not be empty"
[ -n "$OP_USERNAME_FIELD" ] || runbook_fail "--op-username-field must not be empty"
[ -n "$OP_PASSWORD_FIELD" ] || runbook_fail "--op-password-field must not be empty"
[ -n "$NEXTCLOUD_OCC_PATH" ] || runbook_fail "--occ-path must not be empty"

runbook_require_cmd ansible
runbook_require_cmd op
runbook_require_op_access

read_op_field() {
  local item_title="$1"
  local vault_id="$2"
  local field_label="$3"
  local reveal_mode="${4:-0}"
  local value=""

  if [ "$reveal_mode" = "1" ]; then
    value="$(op item get "$item_title" --vault "$vault_id" --reveal --fields "label=$field_label" 2>/dev/null || true)"
    [ -n "$value" ] || value="$(op item get "$item_title" --vault "$vault_id" --reveal --fields "$field_label" 2>/dev/null || true)"
  else
    value="$(op item get "$item_title" --vault "$vault_id" --fields "label=$field_label" 2>/dev/null || true)"
    [ -n "$value" ] || value="$(op item get "$item_title" --vault "$vault_id" --fields "$field_label" 2>/dev/null || true)"
  fi

  printf '%s' "$value"
}

echo "[INFO] Reading target user + password from 1Password"
echo "[INFO] Vault: $VAULT_ID"
echo "[INFO] Item: $ITEM_TITLE"

OP_USER="$(read_op_field "$ITEM_TITLE" "$VAULT_ID" "$OP_USERNAME_FIELD" 0)"
OP_PASS="$(read_op_field "$ITEM_TITLE" "$VAULT_ID" "$OP_PASSWORD_FIELD" 1)"

[ -n "$OP_PASS" ] || runbook_fail "failed to read OP password field '$OP_PASSWORD_FIELD' from item '$ITEM_TITLE'"

if [ -z "$NEXTCLOUD_USER" ]; then
  [ -n "$OP_USER" ] || runbook_fail "failed to read OP username field '$OP_USERNAME_FIELD' from item '$ITEM_TITLE' (or set --nextcloud-user)"
  NEXTCLOUD_USER="$OP_USER"
fi

[ -n "$NEXTCLOUD_USER" ] || runbook_fail "resolved Nextcloud username is empty"

USER_B64="$(printf '%s' "$NEXTCLOUD_USER" | base64 | tr -d '\n')"
PASS_B64="$(printf '%s' "$OP_PASS" | base64 | tr -d '\n')"

echo "[INFO] Rotating password on Nextcloud host alias: $HOST_ALIAS"
echo "[INFO] Nextcloud user: $NEXTCLOUD_USER"
echo "[INFO] create-if-missing: $CREATE_IF_MISSING"
echo "[INFO] ensure-admin: $ENSURE_ADMIN_GROUP"

ansible -i "$INVENTORY_PATH" "$HOST_ALIAS" -b -m shell -a "set -eu
NC_USER=\"\$(printf '%s' '$USER_B64' | base64 -d)\"
NC_PASS=\"\$(printf '%s' '$PASS_B64' | base64 -d)\"
export OC_PASS=\"\$NC_PASS\"
if ! sudo -u www-data php '$NEXTCLOUD_OCC_PATH' user:info \"\$NC_USER\" >/dev/null 2>&1; then
  if [ \"$CREATE_IF_MISSING\" = \"true\" ]; then
    sudo -E -u www-data php '$NEXTCLOUD_OCC_PATH' user:add --password-from-env --display-name=\"\$NC_USER\" \"\$NC_USER\"
  else
    echo \"[FAIL] Nextcloud user not found: \$NC_USER\" >&2
    exit 1
  fi
fi
sudo -E -u www-data php '$NEXTCLOUD_OCC_PATH' user:resetpassword --password-from-env \"\$NC_USER\"
if [ \"$ENSURE_ADMIN_GROUP\" = \"true\" ]; then
  sudo -u www-data php '$NEXTCLOUD_OCC_PATH' group:adduser admin \"\$NC_USER\" >/dev/null 2>&1 || true
fi
"

echo "[OK] Nextcloud password rotation completed for user: $NEXTCLOUD_USER"
