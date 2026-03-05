#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../lib/runbook.sh"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../lib/pangolin-site-credentials.sh"

runbook_require_no_args "$@"
runbook_require_host_terminal
runbook_require_op_write_access
runbook_source_labrc "$REPO_ROOT"

OBSERVATORY_VARS="$REPO_ROOT/ops/ansible/group_vars/observatory.yml"
SITE_LIST_FILE="$REPO_ROOT/ops/pangolin/sites/observatory-site-slugs.txt"

[ -f "$OBSERVATORY_VARS" ] || runbook_fail "missing group vars file at $OBSERVATORY_VARS"
[ -f "$SITE_LIST_FILE" ] || runbook_fail "missing site list file at $SITE_LIST_FILE"

VAULT_ID="$(runbook_yaml_get "$OBSERVATORY_VARS" "pangolin_newt_credentials_vault_id" || true)"
ITEM_PREFIX="$(runbook_yaml_get "$OBSERVATORY_VARS" "pangolin_newt_credentials_item_prefix" || true)"

[ -n "$VAULT_ID" ] || runbook_fail "pangolin_newt_credentials_vault_id missing in $OBSERVATORY_VARS"
[ -n "$ITEM_PREFIX" ] || runbook_fail "pangolin_newt_credentials_item_prefix missing in $OBSERVATORY_VARS"

slug_count=0
while IFS= read -r site_slug; do
  case "$site_slug" in
    ""|\#*) continue ;;
  esac
  slug_count=$((slug_count + 1))
  site_name="${site_slug//_/-}"
  item_title="${ITEM_PREFIX}${site_slug}"

  echo
  echo "[INFO] >>> Processing site slug: $site_slug"
  while true; do
    read -r -p "Action for ${site_slug}? [enter=process, s=skip, q=quit]: " action
    case "${action:-}" in
      "")
        break
        ;;
      s|S|skip|SKIP)
        echo "[INFO] Skipping ${site_slug}"
        continue 2
        ;;
      q|Q|quit|QUIT)
        runbook_fail "operator aborted at site slug ${site_slug}"
        ;;
      *)
        echo "[WARN] Invalid action '${action}'. Use enter, s, or q."
        ;;
    esac
  done
  runbook_register_pangolin_site_credentials "$REPO_ROOT" "$site_slug" "$site_name" "$item_title" "$VAULT_ID"
done < "$SITE_LIST_FILE"

[ "$slug_count" -gt 0 ] || runbook_fail "no site slugs found in $SITE_LIST_FILE"
echo
echo "[OK] Completed site credential registration for ${slug_count} site(s)."
