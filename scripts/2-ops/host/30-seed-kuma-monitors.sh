#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../lib/runbook.sh"

runbook_require_no_args "$@"
runbook_require_host_terminal
runbook_require_op_user_session

runbook_fail "Uptime Kuma monitor seeding is currently disabled. The current script design is busted: it still depends on an SSH-backed local port-forward to reach Kuma's API, and that path is proving unreliable in practice. Do not use this script as-is. Recommended next step: seed monitors manually in Kuma or replace this with a different integration approach."

GROUP_VARS="$REPO_ROOT/ops/ansible/group_vars/observatory.yml"
INV="$REPO_ROOT/ops/ansible/inventory/observatory.ini"
BLUEPRINT_FILE="$REPO_ROOT/ops/pangolin/blueprints/observatory/monitoring.blueprint.yaml"

[ -f "$GROUP_VARS" ] || runbook_fail "missing group vars file at $GROUP_VARS"
[ -f "$INV" ] || runbook_fail "inventory not found: $INV"
[ -f "$BLUEPRINT_FILE" ] || runbook_fail "missing blueprint file at $BLUEPRINT_FILE"

runbook_require_cmd ssh
runbook_require_cmd op
runbook_require_cmd python3

VAULT_ID="$(runbook_yaml_get "$GROUP_VARS" "monitoring_kuma_credentials_vault_id" || true)"
ITEM_TITLE="$(runbook_yaml_get "$GROUP_VARS" "monitoring_kuma_credentials_item" || true)"
KUMA_RELEASE="$(runbook_yaml_get "$GROUP_VARS" "monitoring_kuma_release_name" || true)"
MON_NS="$(runbook_yaml_get "$GROUP_VARS" "monitoring_namespace" || true)"
LOCAL_PORT="$(runbook_yaml_get "$GROUP_VARS" "monitoring_kuma_seed_local_port" || true)"
INTERVAL="$(runbook_yaml_get "$GROUP_VARS" "monitoring_kuma_seed_interval" || true)"
MAX_RETRIES="$(runbook_yaml_get "$GROUP_VARS" "monitoring_kuma_seed_max_retries" || true)"

[ -n "$VAULT_ID" ] || runbook_fail "monitoring_kuma_credentials_vault_id missing in $GROUP_VARS"
[ -n "$ITEM_TITLE" ] || runbook_fail "monitoring_kuma_credentials_item missing in $GROUP_VARS"
[ -n "$KUMA_RELEASE" ] || runbook_fail "monitoring_kuma_release_name missing in $GROUP_VARS"
[ -n "$MON_NS" ] || runbook_fail "monitoring_namespace missing in $GROUP_VARS"
[ -n "$LOCAL_PORT" ] || runbook_fail "monitoring_kuma_seed_local_port missing in $GROUP_VARS"
[ -n "$INTERVAL" ] || runbook_fail "monitoring_kuma_seed_interval missing in $GROUP_VARS"
[ -n "$MAX_RETRIES" ] || runbook_fail "monitoring_kuma_seed_max_retries missing in $GROUP_VARS"

OBSERVATORY_ANSIBLE_USER="$(awk '
  /^\[/ { next }
  $0 !~ /^[[:space:]]*#/ && NF > 0 {
    host=""
    user=""
    for (i=1; i<=NF; i++) {
      if ($i ~ /^ansible_user=/) { split($i, a, "="); user=a[2] }
      if ($i ~ /^ansible_host=/) { split($i, a, "="); host=a[2] }
    }
    if (user != "") { print user; exit }
  }
' "$INV")"
OBSERVATORY_HOST="$(awk '
  /^\[/ { next }
  $0 !~ /^[[:space:]]*#/ && NF > 0 {
    host=""
    for (i=1; i<=NF; i++) {
      if ($i ~ /^ansible_host=/) { split($i, a, "="); host=a[2] }
    }
    if (host != "") { print host; exit }
  }
' "$INV")"

[ -n "$OBSERVATORY_ANSIBLE_USER" ] || runbook_fail "ansible_user missing in $INV"
[ -n "$OBSERVATORY_HOST" ] || runbook_fail "ansible_host missing in $INV"

KUBECONFIG_REMOTE="/home/${OBSERVATORY_ANSIBLE_USER}/.kube/config"
KUMA_SERVICE="observatory-kuma-uptime-kuma"

resolve_local_tunnel_port() {
  if python3 - "$LOCAL_PORT" <<'PY' >/dev/null 2>&1
import socket
import sys
port = int(sys.argv[1])
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
try:
    s.bind(("127.0.0.1", port))
except OSError:
    raise SystemExit(1)
finally:
    s.close()
PY
  then
    printf '%s\n' "$LOCAL_PORT"
    return 0
  fi

  python3 <<'PY'
import socket
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.bind(("127.0.0.1", 0))
print(s.getsockname()[1])
s.close()
PY
}

if op item get "$ITEM_TITLE" --vault "$VAULT_ID" >/dev/null 2>&1; then
  echo "[INFO] Reading Uptime Kuma admin credentials from 1Password item: $ITEM_TITLE"
  KUMA_USERNAME="$(op item get "$ITEM_TITLE" --vault "$VAULT_ID" --fields label=username)"
  KUMA_PASSWORD="$(op item get "$ITEM_TITLE" --vault "$VAULT_ID" --fields label=password --reveal)"
else
  echo "[INFO] 1Password item not found: $ITEM_TITLE"
  read -r -p "Uptime Kuma admin username: " KUMA_USERNAME
  read -r -s -p "Uptime Kuma admin password: " KUMA_PASSWORD
  echo
  [ -n "$KUMA_USERNAME" ] || runbook_fail "Uptime Kuma username is empty"
  [ -n "$KUMA_PASSWORD" ] || runbook_fail "Uptime Kuma password is empty"
  echo "[INFO] Creating 1Password login item: $ITEM_TITLE"
  op item create --vault "$VAULT_ID" --category "Login" --title "$ITEM_TITLE" \
    "website[text]=https://uptime.virgil.info" \
    "username[text]=$KUMA_USERNAME" \
    "password[concealed]=$KUMA_PASSWORD" >/dev/null
fi

[ -n "$KUMA_USERNAME" ] || runbook_fail "Uptime Kuma username is empty"
[ -n "$KUMA_PASSWORD" ] || runbook_fail "Uptime Kuma password is empty"

KUMA_VENV="${HOME}/.local/share/rita-v4/kuma-seed-venv"
if [ ! -x "$KUMA_VENV/bin/python" ]; then
  echo "[INFO] Creating Uptime Kuma seeder virtualenv at $KUMA_VENV"
  python3 -m venv "$KUMA_VENV"
fi

echo "[INFO] Ensuring Python dependencies for Kuma seeding are installed"
"$KUMA_VENV/bin/python" -m pip install --quiet --upgrade pip >/dev/null
"$KUMA_VENV/bin/python" -m pip install --quiet pyyaml uptime-kuma-api >/dev/null

TUNNEL_PORT="$(resolve_local_tunnel_port)"
if [ "$TUNNEL_PORT" != "$LOCAL_PORT" ]; then
  echo "[INFO] Default local Kuma tunnel port ${LOCAL_PORT} is busy; using ${TUNNEL_PORT} instead"
fi

echo "[INFO] Opening temporary SSH-backed Kuma tunnel on 127.0.0.1:${TUNNEL_PORT}"
ssh -o ExitOnForwardFailure=yes -L "${TUNNEL_PORT}:127.0.0.1:${TUNNEL_PORT}" "${OBSERVATORY_ANSIBLE_USER}@${OBSERVATORY_HOST}" \
  "export KUBECONFIG=${KUBECONFIG_REMOTE} && kubectl port-forward -n ${MON_NS} svc/${KUMA_SERVICE} ${TUNNEL_PORT}:80" \
  >/tmp/rita-kuma-seed-tunnel.log 2>&1 &
TUNNEL_PID=$!
cleanup() {
  kill "$TUNNEL_PID" >/dev/null 2>&1 || true
}
trap cleanup EXIT

for _ in $(seq 1 20); do
  if python3 - <<PY >/dev/null 2>&1
import socket
s = socket.socket()
s.settimeout(0.5)
try:
    s.connect(("127.0.0.1", int("${TUNNEL_PORT}")))
except Exception:
    raise SystemExit(1)
finally:
    s.close()
PY
  then
    break
  fi
  sleep 1
done

if ! python3 - <<PY >/dev/null 2>&1
import socket
s = socket.socket()
s.settimeout(0.5)
try:
    s.connect(("127.0.0.1", int("${TUNNEL_PORT}")))
except Exception:
    raise SystemExit(1)
finally:
    s.close()
PY
then
  echo "[INFO] SSH tunnel log:"
  cat /tmp/rita-kuma-seed-tunnel.log || true
  runbook_fail "failed to establish local Kuma tunnel on 127.0.0.1:${TUNNEL_PORT}"
fi

echo "[INFO] Seeding Uptime Kuma monitors from monitoring blueprint"
"$KUMA_VENV/bin/python" - "$BLUEPRINT_FILE" "$TUNNEL_PORT" "$KUMA_USERNAME" "$KUMA_PASSWORD" "$INTERVAL" "$MAX_RETRIES" <<'PY'
import sys
from pathlib import Path

import yaml
from uptime_kuma_api import MonitorType, UptimeKumaApi
from uptime_kuma_api.api import _check_arguments_monitor, _convert_monitor_input

blueprint_file = Path(sys.argv[1])
local_port = int(sys.argv[2])
username = sys.argv[3]
password = sys.argv[4]
interval = int(sys.argv[5])
max_retries = int(sys.argv[6])

doc = yaml.safe_load(blueprint_file.read_text())
resources = doc.get("public-resources", {})

desired = []
for _, resource in resources.items():
    full_domain = resource.get("full-domain")
    protocol = resource.get("protocol")
    name = resource.get("name")
    if not full_domain or not name:
      continue
    if protocol not in {"http", "https"}:
      continue
    # Pangolin public resources are served over HTTPS externally.
    url = f"https://{full_domain}"
    desired.append({"name": name, "url": url})

if not desired:
    raise SystemExit("No public HTTP(S) resources found in blueprint.")

with UptimeKumaApi(f"http://127.0.0.1:{local_port}") as api:
    api.login(username, password)
    existing = {m["name"]: m for m in api.get_monitors()}
    for monitor in desired:
        payload = {
            "type": MonitorType.HTTP,
            "name": monitor["name"],
            "url": monitor["url"],
            "interval": interval,
            "maxretries": max_retries,
            "retryInterval": interval,
            "conditions": [],
        }
        if monitor["name"] in existing:
            monitor_id = existing[monitor["name"]]["id"]
            api.edit_monitor(id_=monitor_id, **payload)
            print(f"[OK] Updated monitor: {monitor['name']} -> {monitor['url']}")
        else:
            request = api._build_monitor_data(**{k: v for k, v in payload.items() if k != "conditions"})
            request["conditions"] = payload["conditions"]
            _convert_monitor_input(request)
            _check_arguments_monitor(request)
            api._call("add", request)
            print(f"[OK] Added monitor: {monitor['name']} -> {monitor['url']}")
PY

echo "[OK] Uptime Kuma monitors seeded from blueprint: $BLUEPRINT_FILE"
echo "[INFO] Canonical source is the Pangolin monitoring blueprint."
