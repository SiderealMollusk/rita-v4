#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../lib/runbook.sh"

runbook_require_no_args "$@"
runbook_require_cmd op

GROUP_VARS="$REPO_ROOT/ops/ansible/group_vars/ops_brain.yml"
ROUTES_FILE="$REPO_ROOT/ops/network/routes.yml"
[ -f "$GROUP_VARS" ] || runbook_fail "missing group vars file at $GROUP_VARS"
[ -f "$ROUTES_FILE" ] || runbook_fail "missing routes file at $ROUTES_FILE"

ITEM_PREFIX="$(runbook_yaml_get "$GROUP_VARS" "pangolin_newt_credentials_item_prefix" || true)"
SITE_SLUG="$(runbook_yaml_get "$GROUP_VARS" "pangolin_newt_site_slug" || true)"
SITE_NAME="$(runbook_yaml_get "$GROUP_VARS" "pangolin_newt_site_name" || true)"
ITEM_TITLE="$(runbook_yaml_get "$GROUP_VARS" "pangolin_newt_credentials_item" || true)"
VAULT_ID="$(runbook_yaml_get "$GROUP_VARS" "pangolin_newt_credentials_vault_id" || true)"
ID_MIN_LENGTH="$(runbook_yaml_get "$GROUP_VARS" "pangolin_newt_id_min_length" || true)"
SECRET_MIN_LENGTH="$(runbook_yaml_get "$GROUP_VARS" "pangolin_newt_secret_min_length" || true)"
EXPECTED_ENDPOINT="$(runbook_yaml_get "$ROUTES_FILE" "pangolin_endpoint" || true)"

[ -n "$ITEM_PREFIX" ] || runbook_fail "pangolin_newt_credentials_item_prefix missing in $GROUP_VARS"
[ -n "$SITE_SLUG" ] || runbook_fail "pangolin_newt_site_slug missing in $GROUP_VARS"
[ -n "$SITE_NAME" ] || runbook_fail "pangolin_newt_site_name missing in $GROUP_VARS"
[ -n "$ITEM_TITLE" ] || runbook_fail "pangolin_newt_credentials_item missing in $GROUP_VARS"
[ -n "$VAULT_ID" ] || runbook_fail "pangolin_newt_credentials_vault_id missing in $GROUP_VARS"
[ -n "$ID_MIN_LENGTH" ] || runbook_fail "pangolin_newt_id_min_length missing in $GROUP_VARS"
[ -n "$SECRET_MIN_LENGTH" ] || runbook_fail "pangolin_newt_secret_min_length missing in $GROUP_VARS"
[ -n "$EXPECTED_ENDPOINT" ] || runbook_fail "pangolin_endpoint missing in $ROUTES_FILE"

EXPECTED_TITLE="${ITEM_PREFIX}${SITE_SLUG}"
[ "$ITEM_TITLE" = "$EXPECTED_TITLE" ] || runbook_fail "configured item title '$ITEM_TITLE' does not match expected '${EXPECTED_TITLE}'"

if [ -n "${OP_SERVICE_ACCOUNT_TOKEN:-}" ]; then
  echo "[INFO] Using 1Password service-account context"
else
  echo "[INFO] Verifying 1Password CLI user session"
  op whoami >/dev/null
fi

echo "[INFO] Reading Pangolin site note: $ITEM_TITLE"
SITE_NOTE_ENDPOINT="$(op item get "$ITEM_TITLE" --vault "$VAULT_ID" --fields label='endpoint')"
SITE_NOTE_NAME="$(op item get "$ITEM_TITLE" --vault "$VAULT_ID" --fields label='name')"
SITE_NOTE_ID="$(op item get "$ITEM_TITLE" --vault "$VAULT_ID" --fields label='id')"
SITE_NOTE_SECRET="$(op item get "$ITEM_TITLE" --vault "$VAULT_ID" --reveal --fields label='secret')"

[ -n "$SITE_NOTE_ENDPOINT" ] || runbook_fail "field 'endpoint' missing or empty in $ITEM_TITLE"
[ "$SITE_NOTE_ENDPOINT" = "$EXPECTED_ENDPOINT" ] || runbook_fail "field 'endpoint' mismatch: expected '$EXPECTED_ENDPOINT', got '$SITE_NOTE_ENDPOINT'"
[ -n "$SITE_NOTE_NAME" ] || runbook_fail "field 'name' missing or empty in $ITEM_TITLE"
[ "$SITE_NOTE_NAME" = "$SITE_NAME" ] || runbook_fail "field 'name' mismatch: expected '$SITE_NAME', got '$SITE_NOTE_NAME'"
case "$SITE_NOTE_SECRET" in
  "[use '"*" --reveal' to reveal]")
    runbook_fail "field 'secret' is still a concealed-field placeholder, not the revealed secret"
    ;;
esac

ID_LENGTH="${#SITE_NOTE_ID}"
SECRET_LENGTH="${#SITE_NOTE_SECRET}"

[ "$ID_LENGTH" -ge "$ID_MIN_LENGTH" ] || runbook_fail "site id too short: got length $ID_LENGTH, expected at least $ID_MIN_LENGTH"
[ "$SECRET_LENGTH" -ge "$SECRET_MIN_LENGTH" ] || runbook_fail "site secret too short: got length $SECRET_LENGTH, expected at least $SECRET_MIN_LENGTH"

echo "[OK] Pangolin site note is readable and matches repo contract"
echo "[INFO] title: $ITEM_TITLE"
echo "[INFO] endpoint: $SITE_NOTE_ENDPOINT"
echo "[INFO] name: $SITE_NOTE_NAME"
echo "[INFO] id length: $ID_LENGTH"
echo "[INFO] secret length: $SECRET_LENGTH"
