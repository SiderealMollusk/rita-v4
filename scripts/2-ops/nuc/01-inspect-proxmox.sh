#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../lib/runbook.sh"

runbook_require_no_args "$@"
runbook_require_host_terminal
REPO_ROOT="$(runbook_detect_repo_root)"
INV="$REPO_ROOT/ops/ansible/inventory/proxmox.ini"
HV="$REPO_ROOT/ops/ansible/host_vars/platform-nuc.yml"

[ -f "$INV" ] || runbook_fail "inventory not found: $INV"
[ -f "$HV" ] || runbook_fail "host vars not found: $HV"

PROXMOX_ROOT_HOST="$(runbook_inventory_get_field "$INV" "platform-nuc" "ansible_host")"
PROXMOX_TEMPLATE_VM_ID="${PROXMOX_TEMPLATE_VM_ID:-$(runbook_yaml_get "$HV" platform_nuc_template_vm_id)}"
PROXMOX_PLATFORM_VM_ID="${PROXMOX_PLATFORM_VM_ID:-$(runbook_yaml_get "$HV" platform_nuc_worker_vm_id)}"
PROXMOX_REFERENCE_VM_ID="${PROXMOX_REFERENCE_VM_ID:-$(runbook_yaml_get "$HV" platform_nuc_newt_vm_id)}"

[ -n "$PROXMOX_ROOT_HOST" ] || runbook_fail "Could not resolve platform-nuc ansible_host from $INV"
[ -n "$PROXMOX_TEMPLATE_VM_ID" ] || runbook_fail "Missing platform_nuc_template_vm_id in $HV"
[ -n "$PROXMOX_PLATFORM_VM_ID" ] || runbook_fail "Missing platform_nuc_worker_vm_id in $HV"
[ -n "$PROXMOX_REFERENCE_VM_ID" ] || runbook_fail "Missing platform_nuc_newt_vm_id in $HV"

echo "[INFO] Inspecting Proxmox host ${PROXMOX_ROOT_HOST}"
ssh "root@${PROXMOX_ROOT_HOST}" "
  set -euo pipefail
  echo '== host =='
  hostname
  uptime
  echo
  echo '== services =='
  systemctl is-active pveproxy pvedaemon pvestatd
  echo
  echo '== guests =='
  qm list
  pct list || true
  echo
  echo '== vm ${PROXMOX_REFERENCE_VM_ID} =='
  qm config ${PROXMOX_REFERENCE_VM_ID} || true
  echo
  echo '== vm ${PROXMOX_PLATFORM_VM_ID} =='
  qm config ${PROXMOX_PLATFORM_VM_ID} || true
  echo
  echo '== template ${PROXMOX_TEMPLATE_VM_ID} =='
  qm config ${PROXMOX_TEMPLATE_VM_ID} || true
  echo
  echo '== storage =='
  pvesm status
  echo
  echo '== memory =='
  free -h
  echo
  echo '== cpu =='
  nproc
  lscpu | egrep 'Model name|Socket|Core|Thread' || true
  echo
  echo '== network =='
  qm config ${PROXMOX_REFERENCE_VM_ID} | egrep 'net0|ipconfig0|nameserver' || true
  qm config ${PROXMOX_PLATFORM_VM_ID} | egrep 'net0|ipconfig0|nameserver' || true
  echo
  ip -4 addr show
"
