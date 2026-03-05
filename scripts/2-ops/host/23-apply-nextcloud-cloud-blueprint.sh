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
BLUEPRINT_FILE="$REPO_ROOT/ops/pangolin/blueprints/observatory/nextcloud-cloud.blueprint.yaml"
BLUEPRINT_NAME="observatory-nextcloud-cloud"
TMP_BLUEPRINT="$(mktemp /tmp/observatory-nextcloud-cloud.blueprint.XXXXXX)"
SITE_SLUG="${PANGOLIN_SITE_SLUG:-nextcloud_vm}"

[ -f "$GROUP_VARS" ] || runbook_fail "missing group vars file at $GROUP_VARS"
[ -f "$REQUIRED_SITES_FILE" ] || runbook_fail "missing required sites file at $REQUIRED_SITES_FILE"
[ -f "$BLUEPRINT_FILE" ] || runbook_fail "missing blueprint file at $BLUEPRINT_FILE"

runbook_require_op_access

VAULT_ID="$(runbook_yaml_get "$GROUP_VARS" "pangolin_newt_credentials_vault_id" || true)"
ITEM_TITLE="$(python3 - "$REQUIRED_SITES_FILE" "$SITE_SLUG" <<'PY'
import json
import sys
path = sys.argv[1]
slug = sys.argv[2]
with open(path, "r", encoding="utf-8") as f:
    sites = json.load(f)
for site in sites:
    if str(site.get("slug", "")) == slug:
        print(str(site.get("op_item_title", "")))
        raise SystemExit(0)
print("")
PY
)"
SITE_IDENTIFIER_FIELD="$(runbook_yaml_get "$GROUP_VARS" "pangolin_newt_site_identifier_field" || true)"

[ -n "$VAULT_ID" ] || runbook_fail "pangolin_newt_credentials_vault_id missing in $GROUP_VARS"
[ -n "$ITEM_TITLE" ] || runbook_fail "op_item_title missing for slug '$SITE_SLUG' in $REQUIRED_SITES_FILE"
[ -n "$SITE_IDENTIFIER_FIELD" ] || runbook_fail "pangolin_newt_site_identifier_field missing in $GROUP_VARS"

SITE_IDENTIFIER="$(op item get "$ITEM_TITLE" --vault "$VAULT_ID" --fields label="$SITE_IDENTIFIER_FIELD")"
[ -n "$SITE_IDENTIFIER" ] || runbook_fail "field '$SITE_IDENTIFIER_FIELD' missing or empty in $ITEM_TITLE"

sed "s/__SITE_IDENTIFIER__/$SITE_IDENTIFIER/g" "$BLUEPRINT_FILE" > "$TMP_BLUEPRINT"
trap 'rm -f "$TMP_BLUEPRINT"' EXIT

echo "[INFO] Applying cloud Nextcloud Pangolin blueprint from Mac host"
echo "[INFO] Blueprint file: $BLUEPRINT_FILE"
echo "[INFO] Blueprint name: $BLUEPRINT_NAME"
echo "[INFO] Site slug: $SITE_SLUG"
echo "[INFO] OP credentials item: $ITEM_TITLE"
echo "[INFO] Site identifier: $SITE_IDENTIFIER"
echo "[INFO] Target backend: 127.0.0.1:80 (local to Nextcloud VM site)"
echo "[INFO] This leaves app.virgil.info untouched while cloud.virgil.info is validated."

"$PANGOLIN_BIN" apply blueprint --file "$TMP_BLUEPRINT" --name "$BLUEPRINT_NAME"

echo "[OK] cloud Nextcloud blueprint apply command completed"
echo "[INFO] Verify in Pangolin that cloud.virgil.info now targets 127.0.0.1:80 on site '$SITE_SLUG'"
