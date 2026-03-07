#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../lib/runbook.sh"

runbook_require_no_args "$@"
runbook_require_host_terminal
runbook_require_cmd ansible
runbook_require_cmd python3

REPO_ROOT="$(runbook_detect_repo_root)"
runbook_source_labrc "$REPO_ROOT"

BECOME_PASSWORD_OP_REF="${TALK_RECORDING_BECOME_PASSWORD_OP_REF:-op://rita-v4/gpu-laptop/password}"
BECOME_PASSWORD="${TALK_RECORDING_BECOME_PASSWORD:-}"

INVENTORY_PATH="${TALK_RECORDING_INVENTORY_PATH:-$REPO_ROOT/ops/ansible/inventory/talk-recording.ini}"
HOST_ALIAS="${TALK_RECORDING_HOST_ALIAS:-talk-recording-gpu}"
[ -f "$INVENTORY_PATH" ] || runbook_fail "inventory path missing: $INVENTORY_PATH"

ANSIBLE_EXTRA_ARGS=()
TMP_BECOME_VARS=""
if [ -z "$BECOME_PASSWORD" ] && [ -n "$BECOME_PASSWORD_OP_REF" ]; then
  runbook_require_op_access
  BECOME_PASSWORD="$(runbook_resolve_secret_from_op "" "$BECOME_PASSWORD_OP_REF")"
fi
if [ -n "$BECOME_PASSWORD" ]; then
  TMP_BECOME_VARS="$(mktemp)"
  cat >"$TMP_BECOME_VARS" <<EOF_JSON
{"ansible_become_password":"$BECOME_PASSWORD"}
EOF_JSON
  ANSIBLE_EXTRA_ARGS+=(-e "@$TMP_BECOME_VARS")
fi

REMOTE_SCRIPT="$(cat <<'EOS'
set -eu
export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y --no-install-recommends prometheus-node-exporter docker-cli

systemctl enable --now prometheus-node-exporter
systemctl enable --now docker

install -d -m 0755 /etc/docker
python3 - <<'PY'
import json
from pathlib import Path

path = Path('/etc/docker/daemon.json')
data = {}
if path.exists():
    try:
        data = json.loads(path.read_text(encoding='utf-8'))
    except Exception:
        data = {}

data['metrics-addr'] = '0.0.0.0:9323'
data['experimental'] = True
path.write_text(json.dumps(data, indent=2, sort_keys=True) + '\n', encoding='utf-8')
PY

systemctl restart docker

docker rm -f cadvisor >/dev/null 2>&1 || true
docker run -d \
  --name cadvisor \
  --restart unless-stopped \
  --privileged \
  --device /dev/kmsg \
  -p 8080:8080 \
  -v /:/rootfs:ro \
  -v /var/run:/var/run:ro \
  -v /sys:/sys:ro \
  -v /var/lib/docker/:/var/lib/docker:ro \
  gcr.io/cadvisor/cadvisor:v0.49.1

for endpoint in \
  http://127.0.0.1:9100/metrics \
  http://127.0.0.1:9323/metrics \
  http://127.0.0.1:8080/metrics
do
  ok=0
  for _ in 1 2 3 4 5 6; do
    if curl -fsS "$endpoint" >/dev/null; then
      ok=1
      break
    fi
    sleep 2
  done
  [ "$ok" -eq 1 ] || { echo "metrics endpoint failed: $endpoint" >&2; exit 1; }
done
EOS
)"

echo "[INFO] Installing GPU host metrics exporters on: $HOST_ALIAS"
RUN_CMD=(ansible -i "$INVENTORY_PATH" "$HOST_ALIAS" -b -m shell -a "$REMOTE_SCRIPT")
if [ "${#ANSIBLE_EXTRA_ARGS[@]}" -gt 0 ]; then
  RUN_CMD=("${RUN_CMD[@]:0:1}" "${ANSIBLE_EXTRA_ARGS[@]}" "${RUN_CMD[@]:1}")
fi
"${RUN_CMD[@]}"

if [ -n "$TMP_BECOME_VARS" ]; then
  rm -f "$TMP_BECOME_VARS"
fi

echo "[OK] GPU metrics exporters configured (node_exporter, docker daemon metrics, cadvisor)."
