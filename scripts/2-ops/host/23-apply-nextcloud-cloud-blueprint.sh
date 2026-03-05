#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../lib/runbook.sh"

runbook_require_no_args "$@"
runbook_require_host_terminal

PANGOLIN_BIN="$(runbook_require_pangolin_cli)"

GROUP_VARS="$REPO_ROOT/ops/ansible/group_vars/ops_brain.yml"
BLUEPRINT_FILE="$REPO_ROOT/ops/pangolin/blueprints/ops-brain/nextcloud-cloud.blueprint.yaml"
BLUEPRINT_NAME="ops-brain-nextcloud-cloud"
TMP_BLUEPRINT="$(mktemp /tmp/ops-brain-nextcloud-cloud.blueprint.XXXXXX)"

[ -f "$GROUP_VARS" ] || runbook_fail "missing group vars file at $GROUP_VARS"
[ -f "$BLUEPRINT_FILE" ] || runbook_fail "missing blueprint file at $BLUEPRINT_FILE"

runbook_require_op_access

VAULT_ID="$(runbook_yaml_get "$GROUP_VARS" "pangolin_newt_credentials_vault_id" || true)"
ITEM_TITLE="$(runbook_yaml_get "$GROUP_VARS" "pangolin_newt_credentials_item" || true)"
SITE_IDENTIFIER_FIELD="$(runbook_yaml_get "$GROUP_VARS" "pangolin_newt_site_identifier_field" || true)"

[ -n "$VAULT_ID" ] || runbook_fail "pangolin_newt_credentials_vault_id missing in $GROUP_VARS"
[ -n "$ITEM_TITLE" ] || runbook_fail "pangolin_newt_credentials_item missing in $GROUP_VARS"
[ -n "$SITE_IDENTIFIER_FIELD" ] || runbook_fail "pangolin_newt_site_identifier_field missing in $GROUP_VARS"

SITE_IDENTIFIER="$(op item get "$ITEM_TITLE" --vault "$VAULT_ID" --fields label="$SITE_IDENTIFIER_FIELD")"
[ -n "$SITE_IDENTIFIER" ] || runbook_fail "field '$SITE_IDENTIFIER_FIELD' missing or empty in $ITEM_TITLE"

sed "s/__SITE_IDENTIFIER__/$SITE_IDENTIFIER/g" "$BLUEPRINT_FILE" > "$TMP_BLUEPRINT"
trap 'rm -f "$TMP_BLUEPRINT"' EXIT

echo "[INFO] Applying cloud Nextcloud Pangolin blueprint from Mac host"
echo "[INFO] Blueprint file: $BLUEPRINT_FILE"
echo "[INFO] Blueprint name: $BLUEPRINT_NAME"
echo "[INFO] Site identifier: $SITE_IDENTIFIER"
echo "[INFO] Target backend: 192.168.6.183:80"
echo "[INFO] This leaves app.virgil.info untouched while cloud.virgil.info is validated."

"$PANGOLIN_BIN" apply blueprint --file "$TMP_BLUEPRINT" --name "$BLUEPRINT_NAME"

echo "[OK] cloud Nextcloud blueprint apply command completed"
echo "[INFO] Verify in Pangolin that cloud.virgil.info now targets 192.168.6.183:80"
