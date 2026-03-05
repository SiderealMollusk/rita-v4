#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../lib/runbook.sh"

runbook_require_no_args "$@"
runbook_require_host_terminal

REPO_ROOT="$(runbook_detect_repo_root)"

INSTALL_SCRIPT="$REPO_ROOT/scripts/2-ops/workload/41-install-nextcloud-talk-hpb-runtime.sh"
CONFIG_SCRIPT="$REPO_ROOT/scripts/2-ops/workload/26-configure-nextcloud-talk-runtime.sh"
VERIFY_SCRIPT="$REPO_ROOT/scripts/2-ops/workload/42-verify-nextcloud-talk-hpb-runtime.sh"
SITES_VERIFY_SCRIPT="$REPO_ROOT/scripts/2-ops/host/28-verify-pangolin-sites-and-newt.sh"
VERIFY_SITES="${HPB_VERIFY_SITES:-0}"

[ -x "$INSTALL_SCRIPT" ] || runbook_fail "missing script: $INSTALL_SCRIPT"
[ -x "$CONFIG_SCRIPT" ] || runbook_fail "missing script: $CONFIG_SCRIPT"
[ -x "$VERIFY_SCRIPT" ] || runbook_fail "missing script: $VERIFY_SCRIPT"
[ -x "$SITES_VERIFY_SCRIPT" ] || runbook_fail "missing script: $SITES_VERIFY_SCRIPT"

echo "[INFO] Step 1/4: install Talk HPB runtime on talk-hpb-vm"
"$INSTALL_SCRIPT"

echo "[INFO] Step 2/4: apply Nextcloud Talk runtime SoT"
if [ "${NEXTCLOUD_SNAPSHOT_MODE:-critical}" = "critical" ]; then
  NEXTCLOUD_SNAPSHOT_MODE=off "$CONFIG_SCRIPT"
else
  "$CONFIG_SCRIPT"
fi

echo "[INFO] Step 3/4: verify Talk HPB runtime + runtime wiring"
"$VERIFY_SCRIPT"

if [ "$VERIFY_SITES" = "1" ]; then
  echo "[INFO] Step 4/4: verify Pangolin + VM Newt baseline"
  "$SITES_VERIFY_SCRIPT"
else
  echo "[INFO] Step 4/4: skipped Pangolin/Newt global site verification (set HPB_VERIFY_SITES=1 to enable)"
fi

echo "[OK] Nextcloud Talk HPB bring-up completed."
