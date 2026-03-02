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
WORKLOAD_INV="$REPO_ROOT/ops/ansible/inventory/workload.ini"
HV="$REPO_ROOT/ops/ansible/host_vars/workload-pve.yml"

[ -f "$INV" ] || runbook_fail "inventory not found: $INV"
[ -f "$WORKLOAD_INV" ] || runbook_fail "inventory not found: $WORKLOAD_INV"
[ -f "$HV" ] || runbook_fail "host vars not found: $HV"

PROXMOX_ROOT_HOST="$(runbook_inventory_get_field "$INV" "workload-pve" "ansible_host")"
PROXMOX_TEMPLATE_VM_ID="${PROXMOX_TEMPLATE_VM_ID:-$(runbook_yaml_get "$HV" workload_pve_template_vm_id)}"
PROXMOX_WORKLOAD_VM_ID="${PROXMOX_WORKLOAD_VM_ID:-$(runbook_yaml_get "$HV" workload_pve_worker_vm_id)}"
PROXMOX_WORKLOAD_NAME="${PROXMOX_WORKLOAD_NAME:-$(runbook_yaml_get "$HV" workload_pve_worker_vm_name)}"
PROXMOX_WORKLOAD_IP_CIDR="${PROXMOX_WORKLOAD_IP_CIDR:-$(runbook_yaml_get "$HV" workload_pve_worker_ip_cidr)}"
PROXMOX_WORKLOAD_GATEWAY="${PROXMOX_WORKLOAD_GATEWAY:-$(runbook_yaml_get "$HV" workload_pve_worker_gateway)}"
PROXMOX_WORKLOAD_CORES="${PROXMOX_WORKLOAD_CORES:-$(runbook_yaml_get "$HV" workload_pve_worker_cores)}"
PROXMOX_WORKLOAD_MEMORY_MB="${PROXMOX_WORKLOAD_MEMORY_MB:-$(runbook_yaml_get "$HV" workload_pve_worker_memory_mb)}"
PROXMOX_WORKLOAD_DISK_GB="${PROXMOX_WORKLOAD_DISK_GB:-$(runbook_yaml_get "$HV" workload_pve_worker_disk_gb)}"
PROXMOX_WORKLOAD_BRIDGE="${PROXMOX_WORKLOAD_BRIDGE:-$(runbook_yaml_get "$HV" workload_pve_worker_bridge)}"
PROXMOX_WORKLOAD_CIUSER="${PROXMOX_WORKLOAD_CIUSER:-$(runbook_yaml_get "$HV" workload_pve_worker_ciuser)}"
PROXMOX_WORKLOAD_SSH_PUBKEY_PATH="${PROXMOX_WORKLOAD_SSH_PUBKEY_PATH:-$(runbook_yaml_get "$HV" workload_pve_worker_ssh_pubkey_path)}"
PROXMOX_WORKLOAD_NAMESERVER="${PROXMOX_WORKLOAD_NAMESERVER:-$(runbook_yaml_get "$HV" workload_pve_worker_nameserver)}"

[ -n "$PROXMOX_ROOT_HOST" ] || runbook_fail "Could not resolve workload-pve ansible_host from $INV"
[ -n "$PROXMOX_TEMPLATE_VM_ID" ] || runbook_fail "Missing workload_pve_template_vm_id in $HV"
[ -n "$PROXMOX_WORKLOAD_VM_ID" ] || runbook_fail "Missing workload_pve_worker_vm_id in $HV"
[ -n "$PROXMOX_WORKLOAD_NAME" ] || runbook_fail "Missing workload_pve_worker_vm_name in $HV"
[ -n "$PROXMOX_WORKLOAD_IP_CIDR" ] || runbook_fail "Missing workload_pve_worker_ip_cidr in $HV"
[ -n "$PROXMOX_WORKLOAD_GATEWAY" ] || runbook_fail "Missing workload_pve_worker_gateway in $HV"
[ -n "$PROXMOX_WORKLOAD_SSH_PUBKEY_PATH" ] || runbook_fail "Missing workload_pve_worker_ssh_pubkey_path in $HV"

PROXMOX_WORKLOAD_SSH_PUBKEY_PATH="${PROXMOX_WORKLOAD_SSH_PUBKEY_PATH/#\~/$HOME}"
[ -f "$PROXMOX_WORKLOAD_SSH_PUBKEY_PATH" ] || runbook_fail "SSH public key file not found: $PROXMOX_WORKLOAD_SSH_PUBKEY_PATH"
WORKLOAD_VM_HOST="$(runbook_inventory_get_field "$WORKLOAD_INV" "workload-vm-worker" "ansible_host")"
[ -n "$WORKLOAD_VM_HOST" ] || runbook_fail "Could not resolve workload-vm-worker ansible_host from $WORKLOAD_INV"

if [ "${PROXMOX_REBUILD_CONFIRM:-}" != "workload-vm-worker-9300" ]; then
  runbook_fail "Set PROXMOX_REBUILD_CONFIRM=workload-vm-worker-9300 before rebuilding VM ${PROXMOX_WORKLOAD_VM_ID}."
fi

echo "[INFO] Rebuilding VM ${PROXMOX_WORKLOAD_VM_ID} as ${PROXMOX_WORKLOAD_NAME}"

ssh "root@${PROXMOX_ROOT_HOST}" "
  set -euo pipefail
  if qm status ${PROXMOX_WORKLOAD_VM_ID} >/dev/null 2>&1; then
    qm stop ${PROXMOX_WORKLOAD_VM_ID} --skiplock 1 >/dev/null 2>&1 || true
    qm destroy ${PROXMOX_WORKLOAD_VM_ID} --destroy-unreferenced-disks 1 --purge 1
  fi

  qm clone ${PROXMOX_TEMPLATE_VM_ID} ${PROXMOX_WORKLOAD_VM_ID} --name ${PROXMOX_WORKLOAD_NAME} --full 1
  qm set ${PROXMOX_WORKLOAD_VM_ID} --cores ${PROXMOX_WORKLOAD_CORES} --memory ${PROXMOX_WORKLOAD_MEMORY_MB}
  qm set ${PROXMOX_WORKLOAD_VM_ID} --net0 virtio,bridge=${PROXMOX_WORKLOAD_BRIDGE}
  qm resize ${PROXMOX_WORKLOAD_VM_ID} scsi0 ${PROXMOX_WORKLOAD_DISK_GB}G
  qm set ${PROXMOX_WORKLOAD_VM_ID} --ciuser ${PROXMOX_WORKLOAD_CIUSER}
  qm set ${PROXMOX_WORKLOAD_VM_ID} --ipconfig0 ip=${PROXMOX_WORKLOAD_IP_CIDR},gw=${PROXMOX_WORKLOAD_GATEWAY}
  qm set ${PROXMOX_WORKLOAD_VM_ID} --nameserver ${PROXMOX_WORKLOAD_NAMESERVER}
"

cat "$PROXMOX_WORKLOAD_SSH_PUBKEY_PATH" | ssh "root@${PROXMOX_ROOT_HOST}" "
  set -euo pipefail
  tmp_key=\$(mktemp)
  cat > \"\$tmp_key\"
  qm set ${PROXMOX_WORKLOAD_VM_ID} --sshkeys \"\$tmp_key\"
  rm -f \"\$tmp_key\"
  qm start ${PROXMOX_WORKLOAD_VM_ID}
  qm config ${PROXMOX_WORKLOAD_VM_ID}
"

echo "[INFO] Waiting for Proxmox to report VM ${PROXMOX_WORKLOAD_VM_ID} as running"
for _ in $(seq 1 60); do
  if [ "$(ssh "root@${PROXMOX_ROOT_HOST}" "qm status ${PROXMOX_WORKLOAD_VM_ID} | awk '{print \$2}'")" = "running" ]; then
    break
  fi
  sleep 2
done
[ "$(ssh "root@${PROXMOX_ROOT_HOST}" "qm status ${PROXMOX_WORKLOAD_VM_ID} | awk '{print \$2}'")" = "running" ] || runbook_fail "VM ${PROXMOX_WORKLOAD_VM_ID} did not enter running state."

echo "[INFO] Waiting for guest agent or SSH readiness"
for _ in $(seq 1 90); do
  if ssh "root@${PROXMOX_ROOT_HOST}" "qm guest cmd ${PROXMOX_WORKLOAD_VM_ID} network-get-interfaces" >/dev/null 2>&1; then
    echo "[INFO] Guest agent is responding"
    break
  fi
  if ssh-keyscan -H "$WORKLOAD_VM_HOST" >/dev/null 2>&1; then
    echo "[INFO] SSH is responding"
    break
  fi
  sleep 2
done

if ! ssh "root@${PROXMOX_ROOT_HOST}" "qm guest cmd ${PROXMOX_WORKLOAD_VM_ID} network-get-interfaces" >/dev/null 2>&1 && \
   ! ssh-keyscan -H "$WORKLOAD_VM_HOST" >/dev/null 2>&1; then
  runbook_fail "VM ${PROXMOX_WORKLOAD_VM_ID} started, but neither guest agent nor SSH became ready."
fi

echo "[INFO] Rebuild phase completed; run scripts/2-ops/workload/03-validate-vm.sh next."
