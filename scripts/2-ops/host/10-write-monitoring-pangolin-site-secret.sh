#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../lib/runbook.sh"

runbook_require_no_args "$@"
runbook_require_host_terminal
runbook_require_op_user_session

GROUP_VARS="$REPO_ROOT/ops/ansible/group_vars/ops_brain.yml"
ROUTES_FILE="$REPO_ROOT/ops/network/routes.yml"

[ -f "$GROUP_VARS" ] || runbook_fail "missing group vars file at $GROUP_VARS"
[ -f "$ROUTES_FILE" ] || runbook_fail "missing routes file at $ROUTES_FILE"

PANGOLIN_ENDPOINT="$(runbook_yaml_get "$ROUTES_FILE" "pangolin_endpoint" || true)"
VAULT_ID="$(runbook_yaml_get "$GROUP_VARS" "pangolin_newt_credentials_vault_id" || true)"
SITE_NAME="$(runbook_yaml_get "$GROUP_VARS" "pangolin_newt_site_name" || true)"
ITEM_TITLE="$(runbook_yaml_get "$GROUP_VARS" "pangolin_newt_credentials_item" || true)"

[ -n "$PANGOLIN_ENDPOINT" ] || runbook_fail "pangolin_endpoint missing in $ROUTES_FILE"
[ -n "$VAULT_ID" ] || runbook_fail "pangolin_newt_credentials_vault_id missing in $GROUP_VARS"
[ -n "$ITEM_TITLE" ] || runbook_fail "pangolin_newt_credentials_item missing in $GROUP_VARS"
[ -n "$SITE_NAME" ] || runbook_fail "pangolin_newt_site_name missing in $GROUP_VARS"

echo "[INFO] This script does not create a Pangolin site."
echo "[INFO] Prerequisite: you must already have created the site in Pangolin at:"
echo "       $PANGOLIN_ENDPOINT"
echo "[INFO] You will need the issued site id and site secret from Pangolin before continuing."

if [ -n "${NEWT_ID:-}" ]; then
  NEWT_ID_VALUE="$NEWT_ID"
else
  read -r -p "Pangolin site id: " NEWT_ID_VALUE
fi

if [ -n "${NEWT_SECRET:-}" ]; then
  NEWT_SECRET_VALUE="$NEWT_SECRET"
else
  read -r -s -p "Pangolin site secret: " NEWT_SECRET_VALUE
  echo
fi

[ -n "$NEWT_ID_VALUE" ] || runbook_fail "Newt site id is empty"
[ -n "$NEWT_SECRET_VALUE" ] || runbook_fail "Newt site secret is empty"

if op item get "$ITEM_TITLE" --vault "$VAULT_ID" >/dev/null 2>&1; then
  echo "[INFO] Updating existing 1Password item: $ITEM_TITLE"
  op item edit "$ITEM_TITLE" --vault "$VAULT_ID" \
    "endpoint[text]=$PANGOLIN_ENDPOINT" \
    "name[text]=$SITE_NAME" \
    "id[text]=$NEWT_ID_VALUE" \
    "secret[concealed]=$NEWT_SECRET_VALUE" >/dev/null
else
  echo "[INFO] Creating new 1Password item: $ITEM_TITLE"
  op item create --vault "$VAULT_ID" --category "Secure Note" --title "$ITEM_TITLE" \
    "endpoint[text]=$PANGOLIN_ENDPOINT" \
    "name[text]=$SITE_NAME" \
    "id[text]=$NEWT_ID_VALUE" \
    "secret[concealed]=$NEWT_SECRET_VALUE" >/dev/null
fi

echo "[OK] 1Password item is ready: $ITEM_TITLE"
echo "[INFO] Endpoint stored from repo routes: $PANGOLIN_ENDPOINT"
