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
KEEP_PRE="${NEXTCLOUD_SNAPSHOT_KEEP_PRE:-10}"
KEEP_POST="${NEXTCLOUD_SNAPSHOT_KEEP_POST:-10}"
KEEP_DAILY="${NEXTCLOUD_SNAPSHOT_KEEP_DAILY:-3}"
CONFIRM="${NEXTCLOUD_PRUNE_CONFIRM:-}"

usage() {
  cat <<'EOF'
Usage:
  37-prune-nextcloud-snapshots.sh [options]

Options:
  --pve-host <ip-or-host>  Proxmox host (default: 192.168.6.11)
  --core-vmid <id>         Nextcloud core VM ID (default: 9301)
  --talk-vmid <id>         Talk HPB VM ID (default: 9302)
  --keep-pre <n>           Keep newest N "pre-" snapshots per VM (default: 10)
  --keep-post <n>          Keep newest N "post-" snapshots per VM (default: 10)
  --keep-daily <n>         Keep newest N "daily-" snapshots per VM (default: 3)
  --yes                    Set prune confirmation automatically
  --help                   Show help
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --pve-host) PVE_HOST="${2:-}"; shift 2 ;;
    --core-vmid) CORE_VMID="${2:-}"; shift 2 ;;
    --talk-vmid) TALK_VMID="${2:-}"; shift 2 ;;
    --keep-pre) KEEP_PRE="${2:-}"; shift 2 ;;
    --keep-post) KEEP_POST="${2:-}"; shift 2 ;;
    --keep-daily) KEEP_DAILY="${2:-}"; shift 2 ;;
    --yes) CONFIRM="prune-nextcloud-snapshots"; shift ;;
    --help|-h) usage; exit 0 ;;
    *) runbook_fail "Unknown argument: $1" ;;
  esac
done

[ "$CONFIRM" = "prune-nextcloud-snapshots" ] || runbook_fail "set NEXTCLOUD_PRUNE_CONFIRM=prune-nextcloud-snapshots (or pass --yes) to delete snapshots"

run_prune_for_vm() {
  local vmid="$1"
  local keep_pre="$2"
  local keep_post="$3"
  local keep_daily="$4"

  echo "[INFO] Pruning snapshots on VM ${vmid}"
  ssh "root@${PVE_HOST}" "set -eu
list=\$(qm listsnapshot '${vmid}' | awk 'NR>1 && \$1 !~ /^->/ && \$1 != \"current\" && \$1 != \"Name\" {print \$1}' || true)

prune_prefix() {
  prefix=\"\$1\"
  keep=\"\$2\"
  [ \"\$keep\" -ge 0 ] || keep=0
  names=\$(printf '%s\n' \"\$list\" | grep -E \"^\${prefix}\" || true)
  [ -n \"\$names\" ] || return 0
  count=\$(printf '%s\n' \"\$names\" | sed '/^$/d' | wc -l | tr -d ' ')
  [ \"\$count\" -gt \"\$keep\" ] || return 0
  remove=\$((count-keep))
  printf '%s\n' \"\$names\" | sort | head -n \"\$remove\" | while read -r snap; do
    [ -n \"\$snap\" ] || continue
    echo \"[INFO] deleting snapshot \$snap from vm ${vmid}\"
    qm delsnapshot '${vmid}' \"\$snap\" --force 1
  done
}

prune_prefix 'pre-' '${keep_pre}'
prune_prefix 'post-' '${keep_post}'
prune_prefix 'daily-' '${keep_daily}'
"
}

run_prune_for_vm "$CORE_VMID" "$KEEP_PRE" "$KEEP_POST" "$KEEP_DAILY"
run_prune_for_vm "$TALK_VMID" "$KEEP_PRE" "$KEEP_POST" "$KEEP_DAILY"

echo "[OK] Snapshot prune complete."
