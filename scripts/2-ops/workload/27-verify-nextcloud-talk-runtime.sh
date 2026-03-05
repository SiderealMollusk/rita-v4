#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../lib/runbook.sh"

runbook_require_no_args "$@"
runbook_require_host_terminal

REPO_ROOT="$(runbook_detect_repo_root)"
CONFIG_FILE="$REPO_ROOT/ops/nextcloud/talk-runtime.yaml"

[ -f "$CONFIG_FILE" ] || runbook_fail "missing config file: $CONFIG_FILE"
runbook_require_cmd python3
runbook_require_cmd ansible

PARSED="$(python3 - "$CONFIG_FILE" <<'PY'
import json
import sys

with open(sys.argv[1], "r", encoding="utf-8") as f:
    data = json.load(f)

inventory_file = data.get("inventory_file", "ops/ansible/inventory/nextcloud.ini")
host_alias = data.get("host_alias", "nextcloud-vm")
occ_path = data.get("occ_path", "/var/www/nextcloud/occ")
notify_push_enabled = bool(data.get("notify_push", {}).get("enabled", False))

talk = data.get("talk", {})
signaling_server = str(talk.get("signaling", {}).get("server", "") or "")
stun_servers = [str(x) for x in talk.get("stun_servers", []) if str(x)]
turn_servers = [str((x or {}).get("server", "") or "") for x in talk.get("turn_servers", []) if isinstance(x, dict)]
turn_servers = [x for x in turn_servers if x]

print("\t".join([
    inventory_file,
    host_alias,
    occ_path,
    "true" if notify_push_enabled else "false",
    signaling_server,
]))
for stun in stun_servers:
    print("STUN\t" + stun)
for turn in turn_servers:
    print("TURN\t" + turn)
PY
)"

IFS=$'\n' read -r HEADER_LINE <<<"$PARSED"
IFS=$'\t' read -r INVENTORY_REL HOST_ALIAS OCC_PATH NOTIFY_PUSH_ENABLED SIGNALING_SERVER <<<"$HEADER_LINE"
INVENTORY_PATH="$REPO_ROOT/$INVENTORY_REL"
[ -f "$INVENTORY_PATH" ] || runbook_fail "inventory path missing: $INVENTORY_PATH"

declare -a EXPECTED_STUN=()
declare -a EXPECTED_TURN=()
while IFS= read -r line; do
  [ -n "$line" ] || continue
  if [[ "$line" == STUN$'\t'* ]]; then
    EXPECTED_STUN+=("${line#STUN$'\t'}")
  elif [[ "$line" == TURN$'\t'* ]]; then
    EXPECTED_TURN+=("${line#TURN$'\t'}")
  fi
done < <(printf '%s\n' "$PARSED" | tail -n +2)

echo "[INFO] Verifying Nextcloud Talk runtime on: $HOST_ALIAS"

APP_LIST="$(ansible -i "$INVENTORY_PATH" "$HOST_ALIAS" -b -m shell -a "sudo -u www-data php '$OCC_PATH' app:list")"
SIGNALING_LIST="$(ansible -i "$INVENTORY_PATH" "$HOST_ALIAS" -b -m shell -a "sudo -u www-data php '$OCC_PATH' talk:signaling:list")"
STUN_LIST="$(ansible -i "$INVENTORY_PATH" "$HOST_ALIAS" -b -m shell -a "sudo -u www-data php '$OCC_PATH' talk:stun:list")"
TURN_LIST="$(ansible -i "$INVENTORY_PATH" "$HOST_ALIAS" -b -m shell -a "sudo -u www-data php '$OCC_PATH' talk:turn:list")"

if [ "$NOTIFY_PUSH_ENABLED" = "true" ]; then
  echo "$APP_LIST" | grep -q "notify_push" || runbook_fail "notify_push expected enabled but not present in app:list"
fi

if [ -n "$SIGNALING_SERVER" ]; then
  echo "$SIGNALING_LIST" | grep -Fq "$SIGNALING_SERVER" || runbook_fail "signaling server not found: $SIGNALING_SERVER"
fi

for stun in "${EXPECTED_STUN[@]-}"; do
  echo "$STUN_LIST" | grep -Fq "$stun" || runbook_fail "STUN server not found: $stun"
done

for turn in "${EXPECTED_TURN[@]-}"; do
  echo "$TURN_LIST" | grep -Fq "$turn" || runbook_fail "TURN server not found: $turn"
done

echo "[OK] Nextcloud Talk runtime verification passed."
