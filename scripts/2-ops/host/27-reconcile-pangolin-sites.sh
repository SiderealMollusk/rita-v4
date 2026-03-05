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
runbook_require_op_write_access
runbook_require_cmd curl
runbook_require_cmd jq
runbook_require_cmd python3
runbook_source_labrc "$REPO_ROOT"

GROUP_VARS="$REPO_ROOT/ops/ansible/group_vars/ops_brain.yml"
ROUTES_FILE="$REPO_ROOT/ops/network/routes.yml"
REQUIRED_SITES_FILE="$REPO_ROOT/ops/pangolin/sites/required-sites.yaml"

[ -f "$GROUP_VARS" ] || runbook_fail "missing group vars file at $GROUP_VARS"
[ -f "$ROUTES_FILE" ] || runbook_fail "missing routes file at $ROUTES_FILE"
[ -f "$REQUIRED_SITES_FILE" ] || runbook_fail "missing required sites file at $REQUIRED_SITES_FILE"

VAULT_ID="$(runbook_yaml_get "$GROUP_VARS" "pangolin_newt_credentials_vault_id" || true)"
[ -n "$VAULT_ID" ] || runbook_fail "pangolin_newt_credentials_vault_id missing in $GROUP_VARS"

PANGOLIN_ENDPOINT="$(runbook_yaml_get "$ROUTES_FILE" "pangolin_endpoint" || true)"
[ -n "$PANGOLIN_ENDPOINT" ] || runbook_fail "pangolin_endpoint missing in $ROUTES_FILE"

runbook_require_pangolin_session

REQUIRED_SITES_JSON="$(python3 - "$REQUIRED_SITES_FILE" <<'PY'
import json
import sys
with open(sys.argv[1], "r", encoding="utf-8") as f:
    print(json.dumps(json.load(f)))
PY
)"

echo "[INFO] Pangolin API host: ${PANGOLIN_SESSION_HOST}"
echo "[INFO] Pangolin org id: ${PANGOLIN_SESSION_ORG_ID}"
echo "[INFO] OP vault id: ${VAULT_ID}"
echo "[INFO] Required sites file: ${REQUIRED_SITES_FILE}"
FORCE_ROTATE="${PANGOLIN_FORCE_ROTATE:-0}"
if [ "$FORCE_ROTATE" = "1" ]; then
  echo "[WARN] PANGOLIN_FORCE_ROTATE=1 enabled; all managed VM sites will be recreated."
fi

created_count=0
updated_count=0
reused_count=0

sanitize_single_line() {
  printf '%s' "${1:-}" | tr -d '\r\n'
}

while IFS=$'\t' read -r slug display_name op_item_title managed_mode rebuild_policy; do
  [ -n "$slug" ] || continue
  if [ "$managed_mode" != "managed" ]; then
    echo "[INFO] Skipping legacy-managed site: ${slug} (${display_name})"
    continue
  fi
  echo
  echo "[INFO] Reconciling site: slug=${slug} name=${display_name} op_item=${op_item_title}"

  live_sites_json="$(runbook_pangolin_api_get "/org/${PANGOLIN_SESSION_ORG_ID}/sites")"
  site_row="$(python3 - "$live_sites_json" "$display_name" <<'PY'
import json
import sys
live = json.loads(sys.argv[1])
name = sys.argv[2]
sites = live.get("data", {}).get("sites", [])
for s in sites:
    if s.get("name") == name:
        print(f"{s.get('siteId','')}\t{s.get('niceId','')}")
        break
PY
)"

  created_new=0
  newt_id=""
  newt_secret=""
  site_id=""
  site_identifier=""

  if [ -z "$site_row" ]; then
    defaults_json="$(runbook_pangolin_api_get "/org/${PANGOLIN_SESSION_ORG_ID}/pick-site-defaults")"
    newt_id="$(python3 - "$defaults_json" <<'PY'
import json,sys
obj=json.loads(sys.argv[1])
print(obj.get("data",{}).get("newtId",""))
PY
)"
    newt_secret="$(python3 - "$defaults_json" <<'PY'
import json,sys
obj=json.loads(sys.argv[1])
print(obj.get("data",{}).get("newtSecret",""))
PY
)"
    client_address="$(python3 - "$defaults_json" <<'PY'
import json,sys
obj=json.loads(sys.argv[1])
print(obj.get("data",{}).get("clientAddress",""))
PY
)"

    [ -n "$newt_id" ] || runbook_fail "missing newtId from defaults for ${display_name}"
    [ -n "$newt_secret" ] || runbook_fail "missing newtSecret from defaults for ${display_name}"
    [ -n "$client_address" ] || runbook_fail "missing clientAddress from defaults for ${display_name}"

    create_payload="$(python3 - "$display_name" "$client_address" "$newt_id" "$newt_secret" <<'PY'
import json,sys
name, address, newt_id, secret = sys.argv[1:5]
print(json.dumps({
  "name": name,
  "type": "newt",
  "address": address,
  "newtId": newt_id,
  "secret": secret
}))
PY
)"
    create_resp="$(runbook_pangolin_api_put_json "/org/${PANGOLIN_SESSION_ORG_ID}/site" "$create_payload")"
    site_id="$(python3 - "$create_resp" <<'PY'
import json,sys
obj=json.loads(sys.argv[1])
print(obj.get("data",{}).get("siteId",""))
PY
)"
    site_identifier="$(python3 - "$create_resp" <<'PY'
import json,sys
obj=json.loads(sys.argv[1])
print(obj.get("data",{}).get("niceId",""))
PY
)"
    [ -n "$site_id" ] || runbook_fail "site create did not return siteId for ${display_name}"
    [ -n "$site_identifier" ] || runbook_fail "site create did not return niceId for ${display_name}"
    created_new=1
    echo "[OK] Created Pangolin site: ${display_name} (site_id=${site_id}, identifier=${site_identifier})"
    created_count=$((created_count + 1))
  else
    IFS=$'\t' read -r site_id site_identifier <<EOF
$site_row
EOF
    [ -n "$site_id" ] || runbook_fail "existing site row missing site_id for ${display_name}"
    [ -n "$site_identifier" ] || runbook_fail "existing site row missing identifier for ${display_name}"
    echo "[OK] Site already exists: ${display_name} (site_id=${site_id}, identifier=${site_identifier})"
  fi

  if [ "$created_new" -eq 0 ] && [ "$FORCE_ROTATE" = "1" ]; then
    if [ "$rebuild_policy" != "rotate" ]; then
      runbook_fail "PANGOLIN_FORCE_ROTATE=1 requested but rebuild_policy for ${display_name} is ${rebuild_policy}."
    fi
    echo "[WARN] Forcing rotate for ${display_name}."
    runbook_pangolin_api_delete "/site/${site_id}" >/dev/null
    defaults_json="$(runbook_pangolin_api_get "/org/${PANGOLIN_SESSION_ORG_ID}/pick-site-defaults")"
    newt_id="$(python3 - "$defaults_json" <<'PY'
import json,sys
obj=json.loads(sys.argv[1])
print(obj.get("data",{}).get("newtId",""))
PY
)"
    newt_secret="$(python3 - "$defaults_json" <<'PY'
import json,sys
obj=json.loads(sys.argv[1])
print(obj.get("data",{}).get("newtSecret",""))
PY
)"
    client_address="$(python3 - "$defaults_json" <<'PY'
import json,sys
obj=json.loads(sys.argv[1])
print(obj.get("data",{}).get("clientAddress",""))
PY
)"
    [ -n "$newt_id" ] || runbook_fail "missing newtId from defaults for ${display_name}"
    [ -n "$newt_secret" ] || runbook_fail "missing newtSecret from defaults for ${display_name}"
    [ -n "$client_address" ] || runbook_fail "missing clientAddress from defaults for ${display_name}"
    create_payload="$(python3 - "$display_name" "$client_address" "$newt_id" "$newt_secret" <<'PY'
import json,sys
name, address, newt_id, secret = sys.argv[1:5]
print(json.dumps({
  "name": name,
  "type": "newt",
  "address": address,
  "newtId": newt_id,
  "secret": secret
}))
PY
)"
    create_resp="$(runbook_pangolin_api_put_json "/org/${PANGOLIN_SESSION_ORG_ID}/site" "$create_payload")"
    site_id="$(python3 - "$create_resp" <<'PY'
import json,sys
obj=json.loads(sys.argv[1])
print(obj.get("data",{}).get("siteId",""))
PY
)"
    site_identifier="$(python3 - "$create_resp" <<'PY'
import json,sys
obj=json.loads(sys.argv[1])
print(obj.get("data",{}).get("niceId",""))
PY
)"
    [ -n "$site_id" ] || runbook_fail "site recreate did not return siteId for ${display_name}"
    [ -n "$site_identifier" ] || runbook_fail "site recreate did not return niceId for ${display_name}"
    echo "[OK] Rotated Pangolin site: ${display_name} (site_id=${site_id}, identifier=${site_identifier})"
    created_count=$((created_count + 1))
  fi

  if [ "$created_new" -eq 0 ] && [ "$FORCE_ROTATE" != "1" ]; then
    has_item=1
    if ! op item get "$op_item_title" --vault "$VAULT_ID" </dev/null >/dev/null 2>&1; then
      has_item=0
    fi
    if [ "$has_item" -eq 1 ]; then
      newt_id="$(op item get "$op_item_title" --vault "$VAULT_ID" --fields label=newt_id </dev/null 2>/dev/null || true)"
      if [ -z "$newt_id" ]; then
        newt_id="$(op item get "$op_item_title" --vault "$VAULT_ID" --fields label=id </dev/null 2>/dev/null || true)"
      fi
      newt_secret="$(op item get "$op_item_title" --vault "$VAULT_ID" --reveal --fields label=secret </dev/null 2>/dev/null || true)"
    fi

    if [ -z "${newt_id:-}" ] || [ -z "${newt_secret:-}" ]; then
      if [ "$rebuild_policy" != "rotate" ]; then
        runbook_fail "site exists but OP credentials are missing/incomplete for ${op_item_title} and rebuild_policy=${rebuild_policy}."
      fi
      echo "[WARN] Credentials missing for existing managed site ${display_name}; rotating site per rebuild_policy=rotate."
      runbook_pangolin_api_delete "/site/${site_id}" >/dev/null

      defaults_json="$(runbook_pangolin_api_get "/org/${PANGOLIN_SESSION_ORG_ID}/pick-site-defaults")"
      newt_id="$(python3 - "$defaults_json" <<'PY'
import json,sys
obj=json.loads(sys.argv[1])
print(obj.get("data",{}).get("newtId",""))
PY
)"
      newt_secret="$(python3 - "$defaults_json" <<'PY'
import json,sys
obj=json.loads(sys.argv[1])
print(obj.get("data",{}).get("newtSecret",""))
PY
)"
      client_address="$(python3 - "$defaults_json" <<'PY'
import json,sys
obj=json.loads(sys.argv[1])
print(obj.get("data",{}).get("clientAddress",""))
PY
)"
      [ -n "$newt_id" ] || runbook_fail "missing newtId from defaults for ${display_name}"
      [ -n "$newt_secret" ] || runbook_fail "missing newtSecret from defaults for ${display_name}"
      [ -n "$client_address" ] || runbook_fail "missing clientAddress from defaults for ${display_name}"

      create_payload="$(python3 - "$display_name" "$client_address" "$newt_id" "$newt_secret" <<'PY'
import json,sys
name, address, newt_id, secret = sys.argv[1:5]
print(json.dumps({
  "name": name,
  "type": "newt",
  "address": address,
  "newtId": newt_id,
  "secret": secret
}))
PY
)"
      create_resp="$(runbook_pangolin_api_put_json "/org/${PANGOLIN_SESSION_ORG_ID}/site" "$create_payload")"
      site_id="$(python3 - "$create_resp" <<'PY'
import json,sys
obj=json.loads(sys.argv[1])
print(obj.get("data",{}).get("siteId",""))
PY
)"
      site_identifier="$(python3 - "$create_resp" <<'PY'
import json,sys
obj=json.loads(sys.argv[1])
print(obj.get("data",{}).get("niceId",""))
PY
)"
      [ -n "$site_id" ] || runbook_fail "site recreate did not return siteId for ${display_name}"
      [ -n "$site_identifier" ] || runbook_fail "site recreate did not return niceId for ${display_name}"
      echo "[OK] Rotated Pangolin site: ${display_name} (site_id=${site_id}, identifier=${site_identifier})"
    else
      reused_count=$((reused_count + 1))
    fi
  fi

  safe_endpoint="$(sanitize_single_line "$PANGOLIN_ENDPOINT")"
  safe_name="$(sanitize_single_line "$display_name")"
  safe_identifier="$(sanitize_single_line "$site_identifier")"
  safe_slug="$(sanitize_single_line "$slug")"
  safe_site_id="$(sanitize_single_line "$site_id")"
  safe_newt_id="$(sanitize_single_line "$newt_id")"
  safe_newt_secret="$(sanitize_single_line "$newt_secret")"

  field_args=(
    "endpoint[text]=$safe_endpoint"
    "name[text]=$safe_name"
    "identifier[text]=$safe_identifier"
    "site_slug[text]=$safe_slug"
    "site_id[text]=$safe_site_id"
    "newt_id[text]=$safe_newt_id"
    "secret[concealed]=$safe_newt_secret"
  )

  if op item get "$op_item_title" --vault "$VAULT_ID" </dev/null >/dev/null 2>&1; then
    if ! edit_err="$(op item edit "$op_item_title" --vault "$VAULT_ID" "${field_args[@]}" </dev/null 2>&1 >/dev/null)"; then
      echo "[FAIL] OP edit error for ${op_item_title}:"
      echo "$edit_err"
      runbook_fail "failed to edit OP item ${op_item_title}"
    fi
    echo "[OK] Updated OP item: ${op_item_title}"
    updated_count=$((updated_count + 1))
  else
    if ! create_err="$(op item create --vault "$VAULT_ID" --category "Secure Note" --title "$op_item_title" "${field_args[@]}" </dev/null 2>&1 >/dev/null)"; then
      echo "[FAIL] OP create error for ${op_item_title}:"
      echo "$create_err"
      runbook_fail "failed to create OP item ${op_item_title}"
    fi
    echo "[OK] Created OP item: ${op_item_title}"
    updated_count=$((updated_count + 1))
  fi
done < <(python3 - "$REQUIRED_SITES_JSON" <<'PY'
import json
import sys
records = json.loads(sys.argv[1])
for r in records:
    print("\t".join([
        str(r.get("slug","")),
        str(r.get("display_name","")),
        str(r.get("op_item_title","")),
        str(r.get("managed_mode","managed")),
        str(r.get("rebuild_policy","reuse")),
    ]))
PY
)

echo
echo "[INFO] Reconcile summary:"
echo "       sites_created=${created_count}"
echo "       op_items_written=${updated_count}"
echo "       existing_site_creds_reused=${reused_count}"
echo "[OK] Pangolin site reconcile completed."
