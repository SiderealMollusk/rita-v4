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
runbook_require_cmd op
runbook_source_labrc "$REPO_ROOT"

GROUP_VARS="$REPO_ROOT/ops/ansible/group_vars/observatory.yml"
REQUIRED_SITES_FILE="$REPO_ROOT/ops/pangolin/sites/required-sites.yaml"

[ -f "$GROUP_VARS" ] || runbook_fail "missing group vars file at $GROUP_VARS"
[ -f "$REQUIRED_SITES_FILE" ] || runbook_fail "missing required sites file at $REQUIRED_SITES_FILE"

VAULT_ID="$(runbook_yaml_get "$GROUP_VARS" "pangolin_newt_credentials_vault_id" || true)"
[ -n "$VAULT_ID" ] || runbook_fail "pangolin_newt_credentials_vault_id missing in $GROUP_VARS"

runbook_require_pangolin_session

CONFIRM="${PANGOLIN_TEARDOWN_CONFIRM:-}"
[ "$CONFIRM" = "delete-managed-sites" ] || runbook_fail "refusing teardown. Re-run with: PANGOLIN_TEARDOWN_CONFIRM=delete-managed-sites"

DELETE_OP_ITEMS="${PANGOLIN_TEARDOWN_DELETE_OP_ITEMS:-1}"
case "$DELETE_OP_ITEMS" in
  0|1) ;;
  *) runbook_fail "PANGOLIN_TEARDOWN_DELETE_OP_ITEMS must be 0 or 1" ;;
esac

REQUIRED_SITES_JSON="$(python3 - "$REQUIRED_SITES_FILE" <<'PY'
import json
import sys
with open(sys.argv[1], "r", encoding="utf-8") as f:
    print(json.dumps(json.load(f)))
PY
)"

echo "[INFO] Pangolin API host: ${PANGOLIN_SESSION_HOST}"
echo "[INFO] Pangolin org id: ${PANGOLIN_SESSION_ORG_ID}"
echo "[INFO] Required sites file: ${REQUIRED_SITES_FILE}"
echo "[INFO] OP vault id: ${VAULT_ID}"
if [ "$DELETE_OP_ITEMS" = "1" ]; then
  echo "[INFO] OP items: delete enabled (archive)"
else
  echo "[INFO] OP items: delete disabled"
fi

sites_deleted=0
sites_missing=0
op_items_deleted=0
op_items_missing=0

while IFS=$'\t' read -r slug display_name op_item_title managed_mode; do
  [ -n "$slug" ] || continue
  if [ "$managed_mode" != "managed" ]; then
    echo "[INFO] Skipping non-managed site: ${slug} (${display_name})"
    continue
  fi

  echo
  echo "[INFO] Tearing down site: slug=${slug} name=${display_name}"

  live_sites_json="$(runbook_pangolin_api_get "/org/${PANGOLIN_SESSION_ORG_ID}/sites")"
  site_ids="$(python3 - "$live_sites_json" "$display_name" <<'PY'
import json
import sys
live = json.loads(sys.argv[1])
name = sys.argv[2]
for s in live.get("data", {}).get("sites", []):
    if s.get("name") == name:
        print(str(s.get("siteId", "")))
PY
)"

  if [ -z "$site_ids" ]; then
    echo "[WARN] Pangolin site not found: ${display_name}"
    sites_missing=$((sites_missing + 1))
  else
    while IFS= read -r sid; do
      [ -n "$sid" ] || continue
      runbook_pangolin_api_delete "/site/${sid}" >/dev/null
      echo "[OK] Deleted Pangolin site: ${display_name} (site_id=${sid})"
      sites_deleted=$((sites_deleted + 1))
    done <<< "$site_ids"
  fi

  if [ "$DELETE_OP_ITEMS" = "1" ]; then
    item_id="$(op item get "$op_item_title" --vault "$VAULT_ID" --format json 2>/dev/null | jq -r '.id // empty' || true)"
    if [ -z "$item_id" ]; then
      echo "[WARN] OP item not found: ${op_item_title}"
      op_items_missing=$((op_items_missing + 1))
    else
      op item delete "$item_id" --vault "$VAULT_ID" >/dev/null
      echo "[OK] Deleted OP item: ${op_item_title}"
      op_items_deleted=$((op_items_deleted + 1))
    fi
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
    ]))
PY
)

echo
echo "[INFO] Teardown summary:"
echo "       sites_deleted=${sites_deleted}"
echo "       sites_missing=${sites_missing}"
echo "       op_items_deleted=${op_items_deleted}"
echo "       op_items_missing=${op_items_missing}"
echo "[OK] Pangolin managed site teardown completed."
