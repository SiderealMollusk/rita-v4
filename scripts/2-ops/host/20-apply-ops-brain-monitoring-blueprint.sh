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
BLUEPRINT_FILE="$REPO_ROOT/ops/pangolin/blueprints/ops-brain/monitoring.blueprint.yaml"
BLUEPRINT_NAME="ops-brain-monitoring"
TMP_BLUEPRINT="$(mktemp /tmp/ops-brain-monitoring.blueprint.XXXXXX)"

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

echo "[INFO] Applying Pangolin blueprint from Mac host"
echo "[INFO] Blueprint file: $BLUEPRINT_FILE"
echo "[INFO] Blueprint name: $BLUEPRINT_NAME"
echo "[INFO] Site identifier: $SITE_IDENTIFIER"
echo "[INFO] This script assumes Pangolin CLI is already authenticated against pangolin-server."
echo "[INFO] This blueprint now changes the resource protection/auth field."
echo "[INFO] After apply:"
echo "       1. verify protection/auth worked in the Pangolin admin panel"
echo "       2. if apply or resource behavior diverges from the UI, this auth field is the first thing to suspect"

"$PANGOLIN_BIN" apply blueprint --file "$TMP_BLUEPRINT" --name "$BLUEPRINT_NAME"

echo "[OK] Blueprint apply command completed"
echo "[INFO] Verify the resulting resources in Pangolin UI and through route checks."
