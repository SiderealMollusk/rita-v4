#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../lib/runbook.sh"

runbook_require_no_args "$@"
runbook_require_cmd ansible
runbook_require_cmd curl

REPO_ROOT="$(runbook_detect_repo_root)"

INVENTORY_PATH="${INVENTORY_PATH:-$REPO_ROOT/ops/ansible/inventory/talk-hpb.ini}"
HOST_ALIAS="${HOST_ALIAS:-talk-hpb-vm}"
PUBLIC_SIGNALING_URL="${PUBLIC_SIGNALING_URL:-https://cloud.virgil.info/standalone-signaling/api/v1/welcome}"

[ -f "$INVENTORY_PATH" ] || runbook_fail "missing inventory file: $INVENTORY_PATH"

echo "[INFO] Verifying Talk HPB runtime on: $HOST_ALIAS"
echo "[INFO] Inventory: $INVENTORY_PATH"

ansible -i "$INVENTORY_PATH" "$HOST_ALIAS" -b -m shell -a "set -eu
systemctl is-active --quiet nextcloud-spreed-signaling.service
systemctl is-active --quiet janus.service
systemctl is-active --quiet nats-server.service
ss -ltnp | grep -q ':8080'
ss -ltnp | grep -q ':4222'
grep -Eq '^[[:space:]]*full_trickle[[:space:]]*=[[:space:]]*true' /etc/janus/janus.jcfg
grep -Eq '^[[:space:]]*broadcast[[:space:]]*=[[:space:]]*true' /etc/janus/janus.jcfg
! journalctl -u nextcloud-spreed-signaling.service --since '-10 min' --no-pager | grep -Fq 'Plugin janus.eventhandler.wsevh not found'
! journalctl -u nextcloud-spreed-signaling.service --since '-10 min' --no-pager | grep -Fq 'Full-Trickle is NOT enabled in Janus'
curl -fsS http://127.0.0.1:8080/api/v1/welcome
"

echo "[INFO] Verifying public signaling endpoint: $PUBLIC_SIGNALING_URL"
HTTP_CODE="$(curl -sS -o /dev/null -w '%{http_code}' "$PUBLIC_SIGNALING_URL")"
[ "$HTTP_CODE" = "200" ] || runbook_fail "public signaling endpoint returned HTTP ${HTTP_CODE}"

echo "[INFO] Verifying Nextcloud runtime wiring"
"$REPO_ROOT/scripts/2-ops/workload/27-verify-nextcloud-talk-runtime.sh"

echo "[OK] Nextcloud Talk HPB runtime verification passed."
