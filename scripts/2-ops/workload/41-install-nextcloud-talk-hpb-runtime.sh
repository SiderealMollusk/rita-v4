#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../lib/runbook.sh"

runbook_require_no_args "$@"
runbook_require_cmd ansible
runbook_require_cmd python3

REPO_ROOT="$(runbook_detect_repo_root)"
runbook_source_labrc "$REPO_ROOT"

TALK_RUNTIME_FILE="${TALK_RUNTIME_FILE:-$REPO_ROOT/ops/nextcloud/talk-runtime.yaml}"
INSTANCES_FILE="${INSTANCES_FILE:-$REPO_ROOT/ops/nextcloud/instances.yaml}"
INVENTORY_PATH="${INVENTORY_PATH:-$REPO_ROOT/ops/ansible/inventory/talk-hpb.ini}"
HOST_ALIAS="${HOST_ALIAS:-talk-hpb-vm}"
HPB_VERSION="${NEXTCLOUD_TALK_HPB_VERSION:-v2.1.0}"
GO_VERSION="${NEXTCLOUD_TALK_HPB_GO_VERSION:-1.24.1}"
NEXTCLOUD_SNAPSHOT_MODE="${NEXTCLOUD_SNAPSHOT_MODE:-critical}"

[ -f "$TALK_RUNTIME_FILE" ] || runbook_fail "missing talk runtime file: $TALK_RUNTIME_FILE"
[ -f "$INSTANCES_FILE" ] || runbook_fail "missing instances file: $INSTANCES_FILE"
[ -f "$INVENTORY_PATH" ] || runbook_fail "missing inventory file: $INVENTORY_PATH"

if [ -n "${NEXTCLOUD_AUTO_SNAPSHOT_PRE:-}" ]; then
  if [ "${NEXTCLOUD_AUTO_SNAPSHOT_PRE}" = "1" ]; then
    NEXTCLOUD_SNAPSHOT_MODE="critical"
  else
    NEXTCLOUD_SNAPSHOT_MODE="off"
  fi
fi

PARSED="$(python3 - "$TALK_RUNTIME_FILE" "$INSTANCES_FILE" <<'PY'
import json
import sys
import urllib.parse

talk_file = sys.argv[1]
instances_file = sys.argv[2]

with open(talk_file, "r", encoding="utf-8") as f:
    talk = json.load(f)

with open(instances_file, "r", encoding="utf-8") as f:
    inst = json.load(f)

secret_ref = str((((talk.get("talk") or {}).get("signaling") or {}).get("secret_op_ref") or "")).strip()
signaling_server = str((((talk.get("talk") or {}).get("signaling") or {}).get("server") or "")).strip()
if not signaling_server:
    raise SystemExit("missing talk.signaling.server in talk-runtime file")

official = str(inst.get("official_instance") or "").strip()
instances = inst.get("instances") or {}
official_obj = instances.get(official) or {}
domain = str(official_obj.get("domain") or "").strip()
if not domain:
    parsed = urllib.parse.urlparse(signaling_server)
    domain = parsed.hostname or ""
if not domain:
    raise SystemExit("unable to resolve official nextcloud domain from instances or signaling server")

backend_url = "https://" + domain

print("SIGNALING_SECRET_OP_REF=" + secret_ref)
print("NEXTCLOUD_DOMAIN=" + domain)
print("NEXTCLOUD_BACKEND_URL=" + backend_url)
PY
)"

while IFS= read -r row; do
  case "$row" in
    SIGNALING_SECRET_OP_REF=*) SIGNALING_SECRET_OP_REF="${row#SIGNALING_SECRET_OP_REF=}" ;;
    NEXTCLOUD_DOMAIN=*) NEXTCLOUD_DOMAIN="${row#NEXTCLOUD_DOMAIN=}" ;;
    NEXTCLOUD_BACKEND_URL=*) NEXTCLOUD_BACKEND_URL="${row#NEXTCLOUD_BACKEND_URL=}" ;;
  esac
done <<EOF
$PARSED
EOF

if [ -z "${SIGNALING_SECRET_OP_REF:-}" ]; then
  [ -n "${OP_VAULT_ID:-}" ] || runbook_fail "talk runtime missing secret_op_ref and OP_VAULT_ID is not set"
  SIGNALING_SECRET_OP_REF="$(runbook_build_op_ref "$OP_VAULT_ID" "nextcloud-talk-runtime" "password")"
fi

SIGNALING_SECRET="$(runbook_resolve_secret_from_op "" "$SIGNALING_SECRET_OP_REF")"
[ -n "$SIGNALING_SECRET" ] || runbook_fail "unable to resolve signaling secret from OP"
[ -n "${NEXTCLOUD_DOMAIN:-}" ] || runbook_fail "resolved NEXTCLOUD_DOMAIN is empty"
[ -n "${NEXTCLOUD_BACKEND_URL:-}" ] || runbook_fail "resolved NEXTCLOUD_BACKEND_URL is empty"

if [ "$NEXTCLOUD_SNAPSHOT_MODE" = "critical" ]; then
  echo "[INFO] Creating pre-change Nextcloud VM pair snapshot"
  NEXTCLOUD_SNAPSHOT_CHANGE_ID="41-install-nextcloud-talk-hpb-runtime" \
    "$REPO_ROOT/scripts/2-ops/workload/35-snapshot-nextcloud-pair.sh"
fi

echo "[INFO] Installing Talk HPB runtime on: $HOST_ALIAS"
echo "[INFO] Inventory: $INVENTORY_PATH"
echo "[INFO] Nextcloud domain: $NEXTCLOUD_DOMAIN"
echo "[INFO] Backend URL: $NEXTCLOUD_BACKEND_URL"
echo "[INFO] Signaling secret ref: $SIGNALING_SECRET_OP_REF"
echo "[INFO] Signaling version: $HPB_VERSION"
echo "[INFO] Go version for build: $GO_VERSION"

HPB_VERSION_B64="$(printf '%s' "$HPB_VERSION" | base64 | tr -d '\n')"
GO_VERSION_B64="$(printf '%s' "$GO_VERSION" | base64 | tr -d '\n')"
NEXTCLOUD_DOMAIN_B64="$(printf '%s' "$NEXTCLOUD_DOMAIN" | base64 | tr -d '\n')"
NEXTCLOUD_BACKEND_URL_B64="$(printf '%s' "$NEXTCLOUD_BACKEND_URL" | base64 | tr -d '\n')"
SIGNALING_SECRET_B64="$(printf '%s' "$SIGNALING_SECRET" | base64 | tr -d '\n')"

REMOTE_SCRIPT="$(cat <<'EOS'
set -eu
export DEBIAN_FRONTEND=noninteractive

HPB_VERSION="$(printf '%s' '__HPB_VERSION_B64__' | base64 -d)"
GO_VERSION="$(printf '%s' '__GO_VERSION_B64__' | base64 -d)"
NEXTCLOUD_DOMAIN="$(printf '%s' '__NEXTCLOUD_DOMAIN_B64__' | base64 -d)"
NEXTCLOUD_BACKEND_URL="$(printf '%s' '__NEXTCLOUD_BACKEND_URL_B64__' | base64 -d)"
SIGNALING_SECRET="$(printf '%s' '__SIGNALING_SECRET_B64__' | base64 -d)"
SESSIONS_HASHKEY="$(printf '%s' "$SIGNALING_SECRET" | sha256sum | awk '{print $1}')"

apt-get update -y
apt-get install -y --no-install-recommends ca-certificates curl python3 make golang-go nats-server janus

go_tgz="/tmp/go-${GO_VERSION}.linux-amd64.tar.gz"
curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" -o "$go_tgz"
rm -rf /usr/local/go
tar -C /usr/local -xzf "$go_tgz"
rm -f "$go_tgz"
export PATH="/usr/local/go/bin:$PATH"

install -d -m 0755 /etc/signaling
if ! id signaling >/dev/null 2>&1; then
  useradd --system --home-dir /var/lib/nextcloud-spreed-signaling --shell /usr/sbin/nologin --user-group signaling
fi
install -d -m 0750 -o signaling -g signaling /var/lib/nextcloud-spreed-signaling

tmp_dir="$(mktemp -d)"
cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

release_api="https://api.github.com/repos/strukturag/nextcloud-spreed-signaling/releases/tags/${HPB_VERSION}"
asset_url="$(python3 - "$release_api" <<'PY'
import json
import sys
import urllib.request

api = sys.argv[1]
with urllib.request.urlopen(api) as resp:
    payload = json.load(resp)

assets = payload.get("assets", [])
selected = ""
for item in assets:
    name = str(item.get("name", "")).lower()
    if name.startswith("nextcloud-spreed-signaling-") and name.endswith(".tar.gz"):
        selected = item.get("browser_download_url", "")
        break

if not selected:
    raise SystemExit("no signaling source release asset found for tag")
print(selected)
PY
)"

[ -n "$asset_url" ] || { echo "failed to resolve release asset url" >&2; exit 1; }

curl -fsSL "$asset_url" -o "$tmp_dir/signaling-src.tgz"
tar -xzf "$tmp_dir/signaling-src.tgz" -C "$tmp_dir"
src_dir="$(find "$tmp_dir" -mindepth 1 -maxdepth 1 -type d -name 'nextcloud-spreed-signaling-*' | head -n1)"
[ -n "$src_dir" ] || { echo "signaling source dir not found in release archive" >&2; exit 1; }

cd "$src_dir"
make build

bin_path="$src_dir/bin/signaling"
[ -f "$bin_path" ] || { echo "signaling binary not built" >&2; exit 1; }

install -m 0755 "$bin_path" /usr/local/bin/nextcloud-spreed-signaling

cat >/etc/signaling/server.conf <<EOF
[http]
listen = 0.0.0.0:8080

[backend]
allowed = ${NEXTCLOUD_DOMAIN}
allowall = false
secret = ${SIGNALING_SECRET}

[sessions]
hashkey = ${SESSIONS_HASHKEY}

[nats]
url = nats://127.0.0.1:4222

[mcu]
type = janus
url = ws://127.0.0.1:8188

[stats]
allowed_ips = 127.0.0.1
EOF

chmod 600 /etc/signaling/server.conf
chown signaling:signaling /etc/signaling/server.conf

cat >/etc/systemd/system/nextcloud-spreed-signaling.service <<'EOF'
[Unit]
Description=Nextcloud Talk signaling server
After=network-online.target nats-server.service janus.service
Wants=network-online.target

[Service]
Type=simple
User=signaling
Group=signaling
WorkingDirectory=/var/lib/nextcloud-spreed-signaling
ExecStart=/usr/local/bin/nextcloud-spreed-signaling --config /etc/signaling/server.conf
Restart=always
RestartSec=3
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOF

if [ -f /etc/janus/janus.transport.websockets.jcfg ]; then
  python3 - <<'PY'
from pathlib import Path
cfg = Path("/etc/janus/janus.transport.websockets.jcfg")
text = cfg.read_text(encoding="utf-8")
text = text.replace("#ws = true", "ws = true")
text = text.replace("#ws_port = 8188", "ws_port = 8188")
text = text.replace("#ws_interface = \"\"", "ws_interface = \"127.0.0.1\"")
cfg.write_text(text, encoding="utf-8")
PY
fi

if [ -f /etc/janus/janus.eventhandler.wsevh.jcfg ]; then
  cat >/etc/janus/janus.eventhandler.wsevh.jcfg <<'EOF'
general: {
  enabled = true
  events = "all"
  grouping = false
  json = "indented"
}

ws-events: {
  backend = "ws://127.0.0.1:8080/api/v1/events"
  subprotocol = "janus-events"
}
EOF
fi

if [ -f /etc/janus/janus.jcfg ]; then
  python3 - <<'PY'
from pathlib import Path
cfg = Path("/etc/janus/janus.jcfg")
text = cfg.read_text(encoding="utf-8")
text = text.replace("#broadcast = true", "broadcast = true")
text = text.replace("#full_trickle = true", "full_trickle = true")
cfg.write_text(text, encoding="utf-8")
PY
fi

systemctl daemon-reload
systemctl enable --now nats-server.service
systemctl enable --now janus.service
systemctl enable --now nextcloud-spreed-signaling.service
systemctl restart nats-server.service janus.service nextcloud-spreed-signaling.service

systemctl --no-pager --full status nats-server.service janus.service nextcloud-spreed-signaling.service | sed -n '1,120p'
for _ in $(seq 1 30); do
  if curl -fsS http://127.0.0.1:8080/api/v1/welcome >/dev/null 2>&1; then
    break
  fi
  sleep 1
done
curl -fsS http://127.0.0.1:8080/api/v1/welcome
EOS
)"

REMOTE_SCRIPT="${REMOTE_SCRIPT//__HPB_VERSION_B64__/$HPB_VERSION_B64}"
REMOTE_SCRIPT="${REMOTE_SCRIPT//__GO_VERSION_B64__/$GO_VERSION_B64}"
REMOTE_SCRIPT="${REMOTE_SCRIPT//__NEXTCLOUD_DOMAIN_B64__/$NEXTCLOUD_DOMAIN_B64}"
REMOTE_SCRIPT="${REMOTE_SCRIPT//__NEXTCLOUD_BACKEND_URL_B64__/$NEXTCLOUD_BACKEND_URL_B64}"
REMOTE_SCRIPT="${REMOTE_SCRIPT//__SIGNALING_SECRET_B64__/$SIGNALING_SECRET_B64}"

ansible -i "$INVENTORY_PATH" "$HOST_ALIAS" -b -m shell -a "$REMOTE_SCRIPT"

echo "[OK] Nextcloud Talk HPB runtime installed."
