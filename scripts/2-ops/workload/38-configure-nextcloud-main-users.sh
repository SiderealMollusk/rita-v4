#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../lib/runbook.sh"

runbook_require_no_args "$@"

CONFIG_FILE="$REPO_ROOT/ops/nextcloud/main-users.yaml"
ROTATE_SCRIPT="$SCRIPT_DIR/22-rotate-nextcloud-user-password.sh"

[ -f "$CONFIG_FILE" ] || runbook_fail "missing config file: $CONFIG_FILE"
[ -x "$ROTATE_SCRIPT" ] || runbook_fail "missing executable script: $ROTATE_SCRIPT"

runbook_require_cmd python3
runbook_require_cmd ansible
runbook_require_op_access

parsed="$(
python3 - "$CONFIG_FILE" <<'PY'
import json
import sys

path = sys.argv[1]
with open(path, "r", encoding="utf-8") as f:
    cfg = json.load(f)

vault_id = str(cfg.get("vault_id", "")).strip()
inventory_file = str(cfg.get("inventory_file", "ops/ansible/inventory/nextcloud.ini")).strip()
host_alias = str(cfg.get("host_alias", "nextcloud-vm")).strip()
occ_path = str(cfg.get("occ_path", "/var/www/nextcloud/occ")).strip()
op_username_field = str(cfg.get("op_username_field", "username")).strip()
op_password_field = str(cfg.get("op_password_field", "password")).strip()

print(f"VAULT_ID={vault_id}")
print(f"INVENTORY_FILE={inventory_file}")
print(f"HOST_ALIAS={host_alias}")
print(f"OCC_PATH={occ_path}")
print(f"OP_USERNAME_FIELD={op_username_field}")
print(f"OP_PASSWORD_FIELD={op_password_field}")

for user in cfg.get("users", []):
    if not isinstance(user, dict):
        continue
    enabled = bool(user.get("enabled", True))
    if not enabled:
        continue
    item_title = str(user.get("item_title", "")).strip()
    nextcloud_user = str(user.get("nextcloud_user", "")).strip()
    role = str(user.get("role", "user")).strip().lower()
    create_if_missing = bool(user.get("create_if_missing", True))
    require_match = bool(user.get("require_op_username_match", True))
    print(
        "USER\t" + "\t".join(
            [
                item_title,
                nextcloud_user,
                role,
                "1" if create_if_missing else "0",
                "1" if require_match else "0",
            ]
        )
    )
PY
)"

VAULT_ID="$(printf '%s\n' "$parsed" | sed -n 's/^VAULT_ID=//p' | head -n1)"
INVENTORY_FILE="$(printf '%s\n' "$parsed" | sed -n 's/^INVENTORY_FILE=//p' | head -n1)"
HOST_ALIAS="$(printf '%s\n' "$parsed" | sed -n 's/^HOST_ALIAS=//p' | head -n1)"
OCC_PATH="$(printf '%s\n' "$parsed" | sed -n 's/^OCC_PATH=//p' | head -n1)"
OP_USERNAME_FIELD="$(printf '%s\n' "$parsed" | sed -n 's/^OP_USERNAME_FIELD=//p' | head -n1)"
OP_PASSWORD_FIELD="$(printf '%s\n' "$parsed" | sed -n 's/^OP_PASSWORD_FIELD=//p' | head -n1)"

[ -n "$VAULT_ID" ] || runbook_fail "vault_id missing in $CONFIG_FILE"
[ -n "$INVENTORY_FILE" ] || runbook_fail "inventory_file missing in $CONFIG_FILE"
[ -n "$HOST_ALIAS" ] || runbook_fail "host_alias missing in $CONFIG_FILE"
[ -n "$OCC_PATH" ] || runbook_fail "occ_path missing in $CONFIG_FILE"
[ -n "$OP_USERNAME_FIELD" ] || runbook_fail "op_username_field missing in $CONFIG_FILE"
[ -n "$OP_PASSWORD_FIELD" ] || runbook_fail "op_password_field missing in $CONFIG_FILE"

INVENTORY_PATH="$REPO_ROOT/$INVENTORY_FILE"
[ -f "$INVENTORY_PATH" ] || runbook_fail "inventory path missing: $INVENTORY_PATH"

configured_count=0
while IFS=$'\t' read -r marker item_title nextcloud_user role create_if_missing require_match; do
  [ "$marker" = "USER" ] || continue
  [ -n "$item_title" ] || runbook_fail "users[].item_title missing in $CONFIG_FILE"
  [ -n "$nextcloud_user" ] || runbook_fail "users[].nextcloud_user missing for item $item_title"
  role="${role:-user}"
  case "$role" in
    admin|user) ;;
    *) runbook_fail "unsupported role '$role' for user '$nextcloud_user'" ;;
  esac

  echo "[INFO] Configuring Nextcloud user from OP item: $item_title -> $nextcloud_user (role=$role)"

  rotate_args=(
    --vault-id "$VAULT_ID"
    --item-title "$item_title"
    --op-username-field "$OP_USERNAME_FIELD"
    --op-password-field "$OP_PASSWORD_FIELD"
    --nextcloud-user "$nextcloud_user"
    --inventory "$INVENTORY_PATH"
    --host-alias "$HOST_ALIAS"
    --occ-path "$OCC_PATH"
  )

  if [ "$create_if_missing" = "1" ]; then
    rotate_args+=(--create-if-missing)
  fi
  if [ "$require_match" = "1" ]; then
    rotate_args+=(--require-op-username-match)
  fi
  if [ "$role" = "admin" ]; then
    rotate_args+=(--ensure-admin)
  fi

  "$ROTATE_SCRIPT" "${rotate_args[@]}"

  if [ "$role" = "user" ]; then
    user_b64="$(printf '%s' "$nextcloud_user" | base64 | tr -d '\n')"
    ansible -i "$INVENTORY_PATH" "$HOST_ALIAS" -b -m shell -a "set -eu
NC_USER=\"\$(printf '%s' '$user_b64' | base64 -d)\"
sudo -u www-data php '$OCC_PATH' group:removeuser admin \"\$NC_USER\" >/dev/null 2>&1 || true
"
  fi

  configured_count=$((configured_count + 1))
done < <(printf '%s\n' "$parsed" | grep $'^USER\t' || true)

[ "$configured_count" -gt 0 ] || runbook_fail "no enabled users found in $CONFIG_FILE"
echo "[OK] Configured ${configured_count} Nextcloud main user(s)."
