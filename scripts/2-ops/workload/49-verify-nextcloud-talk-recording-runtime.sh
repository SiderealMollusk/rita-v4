#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../lib/runbook.sh"

runbook_require_no_args "$@"
runbook_require_host_terminal
runbook_require_cmd python3
runbook_require_cmd ansible
runbook_require_cmd curl

REPO_ROOT="$(runbook_detect_repo_root)"
runbook_source_labrc "$REPO_ROOT"

BECOME_PASSWORD_OP_REF="${TALK_RECORDING_BECOME_PASSWORD_OP_REF:-}"
BECOME_PASSWORD="${TALK_RECORDING_BECOME_PASSWORD:-}"

CONFIG_FILE="${TALK_RECORDING_RUNTIME_FILE:-$REPO_ROOT/ops/nextcloud/talk-recording-runtime.yaml}"
[ -f "$CONFIG_FILE" ] || runbook_fail "missing talk recording runtime file: $CONFIG_FILE"

PARSED="$(python3 - "$CONFIG_FILE" <<'PY'
import json
import sys

with open(sys.argv[1], 'r', encoding='utf-8') as f:
    data = json.load(f)

recording = data.get('recording') or {}
nextcloud = data.get('nextcloud') or {}

print('RECORDING_INVENTORY=' + str(data.get('inventory_file') or 'ops/ansible/inventory/talk-recording.ini').strip())
print('RECORDING_HOST_ALIAS=' + str(data.get('host_alias') or 'talk-recording-gpu').strip())
print('WELCOME_URL=' + str(recording.get('welcome_url') or 'http://127.0.0.1:1234/api/v1/welcome').strip())
print('PUBLIC_URL=' + str(recording.get('public_url') or '').strip())
print('NEXTCLOUD_INVENTORY=' + str(nextcloud.get('inventory_file') or 'ops/ansible/inventory/nextcloud.ini').strip())
print('NEXTCLOUD_HOST_ALIAS=' + str(nextcloud.get('host_alias') or 'nextcloud-vm').strip())
print('NEXTCLOUD_OCC_PATH=' + str(nextcloud.get('occ_path') or '/var/www/nextcloud/occ').strip())
print('EXPECTED_RECORDING_SERVERS=' + json.dumps(nextcloud.get('recording_servers') or [], separators=(',', ':')))
PY
)"

RECORDING_INVENTORY_REL="$(printf '%s\n' "$PARSED" | sed -n 's/^RECORDING_INVENTORY=//p' | head -n1)"
RECORDING_HOST_ALIAS="$(printf '%s\n' "$PARSED" | sed -n 's/^RECORDING_HOST_ALIAS=//p' | head -n1)"
WELCOME_URL="$(printf '%s\n' "$PARSED" | sed -n 's/^WELCOME_URL=//p' | head -n1)"
PUBLIC_URL="$(printf '%s\n' "$PARSED" | sed -n 's/^PUBLIC_URL=//p' | head -n1)"
NEXTCLOUD_INVENTORY_REL="$(printf '%s\n' "$PARSED" | sed -n 's/^NEXTCLOUD_INVENTORY=//p' | head -n1)"
NEXTCLOUD_HOST_ALIAS="$(printf '%s\n' "$PARSED" | sed -n 's/^NEXTCLOUD_HOST_ALIAS=//p' | head -n1)"
NEXTCLOUD_OCC_PATH="$(printf '%s\n' "$PARSED" | sed -n 's/^NEXTCLOUD_OCC_PATH=//p' | head -n1)"
EXPECTED_RECORDING_SERVERS="$(printf '%s\n' "$PARSED" | sed -n 's/^EXPECTED_RECORDING_SERVERS=//p' | head -n1)"

RECORDING_INVENTORY_PATH="$REPO_ROOT/$RECORDING_INVENTORY_REL"
NEXTCLOUD_INVENTORY_PATH="$REPO_ROOT/$NEXTCLOUD_INVENTORY_REL"
[ -f "$RECORDING_INVENTORY_PATH" ] || runbook_fail "inventory path missing: $RECORDING_INVENTORY_PATH"
[ -f "$NEXTCLOUD_INVENTORY_PATH" ] || runbook_fail "inventory path missing: $NEXTCLOUD_INVENTORY_PATH"

ANSIBLE_EXTRA_ARGS=()
TMP_BECOME_VARS=""
if [ -z "$BECOME_PASSWORD" ] && [ -n "$BECOME_PASSWORD_OP_REF" ]; then
  runbook_require_op_access
  BECOME_PASSWORD="$(runbook_resolve_secret_from_op "" "$BECOME_PASSWORD_OP_REF")"
fi
if [ -n "$BECOME_PASSWORD" ]; then
  TMP_BECOME_VARS="$(mktemp)"
  cat >"$TMP_BECOME_VARS" <<EOF
{"ansible_become_password":"$BECOME_PASSWORD"}
EOF
  ANSIBLE_EXTRA_ARGS+=(-e "@$TMP_BECOME_VARS")
fi

echo "[INFO] Verifying recording runtime host service"
REC_VERIFY_CMD=(ansible -i "$RECORDING_INVENTORY_PATH" "$RECORDING_HOST_ALIAS" -b -m shell -a "set -eu
systemctl is-active --quiet nextcloud-talk-recording.service
curl -fsS '$WELCOME_URL' >/dev/null
")
if [ "${#ANSIBLE_EXTRA_ARGS[@]}" -gt 0 ]; then
  REC_VERIFY_CMD=("${REC_VERIFY_CMD[@]:0:1}" "${ANSIBLE_EXTRA_ARGS[@]}" "${REC_VERIFY_CMD[@]:1}")
fi
"${REC_VERIFY_CMD[@]}"

if [ -n "$PUBLIC_URL" ]; then
  echo "[INFO] Probing recording endpoint from operator host: $PUBLIC_URL/api/v1/welcome"
  HTTP_CODE="$(curl -sS -o /dev/null -w '%{http_code}' "$PUBLIC_URL/api/v1/welcome" || true)"
  [ "$HTTP_CODE" = "200" ] || runbook_fail "public recording welcome probe failed with HTTP $HTTP_CODE"
fi

EXPECTED_RECORDING_SERVERS_B64="$(printf '%s' "$EXPECTED_RECORDING_SERVERS" | base64 | tr -d '\n')"

echo "[INFO] Verifying Nextcloud recording config"
NC_VERIFY_CMD=(ansible -i "$NEXTCLOUD_INVENTORY_PATH" "$NEXTCLOUD_HOST_ALIAS" -b -m shell -a "set -eu
OCC='$NEXTCLOUD_OCC_PATH'
EXPECTED_SERVERS_JSON=\"\$(printf '%s' '$EXPECTED_RECORDING_SERVERS_B64' | base64 -d)\"
RAW=\"\$(sudo -u www-data php \"\$OCC\" config:app:get spreed recording_servers || true)\"
[ -n \"\$RAW\" ] || { echo '[FAIL] spreed recording_servers is empty' >&2; exit 1; }
export EXPECTED_SERVERS_JSON
export RAW
python3 - <<'PY'
import json
import os
import sys

raw = os.environ['RAW']
expected_servers = json.loads(os.environ['EXPECTED_SERVERS_JSON'])

cfg = json.loads(raw)
servers = cfg.get('servers') if isinstance(cfg, dict) else None
secret = cfg.get('secret') if isinstance(cfg, dict) else ''
if not isinstance(servers, list) or not servers:
    raise SystemExit('recording_servers has no servers list')
if not secret:
    raise SystemExit('recording_servers missing secret')
if servers != expected_servers:
    raise SystemExit('recording_servers mismatch with runtime SoT')
PY
")
if [ "${#ANSIBLE_EXTRA_ARGS[@]}" -gt 0 ]; then
  NC_VERIFY_CMD=("${NC_VERIFY_CMD[@]:0:1}" "${ANSIBLE_EXTRA_ARGS[@]}" "${NC_VERIFY_CMD[@]:1}")
fi
"${NC_VERIFY_CMD[@]}"

if [ -n "$TMP_BECOME_VARS" ]; then
  rm -f "$TMP_BECOME_VARS"
fi

echo "[OK] Nextcloud Talk recording runtime verification passed."
