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
runbook_require_cmd ansible-playbook
runbook_require_cmd op
runbook_require_cmd python3
runbook_source_labrc "$REPO_ROOT"

GROUP_VARS="$REPO_ROOT/ops/ansible/group_vars/observatory.yml"
REQUIRED_SITES_FILE="$REPO_ROOT/ops/pangolin/sites/required-sites.yaml"
PLAYBOOK="$REPO_ROOT/ops/ansible/playbooks/35-wire-vm-newt-connector.yml"

[ -f "$GROUP_VARS" ] || runbook_fail "missing group vars file at $GROUP_VARS"
[ -f "$REQUIRED_SITES_FILE" ] || runbook_fail "missing required sites file at $REQUIRED_SITES_FILE"
[ -f "$PLAYBOOK" ] || runbook_fail "missing playbook: $PLAYBOOK"

VAULT_ID="$(runbook_yaml_get "$GROUP_VARS" "pangolin_newt_credentials_vault_id" || true)"
[ -n "$VAULT_ID" ] || runbook_fail "pangolin_newt_credentials_vault_id missing in $GROUP_VARS"

runbook_require_pangolin_session

FAST_FAIL_ARGS=()
if [ "${NEWT_FAST_FAIL:-0}" = "1" ]; then
  echo "[INFO] NEWT_FAST_FAIL=1 enabled (wait retries=1, delay=0)"
  FAST_FAIL_ARGS=(-e '{"pangolin_newt_wait_retries":1,"pangolin_newt_wait_delay":0}')
fi

REQUIRED_SITES_JSON="$(python3 - "$REQUIRED_SITES_FILE" <<'PY'
import json
import sys
with open(sys.argv[1], "r", encoding="utf-8") as f:
    print(json.dumps(json.load(f)))
PY
)"

wired_count=0
failed_count=0
while IFS=$'\t' read -r slug display_name host_alias inventory_file connector_mode newt_enabled op_item_title; do
  [ -n "$slug" ] || continue
  [ "$connector_mode" = "vm" ] || continue
  [ "$newt_enabled" = "True" ] || continue

  inventory_path="$REPO_ROOT/$inventory_file"
  [ -f "$inventory_path" ] || runbook_fail "inventory file missing for ${slug}: $inventory_path"

  endpoint="$(op item get "$op_item_title" --vault "$VAULT_ID" --fields label=endpoint 2>/dev/null || true)"
  newt_id="$(op item get "$op_item_title" --vault "$VAULT_ID" --fields label=newt_id 2>/dev/null || true)"
  if [ -z "$newt_id" ]; then
    newt_id="$(op item get "$op_item_title" --vault "$VAULT_ID" --fields label=id 2>/dev/null || true)"
  fi
  newt_secret="$(op item get "$op_item_title" --vault "$VAULT_ID" --reveal --fields label=secret 2>/dev/null || true)"

  [ -n "$endpoint" ] || runbook_fail "${op_item_title} missing field endpoint"
  [ -n "$newt_id" ] || runbook_fail "${op_item_title} missing field newt_id (or legacy id)"
  [ -n "$newt_secret" ] || runbook_fail "${op_item_title} missing field secret"

  echo "[INFO] Wiring Newt connector on VM site ${slug} (${host_alias})"
  tmp_vars="$(mktemp)"
  cat > "$tmp_vars" <<EOF
{
  "pangolin_endpoint": "$endpoint",
  "pangolin_org_id": "${PANGOLIN_SESSION_ORG_ID}",
  "pangolin_newt_id": "$newt_id",
  "pangolin_newt_secret": "$newt_secret"
}
EOF
  if [ "${NEWT_FAST_FAIL:-0}" = "1" ]; then
    ansible_rc=0
    ansible-playbook -i "$inventory_path" "$PLAYBOOK" --limit "$host_alias" -e "@$tmp_vars" "${FAST_FAIL_ARGS[@]}" || ansible_rc=$?
  else
    ansible_rc=0
    ansible-playbook -i "$inventory_path" "$PLAYBOOK" --limit "$host_alias" -e "@$tmp_vars" || ansible_rc=$?
  fi
  if [ "$ansible_rc" -ne 0 ]; then
    echo "[FAIL] Newt wiring failed for ${slug} (${host_alias})"
    failed_count=$((failed_count + 1))
  fi
  rm -f "$tmp_vars"
  wired_count=$((wired_count + 1))
done < <(python3 - "$REQUIRED_SITES_JSON" <<'PY'
import json
import sys
records = json.loads(sys.argv[1])
for r in records:
    print("\t".join([
        str(r.get("slug","")),
        str(r.get("display_name","")),
        str(r.get("host_alias","")),
        str(r.get("inventory_file","")),
        str(r.get("connector_mode","")),
        str(r.get("newt_enabled","")),
        str(r.get("op_item_title","")),
    ]))
PY
)

[ "$wired_count" -gt 0 ] || runbook_fail "No VM Newt connector records were found in required-sites.yaml"
[ "$failed_count" -eq 0 ] || runbook_fail "Wired ${wired_count} VM connector target(s) with ${failed_count} failure(s)."
echo "[OK] Wired ${wired_count} VM Newt connector(s)."
