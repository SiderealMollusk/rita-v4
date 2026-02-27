#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../lib/runbook.sh"

runbook_require_no_args "$@"
REPO_ROOT="$(runbook_detect_repo_root)"

INV="$REPO_ROOT/ops/ansible/inventory/vps.ini"
GROUP_VARS="$REPO_ROOT/ops/ansible/group_vars/vps.yml"

[ -f "$GROUP_VARS" ] || runbook_fail "missing group vars file at $GROUP_VARS"

runbook_refresh_known_hosts_from_inventory "$INV"

PANGOLIN_INSTALL_DIR="$(runbook_yaml_get "$GROUP_VARS" "pangolin_install_dir" || true)"
[ -n "$PANGOLIN_INSTALL_DIR" ] || runbook_fail "pangolin_install_dir missing in $GROUP_VARS"
PANGOLIN_INSTALLER_URL="$(runbook_yaml_get "$GROUP_VARS" "pangolin_installer_url" || true)"
[ -n "$PANGOLIN_INSTALLER_URL" ] || runbook_fail "pangolin_installer_url missing in $GROUP_VARS"

echo "[INFO] Staging Pangolin installer on VPS"
ansible -i "$INV" vps -b -m shell -a "set -e; install -d -m 0755 $PANGOLIN_INSTALL_DIR; cd $PANGOLIN_INSTALL_DIR; curl -fsSL $PANGOLIN_INSTALLER_URL -o get-installer.sh; chmod +x get-installer.sh"

SSH_TARGET="$(awk '
  BEGIN { in_vps=0 }
  /^\[vps\]/ { in_vps=1; next }
  /^\[/ { in_vps=0 }
  in_vps && $0 !~ /^[[:space:]]*#/ && NF > 0 {
    for (i=1; i<=NF; i++) {
      if ($i ~ /^ansible_user=/) { split($i,a,"="); u=a[2] }
      if ($i ~ /^ansible_host=/) { split($i,a,"="); h=a[2] }
    }
    if (u != "" && h != "") { print u "@" h; exit }
  }
' "$INV")"
[ -n "$SSH_TARGET" ] || runbook_fail "failed to derive SSH target from $INV"

echo "[INFO] Run installer interactively now:"
echo "       ssh $SSH_TARGET"
echo "       chmod +x /home/virgil/installer"
echo "       sudo /home/virgil/installer"
echo "       cd /home/virgil && docker compose up -d"
echo "[INFO] Continue with 05 after installer completion."
echo "[OK] Installer staged"
