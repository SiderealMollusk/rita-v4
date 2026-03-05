#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../lib/runbook.sh"

runbook_require_no_args "$@"
runbook_require_host_terminal

CONFIG_FILE="$REPO_ROOT/ops/nextcloud/appapi-runtime.yaml"
DEFAULT_OCC_PATH="/var/www/nextcloud/occ"

[ -f "$CONFIG_FILE" ] || runbook_fail "missing config file: $CONFIG_FILE"

runbook_require_cmd python3
runbook_require_cmd ansible

PARSED="$(
python3 - "$CONFIG_FILE" <<'PY'
import json
import sys

path = sys.argv[1]
with open(path, "r", encoding="utf-8") as f:
    cfg = json.load(f)

inventory_file = str(cfg.get("inventory_file", "")).strip()
host_alias = str(cfg.get("host_alias", "")).strip()
occ_path = str(cfg.get("occ_path", "/var/www/nextcloud/occ")).strip()
nextcloud_url = str(cfg.get("nextcloud_url", "")).strip()

daemon = cfg.get("daemon", {}) if isinstance(cfg.get("daemon", {}), dict) else {}
mode = str(daemon.get("mode", "")).strip()
name = str(daemon.get("name", "")).strip()
display_name = str(daemon.get("display_name", "")).strip()
accepts_deploy_id = str(daemon.get("accepts_deploy_id", "")).strip()
protocol = str(daemon.get("protocol", "")).strip()
host = str(daemon.get("host", "")).strip()
set_default = bool(daemon.get("set_default", True))
harp_frp_address = str(daemon.get("harp_frp_address", "")).strip()
harp_shared_key = str(daemon.get("harp_shared_key", "")).strip()
harp_shared_key_op_ref = str(daemon.get("harp_shared_key_op_ref", "")).strip()
harp_docker_socket_port = str(daemon.get("harp_docker_socket_port", "24000")).strip()
harp_exapp_direct = bool(daemon.get("harp_exapp_direct", False))

harp_runtime = cfg.get("harp_runtime", {}) if isinstance(cfg.get("harp_runtime", {}), dict) else {}
runtime_enabled = bool(harp_runtime.get("enabled", True))
container_name = str(harp_runtime.get("container_name", "appapi-harp")).strip()
image = str(harp_runtime.get("image", "ghcr.io/nextcloud/nextcloud-appapi-harp:release")).strip()
listen_host = str(harp_runtime.get("listen_host", "127.0.0.1")).strip()
exapps_port = str(harp_runtime.get("exapps_port", 8780)).strip()
frp_port = str(harp_runtime.get("frp_port", 8782)).strip()

print("INVENTORY_FILE=" + inventory_file)
print("HOST_ALIAS=" + host_alias)
print("OCC_PATH=" + occ_path)
print("NEXTCLOUD_URL=" + nextcloud_url)
print("DAEMON_MODE=" + mode)
print("DAEMON_NAME=" + name)
print("DAEMON_DISPLAY_NAME=" + display_name)
print("DAEMON_ACCEPTS_DEPLOY_ID=" + accepts_deploy_id)
print("DAEMON_PROTOCOL=" + protocol)
print("DAEMON_HOST=" + host)
print("DAEMON_SET_DEFAULT=" + ("1" if set_default else "0"))
print("HARP_FRP_ADDRESS=" + harp_frp_address)
print("HARP_SHARED_KEY=" + harp_shared_key)
print("HARP_SHARED_KEY_OP_REF=" + harp_shared_key_op_ref)
print("HARP_DOCKER_SOCKET_PORT=" + harp_docker_socket_port)
print("HARP_EXAPP_DIRECT=" + ("1" if harp_exapp_direct else "0"))
print("RUNTIME_ENABLED=" + ("1" if runtime_enabled else "0"))
print("RUNTIME_CONTAINER_NAME=" + container_name)
print("RUNTIME_IMAGE=" + image)
print("RUNTIME_LISTEN_HOST=" + listen_host)
print("RUNTIME_EXAPPS_PORT=" + exapps_port)
print("RUNTIME_FRP_PORT=" + frp_port)
PY
)"

get_parsed() {
  local key="$1"
  printf '%s\n' "$PARSED" | sed -n "s/^${key}=//p" | head -n1
}

INVENTORY_REL="$(get_parsed INVENTORY_FILE)"
HOST_ALIAS="$(get_parsed HOST_ALIAS)"
OCC_PATH="$(get_parsed OCC_PATH)"
NEXTCLOUD_URL="$(get_parsed NEXTCLOUD_URL)"
DAEMON_MODE="$(get_parsed DAEMON_MODE)"
DAEMON_NAME="$(get_parsed DAEMON_NAME)"
DAEMON_DISPLAY_NAME="$(get_parsed DAEMON_DISPLAY_NAME)"
DAEMON_ACCEPTS_DEPLOY_ID="$(get_parsed DAEMON_ACCEPTS_DEPLOY_ID)"
DAEMON_PROTOCOL="$(get_parsed DAEMON_PROTOCOL)"
DAEMON_HOST="$(get_parsed DAEMON_HOST)"
DAEMON_SET_DEFAULT="$(get_parsed DAEMON_SET_DEFAULT)"
HARP_FRP_ADDRESS="$(get_parsed HARP_FRP_ADDRESS)"
HARP_SHARED_KEY="$(get_parsed HARP_SHARED_KEY)"
HARP_SHARED_KEY_OP_REF="$(get_parsed HARP_SHARED_KEY_OP_REF)"
HARP_DOCKER_SOCKET_PORT="$(get_parsed HARP_DOCKER_SOCKET_PORT)"
HARP_EXAPP_DIRECT="$(get_parsed HARP_EXAPP_DIRECT)"
RUNTIME_ENABLED="$(get_parsed RUNTIME_ENABLED)"
RUNTIME_CONTAINER_NAME="$(get_parsed RUNTIME_CONTAINER_NAME)"
RUNTIME_IMAGE="$(get_parsed RUNTIME_IMAGE)"
RUNTIME_LISTEN_HOST="$(get_parsed RUNTIME_LISTEN_HOST)"
RUNTIME_EXAPPS_PORT="$(get_parsed RUNTIME_EXAPPS_PORT)"
RUNTIME_FRP_PORT="$(get_parsed RUNTIME_FRP_PORT)"

[ -n "$INVENTORY_REL" ] || runbook_fail "inventory_file missing in $CONFIG_FILE"
[ -n "$HOST_ALIAS" ] || runbook_fail "host_alias missing in $CONFIG_FILE"
[ -n "$NEXTCLOUD_URL" ] || runbook_fail "nextcloud_url missing in $CONFIG_FILE"
[ "$DAEMON_MODE" = "harp" ] || runbook_fail "daemon.mode must be 'harp' for this script"
[ -n "$DAEMON_NAME" ] || runbook_fail "daemon.name missing in $CONFIG_FILE"
[ -n "$DAEMON_DISPLAY_NAME" ] || runbook_fail "daemon.display_name missing in $CONFIG_FILE"
[ -n "$DAEMON_ACCEPTS_DEPLOY_ID" ] || runbook_fail "daemon.accepts_deploy_id missing in $CONFIG_FILE"
[ -n "$DAEMON_PROTOCOL" ] || runbook_fail "daemon.protocol missing in $CONFIG_FILE"
[ -n "$DAEMON_HOST" ] || runbook_fail "daemon.host missing in $CONFIG_FILE"
[ -n "$HARP_FRP_ADDRESS" ] || runbook_fail "daemon.harp_frp_address missing in $CONFIG_FILE"
[ -n "$HARP_DOCKER_SOCKET_PORT" ] || runbook_fail "daemon.harp_docker_socket_port missing in $CONFIG_FILE"

INVENTORY_PATH="$REPO_ROOT/$INVENTORY_REL"
[ -f "$INVENTORY_PATH" ] || runbook_fail "inventory path missing: $INVENTORY_PATH"

if [ -z "$HARP_SHARED_KEY" ] && [ -n "$HARP_SHARED_KEY_OP_REF" ]; then
  runbook_require_op_access
  HARP_SHARED_KEY="$(runbook_resolve_secret_from_op "" "$HARP_SHARED_KEY_OP_REF")"
fi
[ -n "$HARP_SHARED_KEY" ] || runbook_fail "missing daemon.harp_shared_key and daemon.harp_shared_key_op_ref in $CONFIG_FILE"

echo "[INFO] Configuring HaRP runtime on: $HOST_ALIAS"
echo "[INFO] Inventory: $INVENTORY_PATH"
echo "[INFO] Daemon name: $DAEMON_NAME"
echo "[INFO] Daemon host: $DAEMON_HOST"
echo "[INFO] HaRP FRP address: $HARP_FRP_ADDRESS"
echo "[INFO] Container image: $RUNTIME_IMAGE"

shared_key_b64="$(printf '%s' "$HARP_SHARED_KEY" | base64 | tr -d '\n')"
nextcloud_url_b64="$(printf '%s' "$NEXTCLOUD_URL" | base64 | tr -d '\n')"
container_name_b64="$(printf '%s' "$RUNTIME_CONTAINER_NAME" | base64 | tr -d '\n')"
image_b64="$(printf '%s' "$RUNTIME_IMAGE" | base64 | tr -d '\n')"
listen_host_b64="$(printf '%s' "$RUNTIME_LISTEN_HOST" | base64 | tr -d '\n')"
exapps_port_b64="$(printf '%s' "$RUNTIME_EXAPPS_PORT" | base64 | tr -d '\n')"
frp_port_b64="$(printf '%s' "$RUNTIME_FRP_PORT" | base64 | tr -d '\n')"

if [ "$RUNTIME_ENABLED" = "1" ]; then
  ansible -i "$INVENTORY_PATH" "$HOST_ALIAS" -b -m shell -a "set -eu
export DEBIAN_FRONTEND=noninteractive
if ! command -v docker >/dev/null 2>&1; then
  apt-get update
  apt-get install -y ca-certificates curl
  curl -fsSL https://get.docker.com | sh
fi
systemctl enable --now docker
SHARED_KEY=\"\$(printf '%s' '$shared_key_b64' | base64 -d)\"
NC_URL=\"\$(printf '%s' '$nextcloud_url_b64' | base64 -d)\"
CONTAINER_NAME=\"\$(printf '%s' '$container_name_b64' | base64 -d)\"
IMAGE=\"\$(printf '%s' '$image_b64' | base64 -d)\"
LISTEN_HOST=\"\$(printf '%s' '$listen_host_b64' | base64 -d)\"
EXAPPS_PORT=\"\$(printf '%s' '$exapps_port_b64' | base64 -d)\"
FRP_PORT=\"\$(printf '%s' '$frp_port_b64' | base64 -d)\"
docker rm -f \"\$CONTAINER_NAME\" >/dev/null 2>&1 || true
docker pull \"\$IMAGE\" >/dev/null
docker run -d \
  --name \"\$CONTAINER_NAME\" \
  --restart unless-stopped \
  -p \"\${LISTEN_HOST}:\${EXAPPS_PORT}:8780\" \
  -p \"\${LISTEN_HOST}:\${FRP_PORT}:8782\" \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -e HP_SHARED_KEY=\"\$SHARED_KEY\" \
  -e NC_INSTANCE_URL=\"\$NC_URL\" \
  -e HP_EXAPPS_ADDRESS=0.0.0.0:8780 \
  -e HP_FRP_ADDRESS=0.0.0.0:8782 \
  -e HP_VERBOSE_START=1 \
  \"\$IMAGE\" >/dev/null
docker ps --filter \"name=\$CONTAINER_NAME\" | tail -n +2
"
fi

register_args=(
  --mode harp
  --inventory "$INVENTORY_PATH"
  --host-alias "$HOST_ALIAS"
  --occ-path "${OCC_PATH:-$DEFAULT_OCC_PATH}"
  --daemon-name "$DAEMON_NAME"
  --display-name "$DAEMON_DISPLAY_NAME"
  --accepts-deploy-id "$DAEMON_ACCEPTS_DEPLOY_ID"
  --protocol "$DAEMON_PROTOCOL"
  --host "$DAEMON_HOST"
  --nextcloud-url "$NEXTCLOUD_URL"
  --harp-frp-address "$HARP_FRP_ADDRESS"
  --harp-docker-socket-port "$HARP_DOCKER_SOCKET_PORT"
  --harp-shared-key "$HARP_SHARED_KEY"
  --replace-existing
)

if [ "$DAEMON_SET_DEFAULT" = "1" ]; then
  register_args+=(--set-default)
else
  register_args+=(--no-set-default)
fi

if [ "$HARP_EXAPP_DIRECT" = "1" ]; then
  register_args+=(--harp-exapp-direct)
fi

"$SCRIPT_DIR/18-register-nextcloud-appapi-daemon.sh" "${register_args[@]}"

echo "[OK] Nextcloud HaRP runtime + daemon configuration applied."
