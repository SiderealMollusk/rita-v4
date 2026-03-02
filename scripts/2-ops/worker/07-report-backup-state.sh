#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../lib/runbook.sh"

runbook_require_no_args "$@"
REPO_ROOT="$(runbook_detect_repo_root)"
BACKUP_STATE_FILE="$REPO_ROOT/ops/gitops/platform/backup-state/services.tsv"

[ -f "$BACKUP_STATE_FILE" ] || runbook_fail "backup state file not found: $BACKUP_STATE_FILE"

echo "[INFO] Declared backup state"
awk -F '\t' '
NR == 1 { next }
{
  printf "- %s (%s): stateful=%s, data_class=%s, backup_target=%s, backup_implemented=%s, notes=%s\n",
    $1, $2, $3, $4, $6, $7, $8
}
' "$BACKUP_STATE_FILE"
