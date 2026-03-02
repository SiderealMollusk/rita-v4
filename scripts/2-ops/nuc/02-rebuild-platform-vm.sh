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
PROXMOX_PLATFORM_NAME="${PROXMOX_PLATFORM_NAME:-$(runbook_yaml_get "$HV" platform_nuc_worker_vm_name)}"
PROXMOX_PLATFORM_IP_CIDR="${PROXMOX_PLATFORM_IP_CIDR:-$(runbook_yaml_get "$HV" platform_nuc_worker_ip_cidr)}"
PROXMOX_PLATFORM_GATEWAY="${PROXMOX_PLATFORM_GATEWAY:-$(runbook_yaml_get "$HV" platform_nuc_worker_gateway)}"
PROXMOX_PLATFORM_CORES="${PROXMOX_PLATFORM_CORES:-$(runbook_yaml_get "$HV" platform_nuc_worker_cores)}"
PROXMOX_PLATFORM_MEMORY_MB="${PROXMOX_PLATFORM_MEMORY_MB:-$(runbook_yaml_get "$HV" platform_nuc_worker_memory_mb)}"
PROXMOX_PLATFORM_DISK_GB="${PROXMOX_PLATFORM_DISK_GB:-$(runbook_yaml_get "$HV" platform_nuc_worker_disk_gb)}"
PROXMOX_PLATFORM_BRIDGE="${PROXMOX_PLATFORM_BRIDGE:-$(runbook_yaml_get "$HV" platform_nuc_worker_bridge)}"
PROXMOX_PLATFORM_CIUSER="${PROXMOX_PLATFORM_CIUSER:-$(runbook_yaml_get "$HV" platform_nuc_worker_ciuser)}"
PROXMOX_PLATFORM_SSH_PUBKEY_PATH="${PROXMOX_PLATFORM_SSH_PUBKEY_PATH:-$(runbook_yaml_get "$HV" platform_nuc_worker_ssh_pubkey_path)}"
PROXMOX_PLATFORM_NAMESERVER="${PROXMOX_PLATFORM_NAMESERVER:-$(runbook_yaml_get "$HV" platform_nuc_worker_nameserver)}"

[ -n "$PROXMOX_ROOT_HOST" ] || runbook_fail "Could not resolve platform-nuc ansible_host from $INV"
[ -n "$PROXMOX_TEMPLATE_VM_ID" ] || runbook_fail "Missing platform_nuc_template_vm_id in $HV"
[ -n "$PROXMOX_PLATFORM_VM_ID" ] || runbook_fail "Missing platform_nuc_worker_vm_id in $HV"
[ -n "$PROXMOX_PLATFORM_NAME" ] || runbook_fail "Missing platform_nuc_worker_vm_name in $HV"
[ -n "$PROXMOX_PLATFORM_IP_CIDR" ] || runbook_fail "Missing platform_nuc_worker_ip_cidr in $HV"
[ -n "$PROXMOX_PLATFORM_GATEWAY" ] || runbook_fail "Missing platform_nuc_worker_gateway in $HV"
[ -n "$PROXMOX_PLATFORM_SSH_PUBKEY_PATH" ] || runbook_fail "Missing platform_nuc_worker_ssh_pubkey_path in $HV"
[ "$PROXMOX_PLATFORM_GATEWAY" != "REPLACE_WITH_PLATFORM_GATEWAY" ] || runbook_fail "Update platform_nuc_worker_gateway in $HV before rebuilding."

PROXMOX_PLATFORM_SSH_PUBKEY_PATH="${PROXMOX_PLATFORM_SSH_PUBKEY_PATH/#\~/$HOME}"
[ -f "$PROXMOX_PLATFORM_SSH_PUBKEY_PATH" ] || runbook_fail "SSH public key file not found: $PROXMOX_PLATFORM_SSH_PUBKEY_PATH"

if [ "${PROXMOX_REBUILD_CONFIRM:-}" != "platform-vm-worker-9200" ]; then
  runbook_fail "Set PROXMOX_REBUILD_CONFIRM=platform-vm-worker-9200 before rebuilding VM ${PROXMOX_PLATFORM_VM_ID}."
fi

echo "[INFO] Rebuilding VM ${PROXMOX_PLATFORM_VM_ID} as ${PROXMOX_PLATFORM_NAME}"

ssh "root@${PROXMOX_ROOT_HOST}" "
  set -euo pipefail
  if qm status ${PROXMOX_PLATFORM_VM_ID} >/dev/null 2>&1; then
    qm stop ${PROXMOX_PLATFORM_VM_ID} --skiplock 1 >/dev/null 2>&1 || true
    qm destroy ${PROXMOX_PLATFORM_VM_ID} --destroy-unreferenced-disks 1 --purge 1
  fi

  qm clone ${PROXMOX_TEMPLATE_VM_ID} ${PROXMOX_PLATFORM_VM_ID} --name ${PROXMOX_PLATFORM_NAME} --full 1
  qm set ${PROXMOX_PLATFORM_VM_ID} --cores ${PROXMOX_PLATFORM_CORES} --memory ${PROXMOX_PLATFORM_MEMORY_MB}
  qm set ${PROXMOX_PLATFORM_VM_ID} --net0 virtio,bridge=${PROXMOX_PLATFORM_BRIDGE}
  qm resize ${PROXMOX_PLATFORM_VM_ID} scsi0 ${PROXMOX_PLATFORM_DISK_GB}G
  qm set ${PROXMOX_PLATFORM_VM_ID} --ciuser ${PROXMOX_PLATFORM_CIUSER}
  qm set ${PROXMOX_PLATFORM_VM_ID} --ipconfig0 ip=${PROXMOX_PLATFORM_IP_CIDR},gw=${PROXMOX_PLATFORM_GATEWAY}
  qm set ${PROXMOX_PLATFORM_VM_ID} --nameserver ${PROXMOX_PLATFORM_NAMESERVER}
"

cat "$PROXMOX_PLATFORM_SSH_PUBKEY_PATH" | ssh "root@${PROXMOX_ROOT_HOST}" "
  set -euo pipefail
  tmp_key=\$(mktemp)
  cat > \"\$tmp_key\"
  qm set ${PROXMOX_PLATFORM_VM_ID} --sshkeys \"\$tmp_key\"
  rm -f \"\$tmp_key\"
  qm start ${PROXMOX_PLATFORM_VM_ID}
  qm config ${PROXMOX_PLATFORM_VM_ID}
"
