#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PARENT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=/dev/null
source "$PARENT_DIR/../../lib/runbook.sh"

runbook_require_no_args "$@"

echo "[INFO] Running ops-brain bootstrap phase"
for step in \
  01-ansible-ping.sh \
  02-bootstrap-host.sh \
  03-configure-power-policy.sh \
  04-install-k3s.sh \
  05-install-helm.sh \
  06-label-node.sh \
  07-verify-cluster.sh
  do
  echo "[INFO] >>> ${step}"
  "$PARENT_DIR/${step}"
done
