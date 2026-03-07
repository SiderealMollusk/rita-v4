#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../lib/runbook.sh"

runbook_require_no_args "$@"
runbook_require_host_terminal
runbook_require_cmd ansible

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
apt-get install -y --no-install-recommends ca-certificates curl docker.io docker-cli
systemctl enable --now docker
command -v docker >/dev/null
docker --version >/dev/null
EOS
)"

echo "[INFO] Installing Docker Engine on: $HOST_ALIAS"
RUN_CMD=(ansible -i "$INVENTORY_PATH" "$HOST_ALIAS" -b -m shell -a "$REMOTE_SCRIPT")
if [ "${#ANSIBLE_EXTRA_ARGS[@]}" -gt 0 ]; then
  RUN_CMD=("${RUN_CMD[@]:0:1}" "${ANSIBLE_EXTRA_ARGS[@]}" "${RUN_CMD[@]:1}")
fi
"${RUN_CMD[@]}"

if [ -n "$TMP_BECOME_VARS" ]; then
  rm -f "$TMP_BECOME_VARS"
fi

echo "[OK] Docker Engine install complete on $HOST_ALIAS."
