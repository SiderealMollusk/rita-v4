#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../lib/runbook.sh"

runbook_require_no_args "$@"
runbook_require_host_terminal
runbook_require_cmd python3
runbook_require_cmd openssl
runbook_require_cmd op

REPO_ROOT="$(runbook_detect_repo_root)"
runbook_source_labrc "$REPO_ROOT"
runbook_require_op_write_access

TALK_RUNTIME_FILE="${TALK_RUNTIME_FILE:-$REPO_ROOT/ops/nextcloud/talk-runtime.yaml}"
TALK_RECORDING_RUNTIME_FILE="${TALK_RECORDING_RUNTIME_FILE:-$REPO_ROOT/ops/nextcloud/talk-recording-runtime.yaml}"

[ -f "$TALK_RUNTIME_FILE" ] || runbook_fail "missing talk runtime file: $TALK_RUNTIME_FILE"
[ -f "$TALK_RECORDING_RUNTIME_FILE" ] || runbook_fail "missing talk recording runtime file: $TALK_RECORDING_RUNTIME_FILE"

# shellcheck disable=SC1090
source <(python3 - "$TALK_RUNTIME_FILE" "$TALK_RECORDING_RUNTIME_FILE" <<'PY'
import json
import sys

def emit(name, value):
    value = (value or '').strip()
    print(f'{name}={value}')

with open(sys.argv[1], 'r', encoding='utf-8') as f:
    talk = json.load(f)
with open(sys.argv[2], 'r', encoding='utf-8') as f:
    rec = json.load(f)

emit('TALK_SIGNALING_SECRET_OP_REF', (((talk.get('talk') or {}).get('signaling') or {}).get('secret_op_ref') or ''))
emit('REC_BACKEND_SECRET_OP_REF', ((((rec.get('recording') or {}).get('backend') or {}).get('secret_op_ref') or '')))
emit('REC_SIGNALING_SECRET_OP_REF', ((((rec.get('recording') or {}).get('signaling') or {}).get('internalsecret_op_ref') or '')))
emit('REC_NEXTCLOUD_SECRET_OP_REF', (((rec.get('nextcloud') or {}).get('recording_secret_op_ref') or '')))
PY
)

[ -n "${TALK_SIGNALING_SECRET_OP_REF:-}" ] || runbook_fail "talk.signaling.secret_op_ref missing in $TALK_RUNTIME_FILE"
[ -n "${REC_BACKEND_SECRET_OP_REF:-}" ] || runbook_fail "recording.backend.secret_op_ref missing in $TALK_RECORDING_RUNTIME_FILE"
[ -n "${REC_SIGNALING_SECRET_OP_REF:-}" ] || runbook_fail "recording.signaling.internalsecret_op_ref missing in $TALK_RECORDING_RUNTIME_FILE"
[ -n "${REC_NEXTCLOUD_SECRET_OP_REF:-}" ] || runbook_fail "nextcloud.recording_secret_op_ref missing in $TALK_RECORDING_RUNTIME_FILE"

parse_op_ref() {
  local ref="$1"
  local _vault_var="$2"
  local _item_var="$3"
  local _field_var="$4"

  [[ "$ref" == op://* ]] || runbook_fail "invalid op ref format: $ref"

  local path="${ref#op://}"
  local vault="${path%%/*}"
  local rest="${path#*/}"
  local item="${rest%%/*}"
  local field="${rest#*/}"

  [ -n "$vault" ] || runbook_fail "invalid op ref vault: $ref"
  [ -n "$item" ] || runbook_fail "invalid op ref item: $ref"
  [ -n "$field" ] || runbook_fail "invalid op ref field: $ref"

  printf -v "$_vault_var" '%s' "$vault"
  printf -v "$_item_var" '%s' "$item"
  printf -v "$_field_var" '%s' "$field"
}

write_op_ref_value() {
  local ref="$1"
  local value="$2"
  local vault item field
  parse_op_ref "$ref" vault item field
  op item edit "$item" --vault "$vault" "$field=$value" >/dev/null
}

NEW_RECORDING_SECRET="$(openssl rand -hex 32)"
NEW_SIGNALING_SECRET="$(openssl rand -hex 32)"

echo "[INFO] Rotating recording shared secret refs in OP"
write_op_ref_value "$REC_BACKEND_SECRET_OP_REF" "$NEW_RECORDING_SECRET"
if [ "$REC_NEXTCLOUD_SECRET_OP_REF" != "$REC_BACKEND_SECRET_OP_REF" ]; then
  write_op_ref_value "$REC_NEXTCLOUD_SECRET_OP_REF" "$NEW_RECORDING_SECRET"
fi

echo "[INFO] Rotating signaling shared secret refs in OP"
write_op_ref_value "$TALK_SIGNALING_SECRET_OP_REF" "$NEW_SIGNALING_SECRET"
if [ "$REC_SIGNALING_SECRET_OP_REF" != "$TALK_SIGNALING_SECRET_OP_REF" ]; then
  write_op_ref_value "$REC_SIGNALING_SECRET_OP_REF" "$NEW_SIGNALING_SECRET"
fi

echo "[INFO] Applying rotated secrets to runtime components"
"$REPO_ROOT/scripts/2-ops/workload/26-configure-nextcloud-talk-runtime.sh"
"$REPO_ROOT/scripts/2-ops/workload/41-install-nextcloud-talk-hpb-runtime.sh"
"$REPO_ROOT/scripts/2-ops/workload/47-install-nextcloud-talk-recording-runtime.sh"
"$REPO_ROOT/scripts/2-ops/workload/48-configure-nextcloud-talk-recording-runtime.sh"

echo "[INFO] Verifying runtime components after rotation"
"$REPO_ROOT/scripts/2-ops/workload/42-verify-nextcloud-talk-hpb-runtime.sh"
"$REPO_ROOT/scripts/2-ops/workload/49-verify-nextcloud-talk-recording-runtime.sh"

echo "[OK] Talk signaling + recording secrets rotated through OP and applied."
