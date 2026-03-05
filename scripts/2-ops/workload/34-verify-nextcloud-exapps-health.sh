#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../lib/runbook.sh"

runbook_require_no_args "$@"
runbook_require_host_terminal

REPO_ROOT="$(runbook_detect_repo_root)"
INSTANCES_FILE="$REPO_ROOT/ops/nextcloud/instances.yaml"

APPAPI_EXPECTED_DAEMON="${APPAPI_EXPECTED_DAEMON:-harp_local_vm}"
APPAPI_EXPECTED_NC_URL="${APPAPI_EXPECTED_NC_URL:-}"
EXAPP_APP_ID="${EXAPP_APP_ID:-flow}"
EXAPP_LOG_TAIL_LINES="${EXAPP_LOG_TAIL_LINES:-4000}"
EXAPP_ACCESS_TAIL_LINES="${EXAPP_ACCESS_TAIL_LINES:-4000}"
EXAPP_NC_LOG_PATH="${EXAPP_NC_LOG_PATH:-/var/www/nextcloud/data/nextcloud.log}"
EXAPP_NGINX_ACCESS_LOG="${EXAPP_NGINX_ACCESS_LOG:-/var/log/nginx/access.log}"
EXAPP_ALLOWED_CALLER_IPS="${EXAPP_ALLOWED_CALLER_IPS:-}"
EXAPP_REQUIRE_APP_ENABLED="${EXAPP_REQUIRE_APP_ENABLED:-1}"
OCC_PATH="${NEXTCLOUD_OCC_PATH:-/var/www/nextcloud/occ}"

[ -f "$INSTANCES_FILE" ] || runbook_fail "missing instances file: $INSTANCES_FILE"
runbook_require_cmd python3
runbook_require_cmd ansible

instance_row="$(python3 - "$INSTANCES_FILE" <<'PY'
import json, sys
with open(sys.argv[1], "r", encoding="utf-8") as f:
    obj = json.load(f)
official = obj.get("official_instance", "")
inst = (obj.get("instances", {}) or {}).get(official, {}) or {}
print("\t".join([
    str(inst.get("connector_mode", "")),
    str(inst.get("inventory_file", "")),
    str(inst.get("host_alias", "")),
]))
PY
)"

IFS=$'\t' read -r OFFICIAL_MODE INVENTORY_REL HOST_ALIAS <<<"$instance_row"
[ "$OFFICIAL_MODE" = "vm" ] || runbook_fail "official instance is not vm-backed"

INVENTORY_PATH="$REPO_ROOT/$INVENTORY_REL"
[ -f "$INVENTORY_PATH" ] || runbook_fail "inventory path missing: $INVENTORY_PATH"
[ -n "$HOST_ALIAS" ] || runbook_fail "host alias resolved empty"

HOST_ANSIBLE_IP="$(runbook_inventory_get_field "$INVENTORY_PATH" "$HOST_ALIAS" "ansible_host" || true)"
[ -n "$HOST_ANSIBLE_IP" ] || runbook_fail "could not resolve ansible_host for $HOST_ALIAS from $INVENTORY_PATH"

if [ -n "$EXAPP_ALLOWED_CALLER_IPS" ]; then
  ALLOWED_IPS="${HOST_ANSIBLE_IP},127.0.0.1,::1,${EXAPP_ALLOWED_CALLER_IPS}"
else
  ALLOWED_IPS="${HOST_ANSIBLE_IP},127.0.0.1,::1"
fi

occ() {
  local cmd="$1"
  ansible -i "$INVENTORY_PATH" "$HOST_ALIAS" -b -m shell -a "set -eu; sudo -u www-data php '$OCC_PATH' ${cmd}"
}

echo "[INFO] Verifying Nextcloud ExApps health on: $HOST_ALIAS"
echo "[INFO] Expected daemon: $APPAPI_EXPECTED_DAEMON"
echo "[INFO] Expected ExApp app id: $EXAPP_APP_ID"
echo "[INFO] Allowed ExApp caller IPs: $ALLOWED_IPS"
echo "[INFO] Require ExApp enabled: $EXAPP_REQUIRE_APP_ENABLED"

DAEMON_LIST="$(occ "app_api:daemon:list" || true)"
echo "$DAEMON_LIST"
echo "$DAEMON_LIST" | grep -Fq "| ${APPAPI_EXPECTED_DAEMON} " || runbook_fail "expected daemon not registered: ${APPAPI_EXPECTED_DAEMON}"
echo "$DAEMON_LIST" | grep -Eq "^\|[[:space:]]*\*[[:space:]]*\|[[:space:]]*${APPAPI_EXPECTED_DAEMON}[[:space:]]*\|" || runbook_fail "expected daemon is not default: ${APPAPI_EXPECTED_DAEMON}"
if [ -n "$APPAPI_EXPECTED_NC_URL" ]; then
  echo "$DAEMON_LIST" | grep -Fq "$APPAPI_EXPECTED_NC_URL" || runbook_fail "expected daemon NC URL not found: $APPAPI_EXPECTED_NC_URL"
fi

APP_LIST="$(occ "app_api:app:list" || true)"
echo "$APP_LIST"
if [ "$EXAPP_REQUIRE_APP_ENABLED" = "1" ]; then
  echo "$APP_LIST" | grep -Eq "^${EXAPP_APP_ID} .*\[enabled\]" || runbook_fail "ExApp not enabled: ${EXAPP_APP_ID}"
fi

if [ "$EXAPP_REQUIRE_APP_ENABLED" = "1" ]; then
  NC_LOG_TAIL="$(ansible -i "$INVENTORY_PATH" "$HOST_ALIAS" -b -m shell -a "set -eu; [ -f '$EXAPP_NC_LOG_PATH' ] && tail -n $EXAPP_LOG_TAIL_LINES '$EXAPP_NC_LOG_PATH' || true")"
  if printf '%s\n' "$NC_LOG_TAIL" | grep -Eq "Invalid signature for[[:space:]]+ExApp: ${EXAPP_APP_ID}|ExApp ${EXAPP_APP_ID} request to[[:space:]]+NC validation failed"; then
    echo "[INFO] Matching recent AppAPI errors:"
    printf '%s\n' "$NC_LOG_TAIL" | grep -E "Invalid signature for[[:space:]]+ExApp: ${EXAPP_APP_ID}|ExApp ${EXAPP_APP_ID} request to[[:space:]]+NC validation failed" | tail -n 10
    runbook_fail "recent AppAPI signature/validation regression detected."
  fi

  ACCESS_TAIL="$(ansible -i "$INVENTORY_PATH" "$HOST_ALIAS" -b -m shell -a "set -eu; [ -f '$EXAPP_NGINX_ACCESS_LOG' ] && tail -n $EXAPP_ACCESS_TAIL_LINES '$EXAPP_NGINX_ACCESS_LOG' || true")"
  FLOW_STATE_LINES="$(printf '%s\n' "$ACCESS_TAIL" | grep "ExApp/${EXAPP_APP_ID}" | grep '/ocs/v1.php/apps/app_api/ex-app/state' || true)"

  if [ -n "$FLOW_STATE_LINES" ]; then
    BAD_401="$(printf '%s\n' "$FLOW_STATE_LINES" | grep '" 401 ' || true)"
    if [ -n "$BAD_401" ]; then
      echo "[INFO] Recent unauthorized ExApp state calls:"
      printf '%s\n' "$BAD_401" | tail -n 10
      runbook_fail "detected 401 responses for ExApp state endpoint."
    fi

    CALLER_IPS="$(printf '%s\n' "$FLOW_STATE_LINES" | awk '{print $1}' | grep -E '^([0-9]{1,3}\.){3}[0-9]{1,3}$|^::1$' | sort -u || true)"
    while IFS= read -r ip; do
      [ -n "$ip" ] || continue
      case ",$ALLOWED_IPS," in
        *",$ip,"*) ;;
        *)
          echo "[INFO] Recent ExApp state lines:"
          printf '%s\n' "$FLOW_STATE_LINES" | tail -n 10
          runbook_fail "unexpected ExApp caller IP detected: $ip"
          ;;
      esac
    done <<<"$CALLER_IPS"
  fi
else
  echo "[INFO] Skipping app-specific log regression checks (daemon-only mode)."
fi

echo "[OK] Nextcloud ExApps health verification passed."
