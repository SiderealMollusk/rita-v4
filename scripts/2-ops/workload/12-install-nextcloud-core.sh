#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../lib/runbook.sh"

runbook_require_no_args "$@"
REPO_ROOT="$(runbook_detect_repo_root)"
PB="$REPO_ROOT/ops/ansible/playbooks/33-install-nextcloud-core.yml"
GROUP_VARS="$REPO_ROOT/ops/ansible/group_vars/nextcloud.yml"
INSTANCES_FILE="$REPO_ROOT/ops/nextcloud/instances.yaml"

[ -f "$GROUP_VARS" ] || runbook_fail "missing group vars file at $GROUP_VARS"
[ -f "$INSTANCES_FILE" ] || runbook_fail "missing nextcloud instances file at $INSTANCES_FILE"
runbook_source_labrc "${REPO_ROOT}"
NEXTCLOUD_SNAPSHOT_MODE="${NEXTCLOUD_SNAPSHOT_MODE:-critical}"
if [ -n "${NEXTCLOUD_AUTO_SNAPSHOT_PRE:-}" ]; then
  if [ "${NEXTCLOUD_AUTO_SNAPSHOT_PRE}" = "1" ]; then
    NEXTCLOUD_SNAPSHOT_MODE="critical"
  else
    NEXTCLOUD_SNAPSHOT_MODE="off"
  fi
fi

NEXTCLOUD_OP_ITEM="${NEXTCLOUD_OP_ITEM:-nextcloud-main}"
NEXTCLOUD_ADMIN_PASSWORD_FIELD="${NEXTCLOUD_ADMIN_PASSWORD_FIELD:-nextcloud-admin}"
NEXTCLOUD_DB_PASSWORD_FIELD="${NEXTCLOUD_DB_PASSWORD_FIELD:-nextcloud-db}"

instance_row="$(python3 - "$INSTANCES_FILE" <<'PY'
import json, sys
path = sys.argv[1]
with open(path, "r", encoding="utf-8") as f:
    obj = json.load(f)
official = obj.get("official_instance", "")
instances = obj.get("instances", {})
inst = instances.get(official, {})
print("\t".join([
    str(official),
    str(inst.get("display_name", "")),
    str(inst.get("connector_mode", "")),
    str(inst.get("inventory_file", "")),
    str(inst.get("domain", "")),
]))
PY
)"

IFS=$'\t' read -r NEXTCLOUD_OFFICIAL_INSTANCE NEXTCLOUD_OFFICIAL_DISPLAY NEXTCLOUD_OFFICIAL_MODE NEXTCLOUD_OFFICIAL_INV_REL NEXTCLOUD_OFFICIAL_DOMAIN <<<"$instance_row"

[ -n "$NEXTCLOUD_OFFICIAL_INSTANCE" ] || runbook_fail "official_instance missing in $INSTANCES_FILE"
[ -n "$NEXTCLOUD_OFFICIAL_INV_REL" ] || runbook_fail "official instance inventory_file missing in $INSTANCES_FILE"
[ "$NEXTCLOUD_OFFICIAL_MODE" = "vm" ] || runbook_fail "official instance '$NEXTCLOUD_OFFICIAL_INSTANCE' is not vm-backed (mode=$NEXTCLOUD_OFFICIAL_MODE); this runbook targets dedicated VM installs only"

INV="$REPO_ROOT/$NEXTCLOUD_OFFICIAL_INV_REL"
[ -f "$INV" ] || runbook_fail "official inventory path does not exist: $INV"

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

NEXTCLOUD_DOMAIN="${NEXTCLOUD_DOMAIN:-$NEXTCLOUD_OFFICIAL_DOMAIN}"
[ -n "$NEXTCLOUD_DOMAIN" ] || runbook_fail "NEXTCLOUD_DOMAIN resolved empty; set it explicitly or provide domain in $INSTANCES_FILE"

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
echo "[INFO] Official Nextcloud instance key: ${NEXTCLOUD_OFFICIAL_INSTANCE}"
echo "[INFO] Official Nextcloud instance name: ${NEXTCLOUD_OFFICIAL_DISPLAY}"
echo "[INFO] Using Nextcloud domain: ${NEXTCLOUD_DOMAIN}"
echo "[INFO] Using inventory: ${INV}"
echo "[INFO] Using admin user: ${NEXTCLOUD_ADMIN_USER}"
if [ -n "${NEXTCLOUD_ADMIN_PASSWORD_OP_REF:-}" ]; then
  echo "[INFO] Using admin password ref: ${NEXTCLOUD_ADMIN_PASSWORD_OP_REF}"
fi
if [ -n "${NEXTCLOUD_DB_PASSWORD_OP_REF:-}" ]; then
  echo "[INFO] Using DB password ref: ${NEXTCLOUD_DB_PASSWORD_OP_REF}"
fi

if [ "${NEXTCLOUD_SNAPSHOT_MODE}" = "critical" ]; then
  echo "[INFO] Creating pre-change Nextcloud VM pair snapshot"
  NEXTCLOUD_SNAPSHOT_CHANGE_ID="12-install-nextcloud-core" \
    "${REPO_ROOT}/scripts/2-ops/workload/35-snapshot-nextcloud-pair.sh"
fi

ansible-playbook -i "$INV" "$PB" -e "@$GROUP_VARS"
