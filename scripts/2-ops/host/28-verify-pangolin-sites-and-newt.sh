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
runbook_require_cmd ansible
runbook_require_cmd python3
runbook_source_labrc "$REPO_ROOT"

REQUIRED_SITES_FILE="$REPO_ROOT/ops/pangolin/sites/required-sites.yaml"
[ -f "$REQUIRED_SITES_FILE" ] || runbook_fail "missing required sites file at $REQUIRED_SITES_FILE"

echo "[INFO] Running Pangolin + OP read-only checks"
"$SCRIPT_DIR/26-pangolin-api-readonly-check.sh"

runbook_require_pangolin_session

REQUIRED_SITES_JSON="$(python3 - "$REQUIRED_SITES_FILE" <<'PY'
import json
import sys
with open(sys.argv[1], "r", encoding="utf-8") as f:
    print(json.dumps(json.load(f)))
PY
)"

live_sites_json="$(runbook_pangolin_api_get "/org/${PANGOLIN_SESSION_ORG_ID}/sites")"
vm_service_failures=0
site_status_warnings=0

while IFS=$'\t' read -r slug display_name host_alias inventory_file connector_mode newt_enabled; do
  [ -n "$slug" ] || continue

  site_online="$(python3 - "$live_sites_json" "$display_name" <<'PY'
import json
import sys
live = json.loads(sys.argv[1])
name = sys.argv[2]
for s in live.get("data", {}).get("sites", []):
    if s.get("name") == name:
        online = s.get("online")
        if online is True:
            print("online")
        elif online is False:
            print("offline")
        else:
            print("unknown")
        break
PY
)"

  if [ -z "$site_online" ] || [ "$site_online" = "unknown" ]; then
    echo "[WARN] Pangolin site online state unknown for ${display_name}"
    site_status_warnings=$((site_status_warnings + 1))
  elif [ "$site_online" = "offline" ]; then
    echo "[WARN] Pangolin site offline: ${display_name}"
    site_status_warnings=$((site_status_warnings + 1))
  else
    echo "[OK] Pangolin site online: ${display_name}"
  fi

  [ "$connector_mode" = "vm" ] || continue
  [ "$newt_enabled" = "True" ] || continue

  inventory_path="$REPO_ROOT/$inventory_file"
  [ -f "$inventory_path" ] || runbook_fail "inventory file missing for ${slug}: $inventory_path"

  if ansible -i "$inventory_path" "$host_alias" -b -m shell -a "systemctl is-active pangolin-newt" | grep -q "active"; then
    echo "[OK] VM Newt service active: ${host_alias}"
  else
    echo "[FAIL] VM Newt service inactive: ${host_alias}"
    vm_service_failures=$((vm_service_failures + 1))
  fi
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
    ]))
PY
)

[ "$vm_service_failures" -eq 0 ] || runbook_fail "VM Newt service verification failed."

if [ "$site_status_warnings" -gt 0 ]; then
  echo "[WARN] Verification passed with ${site_status_warnings} site-status warning(s)."
else
  echo "[OK] Pangolin sites + VM Newt verification passed."
fi
