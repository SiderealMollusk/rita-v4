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
CHANGE_ID="${NEXTCLOUD_SNAPSHOT_CHANGE_ID:-manual}"
TAG="${NEXTCLOUD_SNAPSHOT_TAG:-}"
DESCRIPTION="${NEXTCLOUD_SNAPSHOT_DESCRIPTION:-}"
INCLUDE_CORE=1
INCLUDE_TALK=1

usage() {
  cat <<'EOF'
Usage:
  35-snapshot-nextcloud-pair.sh [options]

Options:
  --tag <tag>              Explicit snapshot tag (default: pre-<change-id>-<timestamp>)
  --change-id <id>         Change id used in auto tag/description
  --description <text>     Snapshot description
  --pve-host <ip-or-host>  Proxmox host (default: 192.168.6.11)
  --core-vmid <id>         Nextcloud core VM ID (default: 9301)
  --talk-vmid <id>         Talk HPB VM ID (default: 9302)
  --core-only              Snapshot only core VM
  --talk-only              Snapshot only talk VM
  --help                   Show help
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --tag) TAG="${2:-}"; shift 2 ;;
    --change-id) CHANGE_ID="${2:-}"; shift 2 ;;
    --description) DESCRIPTION="${2:-}"; shift 2 ;;
    --pve-host) PVE_HOST="${2:-}"; shift 2 ;;
    --core-vmid) CORE_VMID="${2:-}"; shift 2 ;;
    --talk-vmid) TALK_VMID="${2:-}"; shift 2 ;;
    --core-only) INCLUDE_CORE=1; INCLUDE_TALK=0; shift ;;
    --talk-only) INCLUDE_CORE=0; INCLUDE_TALK=1; shift ;;
    --help|-h) usage; exit 0 ;;
    *) runbook_fail "Unknown argument: $1" ;;
  esac
done

[ "$INCLUDE_CORE" = "1" ] || [ "$INCLUDE_TALK" = "1" ] || runbook_fail "nothing selected to snapshot"
[ -n "$PVE_HOST" ] || runbook_fail "pve host is required"
[ -n "$CHANGE_ID" ] || runbook_fail "change id is required"

if [ -z "$TAG" ]; then
  stamp="$(date +%Y%m%d-%H%M%S)"
  TAG="pre-${CHANGE_ID}-${stamp}"
fi
TAG="${TAG// /-}"

if [ -z "$DESCRIPTION" ]; then
  DESCRIPTION="pre-change snapshot for ${CHANGE_ID}"
fi
DESC_ESCAPED="$(printf "%s" "$DESCRIPTION" | sed "s/'/'\"'\"'/g")"

run_snapshot() {
  local vmid="$1"
  local label="$2"
  echo "[INFO] Snapshotting ${label} VM ${vmid} on ${PVE_HOST} with tag ${TAG}"
  ssh "root@${PVE_HOST}" "set -eu;
    qm status '${vmid}' >/dev/null 2>&1 || { echo 'vm not found: ${vmid}' >&2; exit 1; }
    qm snapshot '${vmid}' '${TAG}' --description '${DESC_ESCAPED}' --vmstate 0"
}

if [ "$INCLUDE_CORE" = "1" ]; then
  run_snapshot "$CORE_VMID" "nextcloud-core"
fi
if [ "$INCLUDE_TALK" = "1" ]; then
  run_snapshot "$TALK_VMID" "talk-hpb"
fi

echo "[OK] Snapshot complete. tag=${TAG}"
