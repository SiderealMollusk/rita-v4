#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../lib/runbook.sh"

runbook_require_no_args "$@"
runbook_require_host_terminal
runbook_require_cmd python3
runbook_require_cmd ansible

INSTANCES_FILE="$REPO_ROOT/ops/nextcloud/instances.yaml"
CONFIRM_TOKEN="${NEXTCLOUD_LOG_FLUSH_CONFIRM:-}"

[ "$CONFIRM_TOKEN" = "flush-nextcloud-logs" ] || runbook_fail "set NEXTCLOUD_LOG_FLUSH_CONFIRM=flush-nextcloud-logs to proceed"
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

echo "[INFO] Flushing Nextcloud logs on host: $HOST_ALIAS"
echo "[INFO] Files:"
echo "       /var/lib/nextcloud/data/nextcloud.log"
echo "       /var/log/nginx/access.log"
echo "       /var/log/nginx/error.log"

echo "[INFO] Sizes before flush"
ansible -i "$INVENTORY_PATH" "$HOST_ALIAS" -b -m shell -a "set -eu
for f in /var/lib/nextcloud/data/nextcloud.log /var/log/nginx/access.log /var/log/nginx/error.log; do
  if [ -f \"\$f\" ]; then
    stat -c '%n %s bytes' \"\$f\"
  else
    echo \"\$f missing\"
  fi
done
"

echo "[INFO] Truncating files"
ansible -i "$INVENTORY_PATH" "$HOST_ALIAS" -b -m shell -a "set -eu
for f in /var/lib/nextcloud/data/nextcloud.log /var/log/nginx/access.log /var/log/nginx/error.log; do
  [ -f \"\$f\" ] && : > \"\$f\" || true
done
"

echo "[INFO] Sizes after flush"
ansible -i "$INVENTORY_PATH" "$HOST_ALIAS" -b -m shell -a "set -eu
for f in /var/lib/nextcloud/data/nextcloud.log /var/log/nginx/access.log /var/log/nginx/error.log; do
  if [ -f \"\$f\" ]; then
    stat -c '%n %s bytes' \"\$f\"
  else
    echo \"\$f missing\"
  fi
done
"

echo "[OK] Nextcloud log flush complete."
