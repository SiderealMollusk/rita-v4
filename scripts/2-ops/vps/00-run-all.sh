#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../lib/runbook.sh"

runbook_require_no_args "$@"
REPO_ROOT="$(runbook_detect_repo_root)"
VPS_DIR="$REPO_ROOT/scripts/2-ops/vps"

STEPS=(
  "01-ansible-ping.sh"
  "02-bootstrap-host.sh"
  "03-install-k3s.sh"
  "04-install-eso.sh"
  "05-apply-secret-bridge.sh"
  "06-pangolin-preflight.sh"
  "07-pangolin-deploy.sh"
  "08-pangolin-verify.sh"
)

echo "[INFO] Running VPS runbook pipeline"
for step in "${STEPS[@]}"; do
  echo "[INFO] >>> $step"
  "$VPS_DIR/$step"
done

echo "[OK] VPS runbook pipeline complete"
