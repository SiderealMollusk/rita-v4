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
[ -f "$OBSERVATORY_VARS" ] || runbook_fail "missing group vars file at $OBSERVATORY_VARS"

VAULT_ID="$(runbook_yaml_get "$OBSERVATORY_VARS" "pangolin_newt_credentials_vault_id" || true)"
SITE_SLUG="$(runbook_yaml_get "$OBSERVATORY_VARS" "pangolin_newt_site_slug" || true)"
SITE_NAME="$(runbook_yaml_get "$OBSERVATORY_VARS" "pangolin_newt_site_name" || true)"
ITEM_TITLE="$(runbook_yaml_get "$OBSERVATORY_VARS" "pangolin_newt_credentials_item" || true)"

[ -n "$VAULT_ID" ] || runbook_fail "pangolin_newt_credentials_vault_id missing in $OBSERVATORY_VARS"
[ -n "$SITE_SLUG" ] || runbook_fail "pangolin_newt_site_slug missing in $OBSERVATORY_VARS"
[ -n "$SITE_NAME" ] || runbook_fail "pangolin_newt_site_name missing in $OBSERVATORY_VARS"
[ -n "$ITEM_TITLE" ] || runbook_fail "pangolin_newt_credentials_item missing in $OBSERVATORY_VARS"

runbook_register_pangolin_site_credentials "$REPO_ROOT" "$SITE_SLUG" "$SITE_NAME" "$ITEM_TITLE" "$VAULT_ID"
