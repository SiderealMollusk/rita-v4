#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../lib/runbook.sh"

runbook_require_host_terminal
runbook_require_cmd python3
runbook_require_cmd ansible

INSTANCES_FILE="$REPO_ROOT/ops/nextcloud/instances.yaml"
OCC_PATH="${NEXTCLOUD_OCC_PATH:-/var/www/nextcloud/occ}"
LOOKBACK_MINUTES="${LOOKBACK_MINUTES:-120}"
TAIL_LINES="${TAIL_LINES:-20000}"
IP_ADDRESS="${1:-${NEXTCLOUD_THROTTLE_IP:-}}"

usage() {
  cat <<'EOF'
Usage:
  44-clear-nextcloud-throttle-and-show-source.sh <ip-address>

Env:
  NEXTCLOUD_THROTTLE_IP    Default IP if argument is omitted.
  LOOKBACK_MINUTES         Log lookback window in minutes (default: 120).
  TAIL_LINES               Raw log tail line count before filtering (default: 20000).
EOF
}

if [ "${IP_ADDRESS}" = "--help" ] || [ "${IP_ADDRESS}" = "-h" ]; then
  usage
  exit 0
fi

[ -n "$IP_ADDRESS" ] || {
  usage
  runbook_fail "missing ip-address argument"
}

[ -f "$INSTANCES_FILE" ] || runbook_fail "missing nextcloud instances file: $INSTANCES_FILE"

instance_row="$(
python3 - "$INSTANCES_FILE" <<'PY'
import json
import sys
path = sys.argv[1]
with open(path, "r", encoding="utf-8") as f:
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

IFS=$'\t' read -r OFFICIAL_MODE OFFICIAL_INV_REL OFFICIAL_HOST_ALIAS <<<"$instance_row"
[ "$OFFICIAL_MODE" = "vm" ] || runbook_fail "official instance is not vm-backed in $INSTANCES_FILE"

INVENTORY_PATH="$REPO_ROOT/$OFFICIAL_INV_REL"
HOST_ALIAS="$OFFICIAL_HOST_ALIAS"
[ -f "$INVENTORY_PATH" ] || runbook_fail "inventory file not found: $INVENTORY_PATH"
[ -n "$HOST_ALIAS" ] || runbook_fail "host alias resolved empty"

ip_b64="$(printf '%s' "$IP_ADDRESS" | base64 | tr -d '\n')"
lookback_b64="$(printf '%s' "$LOOKBACK_MINUTES" | base64 | tr -d '\n')"
tail_lines_b64="$(printf '%s' "$TAIL_LINES" | base64 | tr -d '\n')"

echo "[INFO] Target host: $HOST_ALIAS"
echo "[INFO] Target IP: $IP_ADDRESS"
echo "[INFO] Lookback minutes: $LOOKBACK_MINUTES"

echo "[INFO] Brute-force status before reset"
ansible -i "$INVENTORY_PATH" "$HOST_ALIAS" -b -m shell -a "set -eu
IP_ADDRESS=\"\$(printf '%s' '$ip_b64' | base64 -d)\"
sudo -u www-data php '$OCC_PATH' security:bruteforce:attempts \"\$IP_ADDRESS\"
"

echo "[INFO] Resetting brute-force state"
ansible -i "$INVENTORY_PATH" "$HOST_ALIAS" -b -m shell -a "set -eu
IP_ADDRESS=\"\$(printf '%s' '$ip_b64' | base64 -d)\"
sudo -u www-data php '$OCC_PATH' security:bruteforce:reset \"\$IP_ADDRESS\"
"

echo "[INFO] Brute-force status after reset"
ansible -i "$INVENTORY_PATH" "$HOST_ALIAS" -b -m shell -a "set -eu
IP_ADDRESS=\"\$(printf '%s' '$ip_b64' | base64 -d)\"
sudo -u www-data php '$OCC_PATH' security:bruteforce:attempts \"\$IP_ADDRESS\"
"

echo "[INFO] Recent likely source lines (Nextcloud log)"
ansible -i "$INVENTORY_PATH" "$HOST_ALIAS" -b -m shell -a "set -eu
IP_ADDRESS=\"\$(printf '%s' '$ip_b64' | base64 -d)\"
LOOKBACK_MINUTES=\"\$(printf '%s' '$lookback_b64' | base64 -d)\"
TAIL_LINES=\"\$(printf '%s' '$tail_lines_b64' | base64 -d)\"
sudo python3 - \"\$IP_ADDRESS\" \"\$LOOKBACK_MINUTES\" \"\$TAIL_LINES\" <<'PY'
import sys
import datetime
import json

ip = sys.argv[1]
lookback = int(sys.argv[2])
tail_lines = int(sys.argv[3])
path = '/var/lib/nextcloud/data/nextcloud.log'

try:
    with open(path, 'r', encoding='utf-8', errors='ignore') as f:
        lines = f.readlines()[-tail_lines:]
except FileNotFoundError:
    print('[WARN] nextcloud.log not found:', path)
    raise SystemExit(0)

cutoff = datetime.datetime.now(datetime.timezone.utc) - datetime.timedelta(minutes=lookback)
hits = []
for line in lines:
    line = line.strip()
    if not line:
        continue
    try:
        obj = json.loads(line)
    except Exception:
        continue
    if obj.get('remoteAddr') != ip:
        continue
    t = obj.get('time')
    try:
        dt = datetime.datetime.fromisoformat(t)
    except Exception:
        continue
    if dt < cutoff:
        continue
    msg = obj.get('message', '')
    app = obj.get('app', '')
    ua = obj.get('userAgent', '')
    if ('Login failed' in msg) or (app == 'app_api'):
        hits.append((t, app, obj.get('user', '--'), obj.get('method', ''), obj.get('url', ''), ua, msg))

if not hits:
    print('[INFO] No matching login-failed/app_api lines in lookback window.')
else:
    for t, app, user, method, url, ua, msg in hits[-30:]:
        print(f'{t} app={app} user={user} method={method} url={url} ua={ua} msg={msg}')
PY
"

echo "[OK] Throttle reset + source trace complete."
