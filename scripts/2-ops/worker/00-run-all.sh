#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../lib/runbook.sh"

runbook_require_no_args "$@"

echo "[INFO] Running platform worker runbook pipeline"
for phase in \
  01-ansible-ping.sh \
  02-bootstrap-host.sh \
  03-install-k3s-agent.sh \
  04-label-nodes.sh \
  05-verify-cluster.sh
do
  echo "[INFO] >>> ${phase}"
  "$SCRIPT_DIR/${phase}"
done
