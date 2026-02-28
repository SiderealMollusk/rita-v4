#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../lib/runbook.sh"

runbook_require_no_args "$@"
runbook_require_host_terminal
runbook_require_op_user_session

echo "[INFO] Running host-ops pipeline"
for step in \
  01-seed-ops-brain-ssh.sh
  do
  echo "[INFO] >>> ${step}"
  "$SCRIPT_DIR/${step}"
done
