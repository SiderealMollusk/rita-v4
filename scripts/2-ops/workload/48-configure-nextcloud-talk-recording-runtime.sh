#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../lib/runbook.sh"

runbook_require_no_args "$@"
runbook_require_host_terminal
runbook_require_cmd python3
runbook_require_cmd ansible

REPO_ROOT="$(runbook_detect_repo_root)"
runbook_source_labrc "$REPO_ROOT"

CONFIG_FILE="${TALK_RECORDING_RUNTIME_FILE:-$REPO_ROOT/ops/nextcloud/talk-recording-runtime.yaml}"
[ -f "$CONFIG_FILE" ] || runbook_fail "missing talk recording runtime file: $CONFIG_FILE"

PARSED="$(python3 - "$CONFIG_FILE" <<'PY'
import json
import sys

with open(sys.argv[1], 'r', encoding='utf-8') as f:
    data = json.load(f)

nextcloud = data.get('nextcloud') or {}
recording_servers = nextcloud.get('recording_servers') or []
recording_secret = str(nextcloud.get('recording_secret') or '').strip()
recording_secret_op_ref = str(nextcloud.get('recording_secret_op_ref') or '').strip()

if not recording_servers:
    raise SystemExit('nextcloud.recording_servers must contain at least one server')

print('NEXTCLOUD_INVENTORY=' + str(nextcloud.get('inventory_file') or 'ops/ansible/inventory/nextcloud.ini').strip())
print('NEXTCLOUD_HOST_ALIAS=' + str(nextcloud.get('host_alias') or 'nextcloud-vm').strip())
print('NEXTCLOUD_OCC_PATH=' + str(nextcloud.get('occ_path') or '/var/www/nextcloud/occ').strip())
print('CALL_RECORDING=' + str(nextcloud.get('call_recording') or 'yes').strip())
print('RECORDING_SECRET=' + recording_secret)
print('RECORDING_SECRET_OP_REF=' + recording_secret_op_ref)
print('RECORDING_SERVERS_JSON=' + json.dumps(recording_servers, separators=(',', ':')))
PY
)"

NEXTCLOUD_INVENTORY_REL="$(printf '%s\n' "$PARSED" | sed -n 's/^NEXTCLOUD_INVENTORY=//p' | head -n1)"
NEXTCLOUD_HOST_ALIAS="$(printf '%s\n' "$PARSED" | sed -n 's/^NEXTCLOUD_HOST_ALIAS=//p' | head -n1)"
NEXTCLOUD_OCC_PATH="$(printf '%s\n' "$PARSED" | sed -n 's/^NEXTCLOUD_OCC_PATH=//p' | head -n1)"
CALL_RECORDING="$(printf '%s\n' "$PARSED" | sed -n 's/^CALL_RECORDING=//p' | head -n1)"
RECORDING_SECRET="$(printf '%s\n' "$PARSED" | sed -n 's/^RECORDING_SECRET=//p' | head -n1)"
RECORDING_SECRET_OP_REF="$(printf '%s\n' "$PARSED" | sed -n 's/^RECORDING_SECRET_OP_REF=//p' | head -n1)"
RECORDING_SERVERS_JSON="$(printf '%s\n' "$PARSED" | sed -n 's/^RECORDING_SERVERS_JSON=//p' | head -n1)"

NEXTCLOUD_INVENTORY_PATH="$REPO_ROOT/$NEXTCLOUD_INVENTORY_REL"
[ -f "$NEXTCLOUD_INVENTORY_PATH" ] || runbook_fail "inventory path missing: $NEXTCLOUD_INVENTORY_PATH"

if [ -z "$RECORDING_SECRET" ] && [ -n "$RECORDING_SECRET_OP_REF" ]; then
  runbook_require_op_access
  RECORDING_SECRET="$(runbook_resolve_secret_from_op "" "$RECORDING_SECRET_OP_REF")"
fi
[ -n "$RECORDING_SECRET" ] || runbook_fail "recording secret missing (nextcloud.recording_secret or nextcloud.recording_secret_op_ref)"

RECORDING_SERVERS_B64="$(printf '%s' "$RECORDING_SERVERS_JSON" | base64 | tr -d '\n')"
RECORDING_SECRET_B64="$(printf '%s' "$RECORDING_SECRET" | base64 | tr -d '\n')"

ansible -i "$NEXTCLOUD_INVENTORY_PATH" "$NEXTCLOUD_HOST_ALIAS" -b -m shell -a "set -eu
OCC='$NEXTCLOUD_OCC_PATH'
CALL_RECORDING='$CALL_RECORDING'
RECORDING_SERVERS_JSON=\"\$(printf '%s' '$RECORDING_SERVERS_B64' | base64 -d)\"
RECORDING_SECRET=\"\$(printf '%s' '$RECORDING_SECRET_B64' | base64 -d)\"
export RECORDING_SERVERS_JSON
export RECORDING_SECRET

run_occ() {
  sudo -u www-data php \"\$OCC\" \"\$@\"
}

RECORDING_VALUE=\"\$(python3 - <<'PY'
import json
import os

servers = json.loads(os.environ['RECORDING_SERVERS_JSON'])
secret = os.environ['RECORDING_SECRET']
print(json.dumps({'servers': servers, 'secret': secret}, separators=(',', ':')))
PY
)\"

run_occ config:app:set spreed recording_servers --value=\"\$RECORDING_VALUE\"
run_occ config:app:set spreed call_recording --value=\"\$CALL_RECORDING\"
"

echo "[OK] Nextcloud Talk recording backend config applied."
