#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PARENT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=/dev/null
source "$PARENT_DIR/../../lib/runbook.sh"

runbook_require_no_args "$@"

echo "[INFO] Running ops-brain services phase"
for step in \
  10-install-newt.sh
  do
  echo "[INFO] >>> ${step}"
  "$PARENT_DIR/${step}"
done
