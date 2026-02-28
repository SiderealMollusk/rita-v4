#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../lib/runbook.sh"

runbook_require_no_args "$@"

echo "[INFO] Running ops-brain runbook pipeline"
for phase in \
  01-bootstrap/00-run-all.sh \
  02-services/00-run-all.sh
do
  echo "[INFO] >>> ${phase}"
  "$SCRIPT_DIR/${phase}"
done
