#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../lib/runbook.sh"

runbook_require_no_args "$@"
runbook_require_host_terminal
runbook_require_cmd ssh-keyscan

REPO_ROOT="$(runbook_detect_repo_root)"
INV="$REPO_ROOT/ops/ansible/inventory/proxmox.ini"
VM_INV="$REPO_ROOT/ops/ansible/inventory/nextcloud.ini"
HV="$REPO_ROOT/ops/ansible/host_vars/workload-pve.yml"

[ -f "$INV" ] || runbook_fail "inventory not found: $INV"
[ -f "$VM_INV" ] || runbook_fail "inventory not found: $VM_INV"
[ -f "$HV" ] || runbook_fail "host vars not found: $HV"

PROXMOX_ROOT_HOST="$(runbook_inventory_get_field "$INV" "workload-pve" "ansible_host")"
TEMPLATE_VM_ID="${PROXMOX_TEMPLATE_VM_ID:-$(runbook_yaml_get "$HV" workload_pve_template_vm_id)}"
TARGET_VM_ID="${PROXMOX_NEXTCLOUD_VM_ID:-$(runbook_yaml_get "$HV" workload_pve_nextcloud_vm_id)}"
TARGET_VM_NAME="${PROXMOX_NEXTCLOUD_VM_NAME:-$(runbook_yaml_get "$HV" workload_pve_nextcloud_vm_name)}"
TARGET_VM_IP_CIDR="${PROXMOX_NEXTCLOUD_VM_IP_CIDR:-$(runbook_yaml_get "$HV" workload_pve_nextcloud_ip_cidr)}"
TARGET_VM_GATEWAY="${PROXMOX_NEXTCLOUD_VM_GATEWAY:-$(runbook_yaml_get "$HV" workload_pve_nextcloud_gateway)}"
TARGET_VM_CORES="${PROXMOX_NEXTCLOUD_VM_CORES:-$(runbook_yaml_get "$HV" workload_pve_nextcloud_cores)}"
TARGET_VM_MEMORY_MB="${PROXMOX_NEXTCLOUD_VM_MEMORY_MB:-$(runbook_yaml_get "$HV" workload_pve_nextcloud_memory_mb)}"
TARGET_VM_DISK_GB="${PROXMOX_NEXTCLOUD_VM_DISK_GB:-$(runbook_yaml_get "$HV" workload_pve_nextcloud_disk_gb)}"
TARGET_VM_BRIDGE="${PROXMOX_NEXTCLOUD_VM_BRIDGE:-$(runbook_yaml_get "$HV" workload_pve_nextcloud_bridge)}"
TARGET_VM_CIUSER="${PROXMOX_NEXTCLOUD_VM_CIUSER:-$(runbook_yaml_get "$HV" workload_pve_nextcloud_ciuser)}"
TARGET_VM_SSH_PUBKEY_PATH="${PROXMOX_NEXTCLOUD_VM_SSH_PUBKEY_PATH:-$(runbook_yaml_get "$HV" workload_pve_nextcloud_ssh_pubkey_path)}"
TARGET_VM_NAMESERVER="${PROXMOX_NEXTCLOUD_VM_NAMESERVER:-$(runbook_yaml_get "$HV" workload_pve_nextcloud_nameserver)}"

[ -n "$PROXMOX_ROOT_HOST" ] || runbook_fail "Could not resolve workload-pve ansible_host from $INV"
[ -n "$TEMPLATE_VM_ID" ] || runbook_fail "Missing workload_pve_template_vm_id in $HV"
[ -n "$TARGET_VM_ID" ] || runbook_fail "Missing workload_pve_nextcloud_vm_id in $HV"
[ -n "$TARGET_VM_NAME" ] || runbook_fail "Missing workload_pve_nextcloud_vm_name in $HV"
[ -n "$TARGET_VM_IP_CIDR" ] || runbook_fail "Missing workload_pve_nextcloud_ip_cidr in $HV"
[ -n "$TARGET_VM_GATEWAY" ] || runbook_fail "Missing workload_pve_nextcloud_gateway in $HV"
[ -n "$TARGET_VM_SSH_PUBKEY_PATH" ] || runbook_fail "Missing workload_pve_nextcloud_ssh_pubkey_path in $HV"

TARGET_VM_SSH_PUBKEY_PATH="${TARGET_VM_SSH_PUBKEY_PATH/#\~/$HOME}"
[ -f "$TARGET_VM_SSH_PUBKEY_PATH" ] || runbook_fail "SSH public key file not found: $TARGET_VM_SSH_PUBKEY_PATH"
TARGET_VM_HOST="$(runbook_inventory_get_field "$VM_INV" "nextcloud-vm" "ansible_host")"
[ -n "$TARGET_VM_HOST" ] || runbook_fail "Could not resolve nextcloud-vm ansible_host from $VM_INV"

if [ "${PROXMOX_REBUILD_CONFIRM:-}" != "nextcloud-vm-9301" ]; then
  runbook_fail "Set PROXMOX_REBUILD_CONFIRM=nextcloud-vm-9301 before rebuilding VM ${TARGET_VM_ID}."
fi

echo "[INFO] Rebuilding VM ${TARGET_VM_ID} as ${TARGET_VM_NAME}"

ssh "root@${PROXMOX_ROOT_HOST}" "
  set -euo pipefail
  if qm status ${TARGET_VM_ID} >/dev/null 2>&1; then
    qm stop ${TARGET_VM_ID} --skiplock 1 >/dev/null 2>&1 || true
    qm destroy ${TARGET_VM_ID} --destroy-unreferenced-disks 1 --purge 1
  fi

  qm clone ${TEMPLATE_VM_ID} ${TARGET_VM_ID} --name ${TARGET_VM_NAME} --full 1
  qm set ${TARGET_VM_ID} --cores ${TARGET_VM_CORES} --memory ${TARGET_VM_MEMORY_MB}
  qm set ${TARGET_VM_ID} --net0 virtio,bridge=${TARGET_VM_BRIDGE}
  qm resize ${TARGET_VM_ID} scsi0 ${TARGET_VM_DISK_GB}G
  qm set ${TARGET_VM_ID} --ciuser ${TARGET_VM_CIUSER}
  qm set ${TARGET_VM_ID} --ipconfig0 ip=${TARGET_VM_IP_CIDR},gw=${TARGET_VM_GATEWAY}
  qm set ${TARGET_VM_ID} --nameserver ${TARGET_VM_NAMESERVER}
"

cat "$TARGET_VM_SSH_PUBKEY_PATH" | ssh "root@${PROXMOX_ROOT_HOST}" "
  set -euo pipefail
  tmp_key=\$(mktemp)
  cat > \"\$tmp_key\"
  qm set ${TARGET_VM_ID} --sshkeys \"\$tmp_key\"
  rm -f \"\$tmp_key\"
  qm start ${TARGET_VM_ID}
  qm config ${TARGET_VM_ID}
"

echo "[INFO] Waiting for Proxmox to report VM ${TARGET_VM_ID} as running"
for _ in $(seq 1 60); do
  if [ "$(ssh "root@${PROXMOX_ROOT_HOST}" "qm status ${TARGET_VM_ID} | awk '{print \$2}'")" = "running" ]; then
    break
  fi
  sleep 2
done
[ "$(ssh "root@${PROXMOX_ROOT_HOST}" "qm status ${TARGET_VM_ID} | awk '{print \$2}'")" = "running" ] || runbook_fail "VM ${TARGET_VM_ID} did not enter running state."

echo "[INFO] Waiting for guest agent or SSH readiness"
for _ in $(seq 1 90); do
  if ssh "root@${PROXMOX_ROOT_HOST}" "qm guest cmd ${TARGET_VM_ID} network-get-interfaces" >/dev/null 2>&1; then
    echo "[INFO] Guest agent is responding"
    break
  fi
  if ssh-keyscan -H "$TARGET_VM_HOST" >/dev/null 2>&1; then
    echo "[INFO] SSH is responding"
    break
  fi
  sleep 2
done

if ! ssh "root@${PROXMOX_ROOT_HOST}" "qm guest cmd ${TARGET_VM_ID} network-get-interfaces" >/dev/null 2>&1 && \
   ! ssh-keyscan -H "$TARGET_VM_HOST" >/dev/null 2>&1; then
  runbook_fail "VM ${TARGET_VM_ID} started, but neither guest agent nor SSH became ready."
fi

echo "[INFO] Nextcloud VM rebuild completed."
