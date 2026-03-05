#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../lib/runbook.sh"

runbook_require_no_args "$@"
runbook_require_host_terminal
runbook_require_op_user_session

GROUP_VARS="$REPO_ROOT/ops/ansible/group_vars/observatory.yml"
ROUTES_FILE="$REPO_ROOT/ops/network/routes.yml"

[ -f "$GROUP_VARS" ] || runbook_fail "missing group vars file at $GROUP_VARS"
[ -f "$ROUTES_FILE" ] || runbook_fail "missing routes file at $ROUTES_FILE"

PANGOLIN_ENDPOINT="$(runbook_yaml_get "$ROUTES_FILE" "pangolin_endpoint" || true)"
VAULT_ID="$(runbook_yaml_get "$GROUP_VARS" "pangolin_newt_credentials_vault_id" || true)"
SITE_NAME="$(runbook_yaml_get "$GROUP_VARS" "pangolin_newt_site_name" || true)"
ITEM_TITLE="$(runbook_yaml_get "$GROUP_VARS" "pangolin_newt_credentials_item" || true)"
SITE_IDENTIFIER_FIELD="$(runbook_yaml_get "$GROUP_VARS" "pangolin_newt_site_identifier_field" || true)"

[ -n "$PANGOLIN_ENDPOINT" ] || runbook_fail "pangolin_endpoint missing in $ROUTES_FILE"
[ -n "$VAULT_ID" ] || runbook_fail "pangolin_newt_credentials_vault_id missing in $GROUP_VARS"
[ -n "$ITEM_TITLE" ] || runbook_fail "pangolin_newt_credentials_item missing in $GROUP_VARS"
[ -n "$SITE_NAME" ] || runbook_fail "pangolin_newt_site_name missing in $GROUP_VARS"
[ -n "$SITE_IDENTIFIER_FIELD" ] || runbook_fail "pangolin_newt_site_identifier_field missing in $GROUP_VARS"

echo "[INFO] This script does not create a Pangolin site."
echo "[INFO] Prerequisite: you must already have created the site in Pangolin at:"
echo "       $PANGOLIN_ENDPOINT"
echo "[INFO] Paste the Pangolin Helm install snippet exactly as shown in the site creation screen."
echo "[INFO] This script will extract endpoint/id/secret and write the canonical OP item."
echo "[INFO] You must also provide the Pangolin site identifier from the site settings page."
echo "[INFO] The site identifier is not the same as the Newt credential id."

read -r -p "Pangolin site name: " PASTED_SITE_NAME
[ -n "$PASTED_SITE_NAME" ] || runbook_fail "Pangolin site name is empty"

if [ "$PASTED_SITE_NAME" != "$SITE_NAME" ]; then
  echo "[FAIL] Pasted site name '$PASTED_SITE_NAME' does not match repo-configured site '$SITE_NAME'."
  echo "[INFO] If this is intentional, update these canonical vars first:"
  echo "       $GROUP_VARS"
  echo "       - pangolin_newt_site_slug"
  echo "       - pangolin_newt_site_name"
  echo "       - pangolin_newt_credentials_item"
  exit 1
fi

read -r -p "Pangolin site identifier: " SITE_IDENTIFIER_VALUE
[ -n "$SITE_IDENTIFIER_VALUE" ] || runbook_fail "Pangolin site identifier is empty"

echo "[INFO] Paste Pangolin Helm snippet, then press Ctrl-D:"
HELM_SNIPPET="$(cat)"
[ -n "$HELM_SNIPPET" ] || runbook_fail "No Helm snippet was pasted"

extract_quoted_value() {
  local input="$1"
  local key="$2"
  printf '%s\n' "$input" | sed -n "s/.*${key}=\"\\([^\"]*\\)\".*/\\1/p" | tail -n 1
}

EXTRACTED_ENDPOINT="$(extract_quoted_value "$HELM_SNIPPET" "endpointKey")"
NEWT_ID_VALUE="$(extract_quoted_value "$HELM_SNIPPET" "idKey")"
NEWT_SECRET_VALUE="$(extract_quoted_value "$HELM_SNIPPET" "secretKey")"

[ -n "$EXTRACTED_ENDPOINT" ] || runbook_fail "Could not extract endpointKey from pasted Helm snippet"
[ -n "$NEWT_ID_VALUE" ] || runbook_fail "Could not extract idKey from pasted Helm snippet"
[ -n "$NEWT_SECRET_VALUE" ] || runbook_fail "Could not extract secretKey from pasted Helm snippet"

if [ "$EXTRACTED_ENDPOINT" != "$PANGOLIN_ENDPOINT" ]; then
  echo "[FAIL] Pasted endpoint '$EXTRACTED_ENDPOINT' does not match canonical repo endpoint '$PANGOLIN_ENDPOINT'."
  echo "[INFO] If Pangolin moved, update:"
  echo "       $ROUTES_FILE"
  exit 1
fi

if op item get "$ITEM_TITLE" --vault "$VAULT_ID" >/dev/null 2>&1; then
  echo "[INFO] Updating existing 1Password item: $ITEM_TITLE"
  op item edit "$ITEM_TITLE" --vault "$VAULT_ID" \
    "endpoint[text]=$PANGOLIN_ENDPOINT" \
    "name[text]=$SITE_NAME" \
    "${SITE_IDENTIFIER_FIELD}[text]=$SITE_IDENTIFIER_VALUE" \
    "newt_id[text]=$NEWT_ID_VALUE" \
    "secret[concealed]=$NEWT_SECRET_VALUE" >/dev/null
else
  echo "[INFO] Creating new 1Password item: $ITEM_TITLE"
  op item create --vault "$VAULT_ID" --category "Secure Note" --title "$ITEM_TITLE" \
    "endpoint[text]=$PANGOLIN_ENDPOINT" \
    "name[text]=$SITE_NAME" \
    "${SITE_IDENTIFIER_FIELD}[text]=$SITE_IDENTIFIER_VALUE" \
    "newt_id[text]=$NEWT_ID_VALUE" \
    "secret[concealed]=$NEWT_SECRET_VALUE" >/dev/null
fi

echo "[OK] 1Password item is ready: $ITEM_TITLE"
echo "[INFO] Endpoint stored from repo routes: $PANGOLIN_ENDPOINT"
echo "[INFO] Stored site identifier: $SITE_IDENTIFIER_VALUE"
echo "[INFO] Extracted id length: ${#NEWT_ID_VALUE}"
echo "[INFO] Extracted secret length: ${#NEWT_SECRET_VALUE}"
