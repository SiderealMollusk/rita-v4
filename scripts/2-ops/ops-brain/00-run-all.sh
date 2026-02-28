#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../lib/runbook.sh"

runbook_require_no_args "$@"

echo "[INFO] Running ops-brain runbook pipeline"
for step in \
  01-ansible-ping.sh \
  02-bootstrap-host.sh \
  03-configure-power-policy.sh \
  04-install-k3s.sh \
  05-install-helm.sh \
  06-label-node.sh
  do
  echo "[INFO] >>> ${step}"
  "$SCRIPT_DIR/${step}"
done
