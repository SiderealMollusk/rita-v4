#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../lib/runbook.sh"

runbook_require_no_args "$@"
runbook_require_host_terminal
runbook_require_cmd python3
runbook_require_cmd ansible

REPO_ROOT="$(runbook_detect_repo_root)"
runbook_source_labrc "$REPO_ROOT"

BECOME_PASSWORD_OP_REF="${TALK_RECORDING_BECOME_PASSWORD_OP_REF:-op://rita-v4/gpu-laptop/password}"
BECOME_PASSWORD="${TALK_RECORDING_BECOME_PASSWORD:-}"

CONFIG_FILE="${TALK_RECORDING_RUNTIME_FILE:-$REPO_ROOT/ops/nextcloud/talk-recording-runtime.yaml}"
[ -f "$CONFIG_FILE" ] || runbook_fail "missing talk recording runtime file: $CONFIG_FILE"

PARSED="$(python3 - "$CONFIG_FILE" <<'PY'
import json
import sys

with open(sys.argv[1], 'r', encoding='utf-8') as f:
    data = json.load(f)

inventory_file = str(data.get('inventory_file') or '').strip()
host_alias = str(data.get('host_alias') or '').strip()
recording = data.get('recording') or {}
backend = recording.get('backend') or {}
signaling = recording.get('signaling') or {}
storage = recording.get('storage') or {}
runtime = recording.get('runtime') or {}
stats_allowed_ips = recording.get('stats_allowed_ips') or []

listen = str(recording.get('listen') or '0.0.0.0:1234').strip()
welcome_url = str(recording.get('welcome_url') or 'http://127.0.0.1:1234/api/v1/welcome').strip()
backend_id = str(backend.get('id') or 'cloud-main').strip()
backend_url = str(backend.get('url') or '').strip()
backend_secret = str(backend.get('secret') or '').strip()
backend_secret_op_ref = str(backend.get('secret_op_ref') or '').strip()
backend_skip_verify = bool(backend.get('skip_verify', False))
signaling_id = str(signaling.get('id') or 'cloud-signaling').strip()
signaling_url = str(signaling.get('url') or '').strip()
signaling_secret = str(signaling.get('internalsecret') or '').strip()
signaling_secret_op_ref = str(signaling.get('internalsecret_op_ref') or '').strip()
directory = str(storage.get('directory') or '/var/lib/nextcloud-talk-recording/data').strip()
container_name = str(runtime.get('container_name') or 'nextcloud-talk-recording').strip()
image = str(runtime.get('image') or 'nextcloud-talk-recording:local').strip()
source_repo = str(runtime.get('source_repo') or 'https://github.com/nextcloud/nextcloud-talk-recording').strip()
source_ref = str(runtime.get('source_ref') or 'main').strip()
stats_allowed_ips_csv = ', '.join(str(i).strip() for i in stats_allowed_ips if str(i).strip())

if not inventory_file:
    raise SystemExit('missing inventory_file')
if not host_alias:
    raise SystemExit('missing host_alias')
if not backend_url:
    raise SystemExit('missing recording.backend.url')
if not signaling_url:
    raise SystemExit('missing recording.signaling.url')
if not container_name:
    raise SystemExit('missing recording.runtime.container_name')
if not image:
    raise SystemExit('missing recording.runtime.image')
if not source_repo:
    raise SystemExit('missing recording.runtime.source_repo')
if not source_ref:
    raise SystemExit('missing recording.runtime.source_ref')

print('INVENTORY_FILE=' + inventory_file)
print('HOST_ALIAS=' + host_alias)
print('LISTEN=' + listen)
print('WELCOME_URL=' + welcome_url)
print('BACKEND_ID=' + backend_id)
print('BACKEND_URL=' + backend_url)
print('BACKEND_SECRET=' + backend_secret)
print('BACKEND_SECRET_OP_REF=' + backend_secret_op_ref)
print('BACKEND_SKIP_VERIFY=' + ('true' if backend_skip_verify else 'false'))
print('SIGNALING_ID=' + signaling_id)
print('SIGNALING_URL=' + signaling_url)
print('SIGNALING_SECRET=' + signaling_secret)
print('SIGNALING_SECRET_OP_REF=' + signaling_secret_op_ref)
print('RECORDING_DIRECTORY=' + directory)
print('CONTAINER_NAME=' + container_name)
print('RUNTIME_IMAGE=' + image)
print('SOURCE_REPO=' + source_repo)
print('SOURCE_REF=' + source_ref)
print('STATS_ALLOWED_IPS=' + stats_allowed_ips_csv)
PY
)"

INVENTORY_REL="$(printf '%s\n' "$PARSED" | sed -n 's/^INVENTORY_FILE=//p' | head -n1)"
HOST_ALIAS="$(printf '%s\n' "$PARSED" | sed -n 's/^HOST_ALIAS=//p' | head -n1)"
LISTEN="$(printf '%s\n' "$PARSED" | sed -n 's/^LISTEN=//p' | head -n1)"
WELCOME_URL="$(printf '%s\n' "$PARSED" | sed -n 's/^WELCOME_URL=//p' | head -n1)"
BACKEND_ID="$(printf '%s\n' "$PARSED" | sed -n 's/^BACKEND_ID=//p' | head -n1)"
BACKEND_URL="$(printf '%s\n' "$PARSED" | sed -n 's/^BACKEND_URL=//p' | head -n1)"
BACKEND_SECRET="$(printf '%s\n' "$PARSED" | sed -n 's/^BACKEND_SECRET=//p' | head -n1)"
BACKEND_SECRET_OP_REF="$(printf '%s\n' "$PARSED" | sed -n 's/^BACKEND_SECRET_OP_REF=//p' | head -n1)"
BACKEND_SKIP_VERIFY="$(printf '%s\n' "$PARSED" | sed -n 's/^BACKEND_SKIP_VERIFY=//p' | head -n1)"
SIGNALING_ID="$(printf '%s\n' "$PARSED" | sed -n 's/^SIGNALING_ID=//p' | head -n1)"
SIGNALING_URL="$(printf '%s\n' "$PARSED" | sed -n 's/^SIGNALING_URL=//p' | head -n1)"
SIGNALING_SECRET="$(printf '%s\n' "$PARSED" | sed -n 's/^SIGNALING_SECRET=//p' | head -n1)"
SIGNALING_SECRET_OP_REF="$(printf '%s\n' "$PARSED" | sed -n 's/^SIGNALING_SECRET_OP_REF=//p' | head -n1)"
RECORDING_DIRECTORY="$(printf '%s\n' "$PARSED" | sed -n 's/^RECORDING_DIRECTORY=//p' | head -n1)"
CONTAINER_NAME="$(printf '%s\n' "$PARSED" | sed -n 's/^CONTAINER_NAME=//p' | head -n1)"
RUNTIME_IMAGE="$(printf '%s\n' "$PARSED" | sed -n 's/^RUNTIME_IMAGE=//p' | head -n1)"
SOURCE_REPO="$(printf '%s\n' "$PARSED" | sed -n 's/^SOURCE_REPO=//p' | head -n1)"
SOURCE_REF="$(printf '%s\n' "$PARSED" | sed -n 's/^SOURCE_REF=//p' | head -n1)"
STATS_ALLOWED_IPS="$(printf '%s\n' "$PARSED" | sed -n 's/^STATS_ALLOWED_IPS=//p' | head -n1)"

INVENTORY_PATH="$REPO_ROOT/$INVENTORY_REL"
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

if [ -z "$BACKEND_SECRET" ] && [ -n "$BACKEND_SECRET_OP_REF" ]; then
  runbook_require_op_access
  BACKEND_SECRET="$(runbook_resolve_secret_from_op "" "$BACKEND_SECRET_OP_REF")"
fi
[ -n "$BACKEND_SECRET" ] || runbook_fail "recording backend secret missing (recording.backend.secret or secret_op_ref)"

if [ -z "$SIGNALING_SECRET" ] && [ -n "$SIGNALING_SECRET_OP_REF" ]; then
  runbook_require_op_access
  SIGNALING_SECRET="$(runbook_resolve_secret_from_op "" "$SIGNALING_SECRET_OP_REF")"
fi
[ -n "$SIGNALING_SECRET" ] || runbook_fail "recording signaling internalsecret missing (recording.signaling.internalsecret or internalsecret_op_ref)"

LISTEN_B64="$(printf '%s' "$LISTEN" | base64 | tr -d '\n')"
BACKEND_ID_B64="$(printf '%s' "$BACKEND_ID" | base64 | tr -d '\n')"
BACKEND_URL_B64="$(printf '%s' "$BACKEND_URL" | base64 | tr -d '\n')"
BACKEND_SECRET_B64="$(printf '%s' "$BACKEND_SECRET" | base64 | tr -d '\n')"
BACKEND_SKIP_VERIFY_B64="$(printf '%s' "$BACKEND_SKIP_VERIFY" | base64 | tr -d '\n')"
SIGNALING_ID_B64="$(printf '%s' "$SIGNALING_ID" | base64 | tr -d '\n')"
SIGNALING_URL_B64="$(printf '%s' "$SIGNALING_URL" | base64 | tr -d '\n')"
SIGNALING_SECRET_B64="$(printf '%s' "$SIGNALING_SECRET" | base64 | tr -d '\n')"
RECORDING_DIR_B64="$(printf '%s' "$RECORDING_DIRECTORY" | base64 | tr -d '\n')"
CONTAINER_NAME_B64="$(printf '%s' "$CONTAINER_NAME" | base64 | tr -d '\n')"
RUNTIME_IMAGE_B64="$(printf '%s' "$RUNTIME_IMAGE" | base64 | tr -d '\n')"
SOURCE_REPO_B64="$(printf '%s' "$SOURCE_REPO" | base64 | tr -d '\n')"
SOURCE_REF_B64="$(printf '%s' "$SOURCE_REF" | base64 | tr -d '\n')"
STATS_ALLOWED_IPS_B64="$(printf '%s' "$STATS_ALLOWED_IPS" | base64 | tr -d '\n')"

REMOTE_SCRIPT="$(cat <<'EOS'
set -eu
export DEBIAN_FRONTEND=noninteractive

LISTEN="$(printf '%s' '__LISTEN_B64__' | base64 -d)"
BACKEND_ID="$(printf '%s' '__BACKEND_ID_B64__' | base64 -d)"
BACKEND_URL="$(printf '%s' '__BACKEND_URL_B64__' | base64 -d)"
BACKEND_SECRET="$(printf '%s' '__BACKEND_SECRET_B64__' | base64 -d)"
BACKEND_SKIP_VERIFY="$(printf '%s' '__BACKEND_SKIP_VERIFY_B64__' | base64 -d)"
SIGNALING_ID="$(printf '%s' '__SIGNALING_ID_B64__' | base64 -d)"
SIGNALING_URL="$(printf '%s' '__SIGNALING_URL_B64__' | base64 -d)"
SIGNALING_SECRET="$(printf '%s' '__SIGNALING_SECRET_B64__' | base64 -d)"
RECORDING_DIRECTORY="$(printf '%s' '__RECORDING_DIR_B64__' | base64 -d)"
CONTAINER_NAME="$(printf '%s' '__CONTAINER_NAME_B64__' | base64 -d)"
RUNTIME_IMAGE="$(printf '%s' '__RUNTIME_IMAGE_B64__' | base64 -d)"
SOURCE_REPO="$(printf '%s' '__SOURCE_REPO_B64__' | base64 -d)"
SOURCE_REF="$(printf '%s' '__SOURCE_REF_B64__' | base64 -d)"
STATS_ALLOWED_IPS="$(printf '%s' '__STATS_ALLOWED_IPS_B64__' | base64 -d)"

apt-get update -y
apt-get install -y --no-install-recommends git

command -v docker >/dev/null 2>&1 || {
  echo "docker command not found; run 51-install-talk-recording-docker-engine.sh first" >&2
  exit 1
}
systemctl is-active --quiet docker || {
  echo "docker service is not active; run 51-install-talk-recording-docker-engine.sh first" >&2
  exit 1
}

# Clean up legacy non-container service if present.
if systemctl list-unit-files nextcloud-talk-recording.service >/dev/null 2>&1; then
  systemctl disable --now nextcloud-talk-recording.service >/dev/null 2>&1 || true
fi

install -d -m 0755 /etc/nextcloud-talk-recording
install -d -m 0777 "$RECORDING_DIRECTORY"

cat >/etc/nextcloud-talk-recording/server.conf <<EOF_CONF
[http]
listen = ${LISTEN}

[backend]
backends = ${BACKEND_ID}
directory = ${RECORDING_DIRECTORY}

[${BACKEND_ID}]
url = ${BACKEND_URL}
secret = ${BACKEND_SECRET}
skipverify = ${BACKEND_SKIP_VERIFY}

[signaling]
signalings = ${SIGNALING_ID}

[${SIGNALING_ID}]
url = ${SIGNALING_URL}
internalsecret = ${SIGNALING_SECRET}
EOF_CONF

if [ -n "$STATS_ALLOWED_IPS" ]; then
cat >>/etc/nextcloud-talk-recording/server.conf <<EOF_STATS

[stats]
allowed_ips = ${STATS_ALLOWED_IPS}
EOF_STATS
fi

chmod 0644 /etc/nextcloud-talk-recording/server.conf

install -d -m 0755 /opt/nextcloud-talk-recording-src
if [ ! -d /opt/nextcloud-talk-recording-src/.git ]; then
  git clone --depth 1 "$SOURCE_REPO" /opt/nextcloud-talk-recording-src
fi

cd /opt/nextcloud-talk-recording-src
git fetch --all --tags --prune
git checkout "$SOURCE_REF"

docker build --pull -t "$RUNTIME_IMAGE" -f docker-compose/Dockerfile .

docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true

docker run -d \
  --name "$CONTAINER_NAME" \
  --restart unless-stopped \
  --network host \
  --shm-size=2g \
  --mount type=bind,src=/etc/nextcloud-talk-recording/server.conf,dst=/etc/nextcloud-talk-recording/server.conf,ro \
  --mount type=bind,src="$RECORDING_DIRECTORY",dst="$RECORDING_DIRECTORY" \
  "$RUNTIME_IMAGE"
EOS
)"

REMOTE_SCRIPT="${REMOTE_SCRIPT//__LISTEN_B64__/$LISTEN_B64}"
REMOTE_SCRIPT="${REMOTE_SCRIPT//__BACKEND_ID_B64__/$BACKEND_ID_B64}"
REMOTE_SCRIPT="${REMOTE_SCRIPT//__BACKEND_URL_B64__/$BACKEND_URL_B64}"
REMOTE_SCRIPT="${REMOTE_SCRIPT//__BACKEND_SECRET_B64__/$BACKEND_SECRET_B64}"
REMOTE_SCRIPT="${REMOTE_SCRIPT//__BACKEND_SKIP_VERIFY_B64__/$BACKEND_SKIP_VERIFY_B64}"
REMOTE_SCRIPT="${REMOTE_SCRIPT//__SIGNALING_ID_B64__/$SIGNALING_ID_B64}"
REMOTE_SCRIPT="${REMOTE_SCRIPT//__SIGNALING_URL_B64__/$SIGNALING_URL_B64}"
REMOTE_SCRIPT="${REMOTE_SCRIPT//__SIGNALING_SECRET_B64__/$SIGNALING_SECRET_B64}"
REMOTE_SCRIPT="${REMOTE_SCRIPT//__RECORDING_DIR_B64__/$RECORDING_DIR_B64}"
REMOTE_SCRIPT="${REMOTE_SCRIPT//__CONTAINER_NAME_B64__/$CONTAINER_NAME_B64}"
REMOTE_SCRIPT="${REMOTE_SCRIPT//__RUNTIME_IMAGE_B64__/$RUNTIME_IMAGE_B64}"
REMOTE_SCRIPT="${REMOTE_SCRIPT//__SOURCE_REPO_B64__/$SOURCE_REPO_B64}"
REMOTE_SCRIPT="${REMOTE_SCRIPT//__SOURCE_REF_B64__/$SOURCE_REF_B64}"
REMOTE_SCRIPT="${REMOTE_SCRIPT//__STATS_ALLOWED_IPS_B64__/$STATS_ALLOWED_IPS_B64}"

echo "[INFO] Installing Nextcloud Talk recording runtime on: $HOST_ALIAS"
echo "[INFO] Inventory: $INVENTORY_PATH"
INSTALL_CMD=(ansible -i "$INVENTORY_PATH" "$HOST_ALIAS" -b -m shell -a "$REMOTE_SCRIPT")
if [ "${#ANSIBLE_EXTRA_ARGS[@]}" -gt 0 ]; then
  INSTALL_CMD=("${INSTALL_CMD[@]:0:1}" "${ANSIBLE_EXTRA_ARGS[@]}" "${INSTALL_CMD[@]:1}")
fi
"${INSTALL_CMD[@]}"

echo "[INFO] Local service probe: $WELCOME_URL"
PROBE_CMD=(ansible -i "$INVENTORY_PATH" "$HOST_ALIAS" -b -m shell -a "curl -fsS '$WELCOME_URL' >/dev/null")
if [ "${#ANSIBLE_EXTRA_ARGS[@]}" -gt 0 ]; then
  PROBE_CMD=("${PROBE_CMD[@]:0:1}" "${ANSIBLE_EXTRA_ARGS[@]}" "${PROBE_CMD[@]:1}")
fi
"${PROBE_CMD[@]}"

if [ -n "$TMP_BECOME_VARS" ]; then
  rm -f "$TMP_BECOME_VARS"
fi

echo "[OK] Nextcloud Talk recording runtime install complete."
