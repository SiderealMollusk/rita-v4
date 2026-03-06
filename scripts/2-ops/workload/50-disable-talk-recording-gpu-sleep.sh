#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../lib/runbook.sh"

runbook_require_no_args "$@"
runbook_require_host_terminal

REPO_ROOT="$(runbook_detect_repo_root)"
runbook_source_labrc "$REPO_ROOT"

INVENTORY_PATH="${TALK_RECORDING_INVENTORY_PATH:-$REPO_ROOT/ops/ansible/inventory/talk-recording.ini}"
HOST_ALIAS="${TALK_RECORDING_HOST_ALIAS:-talk-recording-gpu}"
BECOME_PASSWORD_OP_REF="${TALK_RECORDING_BECOME_PASSWORD_OP_REF:-}"
BECOME_PASSWORD="${TALK_RECORDING_BECOME_PASSWORD:-}"

[ -f "$INVENTORY_PATH" ] || runbook_fail "missing inventory file: $INVENTORY_PATH"
[ -x "$REPO_ROOT/scripts/lib/disable-machine-sleep.sh" ] || runbook_fail "missing logic script: $REPO_ROOT/scripts/lib/disable-machine-sleep.sh"

ARGS=(
  --inventory "$INVENTORY_PATH"
  --host-alias "$HOST_ALIAS"
)

if [ -n "$BECOME_PASSWORD_OP_REF" ]; then
  ARGS+=(--become-password-op-ref "$BECOME_PASSWORD_OP_REF")
elif [ -n "$BECOME_PASSWORD" ]; then
  ARGS+=(--become-password "$BECOME_PASSWORD")
fi

"$REPO_ROOT/scripts/lib/disable-machine-sleep.sh" "${ARGS[@]}"
