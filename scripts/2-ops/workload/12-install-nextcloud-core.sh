#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../lib/runbook.sh"

runbook_require_no_args "$@"
REPO_ROOT="$(runbook_detect_repo_root)"
INV="$REPO_ROOT/ops/ansible/inventory/nextcloud.ini"
PB="$REPO_ROOT/ops/ansible/playbooks/33-install-nextcloud-core.yml"
GROUP_VARS="$REPO_ROOT/ops/ansible/group_vars/nextcloud.yml"

[ -f "$GROUP_VARS" ] || runbook_fail "missing group vars file at $GROUP_VARS"
runbook_source_labrc "${REPO_ROOT}"

NEXTCLOUD_OP_ITEM="${NEXTCLOUD_OP_ITEM:-nextcloud-main}"
NEXTCLOUD_ADMIN_PASSWORD_FIELD="${NEXTCLOUD_ADMIN_PASSWORD_FIELD:-nextcloud-admin}"
NEXTCLOUD_DB_PASSWORD_FIELD="${NEXTCLOUD_DB_PASSWORD_FIELD:-nextcloud-db}"

if [ -z "${NEXTCLOUD_ADMIN_PASSWORD_OP_REF:-}" ] && [ -n "${OP_VAULT_ID:-}" ]; then
  NEXTCLOUD_ADMIN_PASSWORD_OP_REF="$(runbook_build_op_ref "${OP_VAULT_ID}" "${NEXTCLOUD_OP_ITEM}" "${NEXTCLOUD_ADMIN_PASSWORD_FIELD}")"
fi

if [ -z "${NEXTCLOUD_DB_PASSWORD_OP_REF:-}" ] && [ -n "${OP_VAULT_ID:-}" ]; then
  NEXTCLOUD_DB_PASSWORD_OP_REF="$(runbook_build_op_ref "${OP_VAULT_ID}" "${NEXTCLOUD_OP_ITEM}" "${NEXTCLOUD_DB_PASSWORD_FIELD}")"
fi

if [ -z "${NEXTCLOUD_ADMIN_USER:-}" ]; then
  NEXTCLOUD_ADMIN_USER="${USER:-virgil}"
fi

runbook_require_env "NEXTCLOUD_ADMIN_USER" "Put NEXTCLOUD_ADMIN_USER in .envrc.local if you do not want the shell user default."

NEXTCLOUD_DOMAIN="${NEXTCLOUD_DOMAIN:-cloud.virgil.info}"

if [ -z "${NEXTCLOUD_ADMIN_PASSWORD:-}" ]; then
  [ -n "${NEXTCLOUD_ADMIN_PASSWORD_OP_REF:-}" ] || runbook_fail "Set NEXTCLOUD_ADMIN_PASSWORD or NEXTCLOUD_ADMIN_PASSWORD_OP_REF."
  NEXTCLOUD_ADMIN_PASSWORD="$(runbook_resolve_secret_from_op "${NEXTCLOUD_ADMIN_PASSWORD:-}" "${NEXTCLOUD_ADMIN_PASSWORD_OP_REF}")"
fi

if [ -z "${NEXTCLOUD_DB_PASSWORD:-}" ]; then
  [ -n "${NEXTCLOUD_DB_PASSWORD_OP_REF:-}" ] || runbook_fail "Set NEXTCLOUD_DB_PASSWORD or NEXTCLOUD_DB_PASSWORD_OP_REF."
  NEXTCLOUD_DB_PASSWORD="$(runbook_resolve_secret_from_op "${NEXTCLOUD_DB_PASSWORD:-}" "${NEXTCLOUD_DB_PASSWORD_OP_REF}")"
fi

export NEXTCLOUD_DOMAIN
export NEXTCLOUD_ADMIN_USER
export NEXTCLOUD_ADMIN_PASSWORD
export NEXTCLOUD_DB_PASSWORD

echo "[INFO] Installing nextcloud-core on dedicated VM"
echo "[INFO] Using Nextcloud domain: ${NEXTCLOUD_DOMAIN}"
echo "[INFO] Using admin user: ${NEXTCLOUD_ADMIN_USER}"
if [ -n "${NEXTCLOUD_ADMIN_PASSWORD_OP_REF:-}" ]; then
  echo "[INFO] Using admin password ref: ${NEXTCLOUD_ADMIN_PASSWORD_OP_REF}"
fi
if [ -n "${NEXTCLOUD_DB_PASSWORD_OP_REF:-}" ]; then
  echo "[INFO] Using DB password ref: ${NEXTCLOUD_DB_PASSWORD_OP_REF}"
fi
ansible-playbook -i "$INV" "$PB" -e "@$GROUP_VARS"
