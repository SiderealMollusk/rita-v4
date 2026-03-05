#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../lib/runbook.sh"

runbook_require_host_terminal
runbook_require_cmd ssh

PVE_HOST="${NEXTCLOUD_PVE_HOST:-192.168.6.11}"
CORE_VMID="${NEXTCLOUD_CORE_VMID:-9301}"
TALK_VMID="${NEXTCLOUD_TALK_HPB_VMID:-9302}"
ROLLBACK_TAG="${NEXTCLOUD_ROLLBACK_TAG:-}"
INCLUDE_CORE=1
INCLUDE_TALK=1
CONFIRM="${NEXTCLOUD_ROLLBACK_CONFIRM:-}"

usage() {
  cat <<'EOF'
Usage:
  36-rollback-nextcloud-pair.sh --tag <snapshot-tag> [options]

Options:
  --tag <tag>              Snapshot tag to rollback both VMs to
  --pve-host <ip-or-host>  Proxmox host (default: 192.168.6.11)
  --core-vmid <id>         Nextcloud core VM ID (default: 9301)
  --talk-vmid <id>         Talk HPB VM ID (default: 9302)
  --core-only              Rollback only core VM
  --talk-only              Rollback only talk VM
  --yes                    Set rollback confirmation automatically
  --help                   Show help
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --tag) ROLLBACK_TAG="${2:-}"; shift 2 ;;
    --pve-host) PVE_HOST="${2:-}"; shift 2 ;;
    --core-vmid) CORE_VMID="${2:-}"; shift 2 ;;
    --talk-vmid) TALK_VMID="${2:-}"; shift 2 ;;
    --core-only) INCLUDE_CORE=1; INCLUDE_TALK=0; shift ;;
    --talk-only) INCLUDE_CORE=0; INCLUDE_TALK=1; shift ;;
    --yes) CONFIRM="rollback-nextcloud-pair"; shift ;;
    --help|-h) usage; exit 0 ;;
    *) runbook_fail "Unknown argument: $1" ;;
  esac
done

[ -n "$ROLLBACK_TAG" ] || runbook_fail "missing --tag <snapshot-tag>"
[ "$INCLUDE_CORE" = "1" ] || [ "$INCLUDE_TALK" = "1" ] || runbook_fail "nothing selected to rollback"
[ "$CONFIRM" = "rollback-nextcloud-pair" ] || runbook_fail "set NEXTCLOUD_ROLLBACK_CONFIRM=rollback-nextcloud-pair (or pass --yes) to execute rollback"

rollback_vm() {
  local vmid="$1"
  local label="$2"
  echo "[INFO] Rolling back ${label} VM ${vmid} to ${ROLLBACK_TAG}"
  ssh "root@${PVE_HOST}" "set -eu;
    qm listsnapshot '${vmid}' | awk '{print \$1}' | grep -Fx '${ROLLBACK_TAG}' >/dev/null || { echo 'snapshot not found on vm ${vmid}: ${ROLLBACK_TAG}' >&2; exit 1; }
    qm rollback '${vmid}' '${ROLLBACK_TAG}'"
}

if [ "$INCLUDE_CORE" = "1" ]; then
  rollback_vm "$CORE_VMID" "nextcloud-core"
fi
if [ "$INCLUDE_TALK" = "1" ]; then
  rollback_vm "$TALK_VMID" "talk-hpb"
fi

echo "[OK] Rollback complete. tag=${ROLLBACK_TAG}"
