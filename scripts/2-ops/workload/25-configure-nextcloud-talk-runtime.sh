#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../lib/runbook.sh"

REPO_ROOT="$(runbook_detect_repo_root)"

INVENTORY_PATH="$REPO_ROOT/ops/ansible/inventory/nextcloud.ini"
HOST_ALIAS="nextcloud-vm"
NEXTCLOUD_OCC_PATH="/var/www/nextcloud/occ"
NEXTCLOUD_DOMAIN="cloud.virgil.info"

NOTIFY_PUSH_ENABLED="false"
NOTIFY_PUSH_ENDPOINT=""

SIGNALING_SERVER=""
SIGNALING_SECRET=""
SIGNALING_SECRET_OP_REF=""
SIGNALING_VERIFY_TLS="true"

declare -a STUN_SERVERS=()
declare -a TURN_SERVERS=()

usage() {
  cat <<'EOF'
Usage:
  25-configure-nextcloud-talk-runtime.sh [options]

Options:
  --inventory <path>                 Ansible inventory path
  --host-alias <host>                Inventory host alias (default: nextcloud-vm)
  --occ-path <path>                  Remote occ path (default: /var/www/nextcloud/occ)
  --nextcloud-domain <domain>        Nextcloud public domain (default: cloud.virgil.info)
  --enable-notify-push               Install/enable notify_push and run setup
  --notify-push-endpoint <url>       notify_push endpoint (ex: https://cloud.virgil.info/push)
  --signaling-server <wss-url>       Talk signaling URL
  --signaling-secret <value>         Talk signaling shared secret (direct value)
  --signaling-secret-op-ref <op://>  Talk signaling shared secret via OP reference
  --signaling-verify-tls             Validate signaling TLS cert (default)
  --signaling-no-verify-tls          Do not validate signaling TLS cert
  --stun-server <host:port>          Add STUN server (repeatable)
  --turn-server <spec>               Add TURN server (repeatable):
                                     schemes|server|protocols|secret
                                     example: turn,turns|turn.example.com|udp,tcp|supersecret
  --help                             Show help
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --inventory)
      INVENTORY_PATH="${2:-}"
      shift 2
      ;;
    --host-alias)
      HOST_ALIAS="${2:-}"
      shift 2
      ;;
    --occ-path)
      NEXTCLOUD_OCC_PATH="${2:-}"
      shift 2
      ;;
    --nextcloud-domain)
      NEXTCLOUD_DOMAIN="${2:-}"
      shift 2
      ;;
    --enable-notify-push)
      NOTIFY_PUSH_ENABLED="true"
      shift
      ;;
    --notify-push-endpoint)
      NOTIFY_PUSH_ENDPOINT="${2:-}"
      shift 2
      ;;
    --signaling-server)
      SIGNALING_SERVER="${2:-}"
      shift 2
      ;;
    --signaling-secret)
      SIGNALING_SECRET="${2:-}"
      shift 2
      ;;
    --signaling-secret-op-ref)
      SIGNALING_SECRET_OP_REF="${2:-}"
      shift 2
      ;;
    --signaling-verify-tls)
      SIGNALING_VERIFY_TLS="true"
      shift
      ;;
    --signaling-no-verify-tls)
      SIGNALING_VERIFY_TLS="false"
      shift
      ;;
    --stun-server)
      STUN_SERVERS+=("${2:-}")
      shift 2
      ;;
    --turn-server)
      TURN_SERVERS+=("${2:-}")
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      runbook_fail "Unknown argument: $1"
      ;;
  esac
done

[ -f "$INVENTORY_PATH" ] || runbook_fail "missing inventory file: $INVENTORY_PATH"
[ -n "$HOST_ALIAS" ] || runbook_fail "--host-alias must not be empty"
[ -n "$NEXTCLOUD_OCC_PATH" ] || runbook_fail "--occ-path must not be empty"
[ -n "$NEXTCLOUD_DOMAIN" ] || runbook_fail "--nextcloud-domain must not be empty"

runbook_require_cmd ansible

if [ -n "$SIGNALING_SECRET_OP_REF" ] && [ -z "$SIGNALING_SECRET" ]; then
  SIGNALING_SECRET="$(runbook_resolve_secret_from_op "" "$SIGNALING_SECRET_OP_REF")"
fi

if [ -n "$SIGNALING_SERVER" ] && [ -z "$SIGNALING_SECRET" ]; then
  runbook_fail "signaling configured but secret is missing (set --signaling-secret or --signaling-secret-op-ref)"
fi

if [ "$NOTIFY_PUSH_ENABLED" = "true" ] && [ -z "$NOTIFY_PUSH_ENDPOINT" ]; then
  NOTIFY_PUSH_ENDPOINT="https://${NEXTCLOUD_DOMAIN}/push"
fi

stun_payload="$(printf '%s\n' "${STUN_SERVERS[@]-}")"
turn_payload="$(printf '%s\n' "${TURN_SERVERS[@]-}")"

SIGNALING_SERVER_B64="$(printf '%s' "$SIGNALING_SERVER" | base64 | tr -d '\n')"
SIGNALING_SECRET_B64="$(printf '%s' "$SIGNALING_SECRET" | base64 | tr -d '\n')"
NOTIFY_PUSH_ENDPOINT_B64="$(printf '%s' "$NOTIFY_PUSH_ENDPOINT" | base64 | tr -d '\n')"
STUN_LIST_B64="$(printf '%s' "$stun_payload" | base64 | tr -d '\n')"
TURN_LIST_B64="$(printf '%s' "$turn_payload" | base64 | tr -d '\n')"

echo "[INFO] Configuring Nextcloud Talk runtime on: $HOST_ALIAS"
echo "[INFO] notify_push enabled: $NOTIFY_PUSH_ENABLED"
echo "[INFO] signaling server set: $([ -n "$SIGNALING_SERVER" ] && echo yes || echo no)"
echo "[INFO] STUN server count: ${#STUN_SERVERS[@]}"
echo "[INFO] TURN server count: ${#TURN_SERVERS[@]}"

ansible -i "$INVENTORY_PATH" "$HOST_ALIAS" -b -m shell -a "set -eu
OCC='$NEXTCLOUD_OCC_PATH'
NC_DOMAIN='$NEXTCLOUD_DOMAIN'
ENABLE_NOTIFY_PUSH='$NOTIFY_PUSH_ENABLED'
SIGNALING_VERIFY_TLS='$SIGNALING_VERIFY_TLS'

SIGNALING_SERVER=\"\$(printf '%s' '$SIGNALING_SERVER_B64' | base64 -d)\"
SIGNALING_SECRET=\"\$(printf '%s' '$SIGNALING_SECRET_B64' | base64 -d)\"
NOTIFY_PUSH_ENDPOINT=\"\$(printf '%s' '$NOTIFY_PUSH_ENDPOINT_B64' | base64 -d)\"
STUN_PAYLOAD=\"\$(printf '%s' '$STUN_LIST_B64' | base64 -d)\"
TURN_PAYLOAD=\"\$(printf '%s' '$TURN_LIST_B64' | base64 -d)\"

run_occ() {
  sudo -u www-data php \"\$OCC\" \"\$@\"
}

if [ \"\$ENABLE_NOTIFY_PUSH\" = \"true\" ]; then
  run_occ app:install notify_push >/dev/null 2>&1 || run_occ app:enable notify_push >/dev/null 2>&1 || true
  if run_occ list | grep -q '^  notify_push:setup'; then
    run_occ notify_push:setup \"\$NOTIFY_PUSH_ENDPOINT\" >/dev/null 2>&1 || true
  fi
fi

if [ -n \"\$SIGNALING_SERVER\" ]; then
  if ! run_occ talk:signaling:list | grep -Fq \"\$SIGNALING_SERVER\"; then
    if [ \"\$SIGNALING_VERIFY_TLS\" = \"true\" ]; then
      run_occ talk:signaling:add --verify \"\$SIGNALING_SERVER\" \"\$SIGNALING_SECRET\"
    else
      run_occ talk:signaling:add \"\$SIGNALING_SERVER\" \"\$SIGNALING_SECRET\"
    fi
  fi
fi

if [ -n \"\$STUN_PAYLOAD\" ]; then
  printf '%s\n' \"\$STUN_PAYLOAD\" | while IFS= read -r stun; do
    [ -n \"\$stun\" ] || continue
    if ! run_occ talk:stun:list | grep -Fq \"\$stun\"; then
      run_occ talk:stun:add \"\$stun\"
    fi
  done
fi

if [ -n \"\$TURN_PAYLOAD\" ]; then
  printf '%s\n' \"\$TURN_PAYLOAD\" | while IFS= read -r spec; do
    [ -n \"\$spec\" ] || continue
    IFS='|' read -r schemes server protocols secret <<EOF_TURN
\$spec
EOF_TURN
    [ -n \"\$schemes\" ] || { echo \"[FAIL] TURN spec missing schemes: \$spec\" >&2; exit 1; }
    [ -n \"\$server\" ] || { echo \"[FAIL] TURN spec missing server: \$spec\" >&2; exit 1; }
    [ -n \"\$protocols\" ] || { echo \"[FAIL] TURN spec missing protocols: \$spec\" >&2; exit 1; }
    [ -n \"\$secret\" ] || { echo \"[FAIL] TURN spec missing secret: \$spec\" >&2; exit 1; }
    if ! run_occ talk:turn:list | grep -Fq \"\$server\"; then
      run_occ talk:turn:add --secret=\"\$secret\" \"\$schemes\" \"\$server\" \"\$protocols\"
    fi
  done
fi
"

echo "[OK] Nextcloud Talk runtime configuration applied."

