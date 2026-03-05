#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../lib/runbook.sh"

runbook_require_no_args "$@"
runbook_require_host_terminal

REPO_ROOT="$(runbook_detect_repo_root)"
CONFIG_FILE="$REPO_ROOT/ops/nextcloud/talk-runtime.yaml"
LOGIC_SCRIPT="$REPO_ROOT/scripts/2-ops/workload/25-configure-nextcloud-talk-runtime.sh"

[ -f "$CONFIG_FILE" ] || runbook_fail "missing config file: $CONFIG_FILE"
[ -x "$LOGIC_SCRIPT" ] || runbook_fail "missing logic script: $LOGIC_SCRIPT"

runbook_require_cmd python3

OP_REF_COUNT="$(python3 - "$CONFIG_FILE" <<'PY'
import json
import sys
with open(sys.argv[1], "r", encoding="utf-8") as f:
    data = json.load(f)
count = 0
sig_ref = (((data.get("talk") or {}).get("signaling") or {}).get("secret_op_ref") or "").strip()
if sig_ref:
    count += 1
for entry in ((data.get("talk") or {}).get("turn_servers") or []):
    if isinstance(entry, dict) and str(entry.get("secret_op_ref") or "").strip():
        count += 1
print(count)
PY
)"

if [ "${OP_REF_COUNT:-0}" -gt 0 ]; then
  runbook_require_op_access
fi

PARSED="$(python3 - "$CONFIG_FILE" <<'PY'
import json
import sys

path = sys.argv[1]
with open(path, "r", encoding="utf-8") as f:
    data = json.load(f)

inventory_file = data.get("inventory_file", "ops/ansible/inventory/nextcloud.ini")
host_alias = data.get("host_alias", "nextcloud-vm")
occ_path = data.get("occ_path", "/var/www/nextcloud/occ")

notify_push = data.get("notify_push", {})
notify_push_enabled = bool(notify_push.get("enabled", False))
notify_push_endpoint = str(notify_push.get("endpoint", "") or "")

talk = data.get("talk", {})
signaling = talk.get("signaling", {})
signaling_server = str(signaling.get("server", "") or "")
signaling_verify_tls = bool(signaling.get("verify_tls", True))
signaling_secret = str(signaling.get("secret", "") or "")
signaling_secret_op_ref = str(signaling.get("secret_op_ref", "") or "")

stun = [str(x) for x in talk.get("stun_servers", []) if str(x)]
turn = []
for item in talk.get("turn_servers", []):
    if not isinstance(item, dict):
        continue
    schemes = str(item.get("schemes", "") or "")
    server = str(item.get("server", "") or "")
    protocols = str(item.get("protocols", "") or "")
    secret = str(item.get("secret", "") or "")
    secret_op_ref = str(item.get("secret_op_ref", "") or "")
    turn.append((schemes, server, protocols, secret, secret_op_ref))

print("INVENTORY_FILE=" + inventory_file)
print("HOST_ALIAS=" + host_alias)
print("OCC_PATH=" + occ_path)
print("NOTIFY_PUSH_ENABLED=" + ("true" if notify_push_enabled else "false"))
print("NOTIFY_PUSH_ENDPOINT=" + notify_push_endpoint)
print("SIGNALING_SERVER=" + signaling_server)
print("SIGNALING_VERIFY_TLS=" + ("true" if signaling_verify_tls else "false"))
print("SIGNALING_SECRET=" + signaling_secret)
print("SIGNALING_SECRET_OP_REF=" + signaling_secret_op_ref)
for stun_server in stun:
    print("STUN\t" + stun_server)
for schemes, server, protocols, secret, secret_op_ref in turn:
    print("TURN\t" + "\t".join([schemes, server, protocols, secret, secret_op_ref]))
PY
)"

INVENTORY_REL="$(printf '%s\n' "$PARSED" | sed -n 's/^INVENTORY_FILE=//p' | head -n1)"
HOST_ALIAS="$(printf '%s\n' "$PARSED" | sed -n 's/^HOST_ALIAS=//p' | head -n1)"
OCC_PATH="$(printf '%s\n' "$PARSED" | sed -n 's/^OCC_PATH=//p' | head -n1)"
NOTIFY_PUSH_ENABLED="$(printf '%s\n' "$PARSED" | sed -n 's/^NOTIFY_PUSH_ENABLED=//p' | head -n1)"
NOTIFY_PUSH_ENDPOINT="$(printf '%s\n' "$PARSED" | sed -n 's/^NOTIFY_PUSH_ENDPOINT=//p' | head -n1)"
SIGNALING_SERVER="$(printf '%s\n' "$PARSED" | sed -n 's/^SIGNALING_SERVER=//p' | head -n1)"
SIGNALING_VERIFY_TLS="$(printf '%s\n' "$PARSED" | sed -n 's/^SIGNALING_VERIFY_TLS=//p' | head -n1)"
SIGNALING_SECRET="$(printf '%s\n' "$PARSED" | sed -n 's/^SIGNALING_SECRET=//p' | head -n1)"
SIGNALING_SECRET_OP_REF="$(printf '%s\n' "$PARSED" | sed -n 's/^SIGNALING_SECRET_OP_REF=//p' | head -n1)"

INVENTORY_PATH="$REPO_ROOT/$INVENTORY_REL"
[ -f "$INVENTORY_PATH" ] || runbook_fail "inventory path missing: $INVENTORY_PATH"

ARGS=(
  --inventory "$INVENTORY_PATH"
  --host-alias "$HOST_ALIAS"
  --occ-path "$OCC_PATH"
)

if [ "$NOTIFY_PUSH_ENABLED" = "true" ]; then
  ARGS+=(--enable-notify-push)
  [ -n "$NOTIFY_PUSH_ENDPOINT" ] && ARGS+=(--notify-push-endpoint "$NOTIFY_PUSH_ENDPOINT")
fi

if [ -n "$SIGNALING_SERVER" ]; then
  ARGS+=(--signaling-server "$SIGNALING_SERVER")
  if [ "$SIGNALING_VERIFY_TLS" = "true" ]; then
    ARGS+=(--signaling-verify-tls)
  else
    ARGS+=(--signaling-no-verify-tls)
  fi

  if [ -n "$SIGNALING_SECRET" ]; then
    ARGS+=(--signaling-secret "$SIGNALING_SECRET")
  elif [ -n "$SIGNALING_SECRET_OP_REF" ]; then
    SIGNALING_SECRET="$(runbook_resolve_secret_from_op "" "$SIGNALING_SECRET_OP_REF")"
    [ -n "$SIGNALING_SECRET" ] || runbook_fail "unable to resolve signaling secret from OP ref"
    ARGS+=(--signaling-secret "$SIGNALING_SECRET")
  fi
fi

while IFS= read -r line; do
  [ -n "$line" ] || continue
  if [[ "$line" == STUN$'\t'* ]]; then
    stun="${line#STUN$'\t'}"
    [ -n "$stun" ] && ARGS+=(--stun-server "$stun")
  elif [[ "$line" == TURN$'\t'* ]]; then
    rest="${line#TURN$'\t'}"
    IFS=$'\t' read -r schemes server protocols secret secret_op_ref <<<"$rest"
    [ -n "$schemes" ] || continue
    [ -n "$server" ] || continue
    [ -n "$protocols" ] || continue
    if [ -z "$secret" ] && [ -n "$secret_op_ref" ]; then
      secret="$(runbook_resolve_secret_from_op "" "$secret_op_ref")"
    fi
    [ -n "$secret" ] || runbook_fail "turn_servers entry for $server has no secret/secret_op_ref"
    ARGS+=(--turn-server "${schemes}|${server}|${protocols}|${secret}")
  fi
done < <(printf '%s\n' "$PARSED" | tail -n +2)

echo "[INFO] Applying Talk runtime from: $CONFIG_FILE"
"$LOGIC_SCRIPT" "${ARGS[@]}"
