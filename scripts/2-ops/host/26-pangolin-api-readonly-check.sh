#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../lib/runbook.sh"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../lib/pangolin-session.sh"

runbook_require_no_args "$@"
runbook_require_host_terminal
runbook_require_op_access
runbook_require_cmd curl
runbook_require_cmd jq
runbook_require_cmd python3
runbook_source_labrc "$REPO_ROOT"

GROUP_VARS="$REPO_ROOT/ops/ansible/group_vars/observatory.yml"
REQUIRED_SITES_FILE="$REPO_ROOT/ops/pangolin/sites/required-sites.yaml"

[ -f "$GROUP_VARS" ] || runbook_fail "missing group vars file at $GROUP_VARS"
[ -f "$REQUIRED_SITES_FILE" ] || runbook_fail "missing required sites file at $REQUIRED_SITES_FILE"

VAULT_ID="$(runbook_yaml_get "$GROUP_VARS" "pangolin_newt_credentials_vault_id" || true)"
[ -n "$VAULT_ID" ] || runbook_fail "pangolin_newt_credentials_vault_id missing in $GROUP_VARS"

runbook_require_pangolin_session

echo "[INFO] Pangolin API host: ${PANGOLIN_SESSION_HOST}"
echo "[INFO] Pangolin org id: ${PANGOLIN_SESSION_ORG_ID}"
echo "[INFO] Required sites file: ${REQUIRED_SITES_FILE}"

LIVE_SITES_JSON="$(runbook_pangolin_api_get "/org/${PANGOLIN_SESSION_ORG_ID}/sites")"
REQUIRED_SITES_JSON="$(python3 - "$REQUIRED_SITES_FILE" <<'PY'
import json
import sys
path = sys.argv[1]
with open(path, "r", encoding="utf-8") as f:
    data = json.load(f)
print(json.dumps(data))
PY
)"

echo "[INFO] Checking required sites against Pangolin and OP schema"

missing_sites=0
missing_op_items=0
schema_failures=0

while IFS=$'\t' read -r slug display_name op_item_title connector_mode newt_enabled managed_mode; do
  [ -n "$slug" ] || continue

  site_row="$(python3 - "$LIVE_SITES_JSON" "$display_name" <<'PY'
import json
import sys
live = json.loads(sys.argv[1])
name = sys.argv[2]
sites = live.get("data", {}).get("sites", [])
for s in sites:
    if s.get("name") == name:
        print(f"{s.get('siteId','')}\t{s.get('niceId','')}\t{s.get('status','')}")
        break
PY
)"

  if [ -z "$site_row" ]; then
    if [ "$managed_mode" = "legacy" ]; then
      echo "[WARN] Legacy site missing in Pangolin: slug=${slug} name=${display_name}"
      continue
    fi
    echo "[FAIL] Site missing in Pangolin: slug=${slug} name=${display_name}"
    missing_sites=$((missing_sites + 1))
    continue
  fi

  IFS=$'\t' read -r site_id nice_id site_status <<EOF
$site_row
EOF
  echo "[OK] Site present: slug=${slug} name=${display_name} site_id=${site_id} nice_id=${nice_id} status=${site_status:-unknown}"

  if ! op item get "$op_item_title" --vault "$VAULT_ID" >/dev/null 2>&1; then
    echo "[FAIL] OP item missing: ${op_item_title}"
    missing_op_items=$((missing_op_items + 1))
    continue
  fi

  endpoint_val="$(op item get "$op_item_title" --vault "$VAULT_ID" --fields label=endpoint 2>/dev/null || true)"
  name_val="$(op item get "$op_item_title" --vault "$VAULT_ID" --fields label=name 2>/dev/null || true)"
  identifier_val="$(op item get "$op_item_title" --vault "$VAULT_ID" --fields label=identifier 2>/dev/null || true)"
  site_slug_val="$(op item get "$op_item_title" --vault "$VAULT_ID" --fields label=site_slug 2>/dev/null || true)"
  site_id_val="$(op item get "$op_item_title" --vault "$VAULT_ID" --fields label=site_id 2>/dev/null || true)"
  newt_id_val="$(op item get "$op_item_title" --vault "$VAULT_ID" --fields label=newt_id 2>/dev/null || true)"
  if [ -z "$newt_id_val" ]; then
    newt_id_val="$(op item get "$op_item_title" --vault "$VAULT_ID" --fields label=id 2>/dev/null || true)"
  fi
  newt_secret_val="$(op item get "$op_item_title" --vault "$VAULT_ID" --reveal --fields label=secret 2>/dev/null || true)"

  field_error=0
  [ -n "$endpoint_val" ] || { echo "[FAIL] ${op_item_title}: missing field endpoint"; field_error=1; }
  [ -n "$name_val" ] || { echo "[FAIL] ${op_item_title}: missing field name"; field_error=1; }
  [ -n "$identifier_val" ] || { echo "[FAIL] ${op_item_title}: missing field identifier"; field_error=1; }
  [ -n "$newt_id_val" ] || { echo "[FAIL] ${op_item_title}: missing field newt_id (or legacy id)"; field_error=1; }
  [ -n "$newt_secret_val" ] || { echo "[FAIL] ${op_item_title}: missing field secret"; field_error=1; }
  if [ "$managed_mode" = "managed" ]; then
    [ -n "$site_slug_val" ] || { echo "[FAIL] ${op_item_title}: missing field site_slug"; field_error=1; }
    [ -n "$site_id_val" ] || { echo "[FAIL] ${op_item_title}: missing field site_id"; field_error=1; }
  fi

  if [ "$field_error" -eq 1 ]; then
    schema_failures=$((schema_failures + 1))
    continue
  fi

  echo "[OK] OP schema present: ${op_item_title}"
done < <(python3 - "$REQUIRED_SITES_JSON" <<'PY'
import json
import sys
records = json.loads(sys.argv[1])
for r in records:
    print("\t".join([
        str(r.get("slug","")),
        str(r.get("display_name","")),
        str(r.get("op_item_title","")),
        str(r.get("connector_mode","")),
        str(r.get("newt_enabled","")),
        str(r.get("managed_mode","managed")),
    ]))
PY
)

echo
echo "[INFO] Summary:"
echo "       missing_sites=${missing_sites}"
echo "       missing_op_items=${missing_op_items}"
echo "       schema_failures=${schema_failures}"

[ "$missing_sites" -eq 0 ] || runbook_fail "Pangolin required sites are missing."
[ "$missing_op_items" -eq 0 ] || runbook_fail "Required OP items are missing."
[ "$schema_failures" -eq 0 ] || runbook_fail "OP item schema check failed."

echo "[OK] Pangolin + OP read-only check passed."
