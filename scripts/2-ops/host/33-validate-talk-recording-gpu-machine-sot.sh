#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../lib/runbook.sh"

runbook_require_no_args "$@"
runbook_source_labrc "$REPO_ROOT"

LAN_IP="${TALK_RECORDING_GPU_LAN_IP:-192.168.6.19}"

echo "[INFO] Validating machine-level SoT for talk-recording-gpu at ${LAN_IP}"
"$REPO_ROOT/scripts/lib/validate-machine-sot.sh" \
  --repo-root "$REPO_ROOT" \
  --lan-ip "$LAN_IP"
