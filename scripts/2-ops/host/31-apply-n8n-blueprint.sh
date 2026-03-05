#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../lib/runbook.sh"

runbook_require_no_args "$@"
runbook_require_host_terminal

PANGOLIN_BIN="$(runbook_require_pangolin_cli)"

GROUP_VARS="$REPO_ROOT/ops/ansible/group_vars/observatory.yml"
REQUIRED_SITES_FILE="$REPO_ROOT/ops/pangolin/sites/required-sites.yaml"
BLUEPRINT_FILE="$REPO_ROOT/ops/pangolin/blueprints/observatory/n8n.blueprint.yaml"
BLUEPRINT_NAME="workload-n8n"
TMP_BLUEPRINT="$(mktemp /tmp/workload-n8n.blueprint.XXXXXX)"

[ -f "$GROUP_VARS" ] || runbook_fail "missing group vars file at $GROUP_VARS"
[ -f "$REQUIRED_SITES_FILE" ] || runbook_fail "missing required sites file at $REQUIRED_SITES_FILE"
[ -f "$BLUEPRINT_FILE" ] || runbook_fail "missing blueprint file at $BLUEPRINT_FILE"

runbook_require_op_access
runbook_require_cmd python3

VAULT_ID="$(runbook_yaml_get "$GROUP_VARS" "pangolin_newt_credentials_vault_id" || true)"
SITE_IDENTIFIER_FIELD="$(runbook_yaml_get "$GROUP_VARS" "pangolin_newt_site_identifier_field" || true)"

[ -n "$VAULT_ID" ] || runbook_fail "pangolin_newt_credentials_vault_id missing in $GROUP_VARS"
[ -n "$SITE_IDENTIFIER_FIELD" ] || runbook_fail "pangolin_newt_site_identifier_field missing in $GROUP_VARS"

ITEM_TITLE="$(python3 - "$REQUIRED_SITES_FILE" <<'PY'
import json
import sys
records = json.load(open(sys.argv[1], "r", encoding="utf-8"))
for rec in records:
    if rec.get("slug") == "n8n_vm":
        print(rec.get("op_item_title", ""))
        break
PY
)"
[ -n "$ITEM_TITLE" ] || runbook_fail "required site slug n8n_vm is missing op_item_title in $REQUIRED_SITES_FILE"

SITE_IDENTIFIER="$(op item get "$ITEM_TITLE" --vault "$VAULT_ID" --fields label="$SITE_IDENTIFIER_FIELD" 2>/dev/null || true)"
[ -n "$SITE_IDENTIFIER" ] || runbook_fail "field '$SITE_IDENTIFIER_FIELD' missing or empty in OP item $ITEM_TITLE"

sed "s/__SITE_IDENTIFIER__/$SITE_IDENTIFIER/g" "$BLUEPRINT_FILE" > "$TMP_BLUEPRINT"
trap 'rm -f "$TMP_BLUEPRINT"' EXIT

echo "[INFO] Applying n8n Pangolin blueprint from Mac host"
echo "[INFO] Blueprint file: $BLUEPRINT_FILE"
echo "[INFO] Blueprint name: $BLUEPRINT_NAME"
echo "[INFO] Site identifier source item: $ITEM_TITLE"
echo "[INFO] Site identifier: $SITE_IDENTIFIER"
echo "[INFO] Target backend: 10.43.171.251:5678"
echo "[INFO] This script assumes Pangolin CLI is already authenticated against pangolin-server."

"$PANGOLIN_BIN" apply blueprint --file "$TMP_BLUEPRINT" --name "$BLUEPRINT_NAME"

echo "[OK] n8n blueprint apply command completed"
echo "[INFO] Verify in Pangolin that n8n.virgil.info targets 10.43.171.251:5678 via site $SITE_IDENTIFIER"
