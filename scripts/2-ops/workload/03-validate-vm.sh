#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../lib/runbook.sh"

runbook_require_no_args "$@"
runbook_require_host_terminal
runbook_require_cmd ssh
runbook_require_cmd ssh-keyscan
REPO_ROOT="$(runbook_detect_repo_root)"
PROXMOX_INV="$REPO_ROOT/ops/ansible/inventory/proxmox.ini"
WORKLOAD_INV="$REPO_ROOT/ops/ansible/inventory/workload.ini"
HV="$REPO_ROOT/ops/ansible/host_vars/workload-pve.yml"
WORKLOAD_VARS="$REPO_ROOT/ops/ansible/group_vars/workload.yml"

[ -f "$PROXMOX_INV" ] || runbook_fail "inventory not found: $PROXMOX_INV"
[ -f "$WORKLOAD_INV" ] || runbook_fail "inventory not found: $WORKLOAD_INV"
[ -f "$HV" ] || runbook_fail "host vars not found: $HV"
[ -f "$WORKLOAD_VARS" ] || runbook_fail "group vars not found: $WORKLOAD_VARS"

PROXMOX_ROOT_HOST="$(runbook_inventory_get_field "$PROXMOX_INV" "workload-pve" "ansible_host")"
WORKLOAD_VM_HOST="$(runbook_inventory_get_field "$WORKLOAD_INV" "workload-vm-worker" "ansible_host")"
WORKLOAD_VM_USER="$(runbook_inventory_get_field "$WORKLOAD_INV" "workload-vm-worker" "ansible_user")"
WORKLOAD_VM_ID="$(runbook_yaml_get "$HV" workload_pve_worker_vm_id)"
WORKLOAD_EXPECTED_HOSTNAME="$(runbook_yaml_get "$WORKLOAD_VARS" workload_expected_hostname)"
WORKLOAD_EXPECTED_GATEWAY="$(runbook_yaml_get "$HV" workload_pve_worker_gateway)"
WORKLOAD_EXPECTED_IP_CIDR="$(runbook_yaml_get "$HV" workload_pve_worker_ip_cidr)"

[ -n "$PROXMOX_ROOT_HOST" ] || runbook_fail "Could not resolve workload-pve ansible_host from $PROXMOX_INV"
[ -n "$WORKLOAD_VM_HOST" ] || runbook_fail "Could not resolve workload-vm-worker ansible_host from $WORKLOAD_INV"
[ -n "$WORKLOAD_VM_USER" ] || runbook_fail "Could not resolve workload-vm-worker ansible_user from $WORKLOAD_INV"
[ -n "$WORKLOAD_VM_ID" ] || runbook_fail "Missing workload_pve_worker_vm_id in $HV"
[ -n "$WORKLOAD_EXPECTED_HOSTNAME" ] || runbook_fail "Missing workload_expected_hostname in $WORKLOAD_VARS"
[ -n "$WORKLOAD_EXPECTED_GATEWAY" ] || runbook_fail "Missing workload_pve_worker_gateway in $HV"
[ -n "$WORKLOAD_EXPECTED_IP_CIDR" ] || runbook_fail "Missing workload_pve_worker_ip_cidr in $HV"

runbook_refresh_known_hosts_from_inventory "$WORKLOAD_INV"

echo "[INFO] Verifying Proxmox reports VM ${WORKLOAD_VM_ID} as running"
VM_STATUS="$(ssh "root@${PROXMOX_ROOT_HOST}" "qm status ${WORKLOAD_VM_ID} | awk '{print \$2}'")"
[ "$VM_STATUS" = "running" ] || runbook_fail "VM ${WORKLOAD_VM_ID} is not running (status=${VM_STATUS})."

echo "[INFO] Checking guest agent availability"
if ssh "root@${PROXMOX_ROOT_HOST}" "qm guest cmd ${WORKLOAD_VM_ID} network-get-interfaces" >/dev/null 2>&1; then
  echo "[INFO] Guest agent responded"
  GUEST_AGENT_READY="yes"
else
  echo "[INFO] Guest agent did not respond yet; continuing with SSH-based validation"
  GUEST_AGENT_READY="no"
fi

echo "[INFO] Waiting for SSH on ${WORKLOAD_VM_HOST}:22"
for _ in $(seq 1 60); do
  if ssh-keyscan -H "$WORKLOAD_VM_HOST" >/dev/null 2>&1; then
    break
  fi
  sleep 2
done
ssh-keyscan -H "$WORKLOAD_VM_HOST" >/dev/null 2>&1 || runbook_fail "SSH did not become reachable on ${WORKLOAD_VM_HOST}:22."

echo "[INFO] Validating in-guest hostname, cloud-init, SSH, guest agent, and route"
VALIDATION_OUTPUT="$(ssh "${WORKLOAD_VM_USER}@${WORKLOAD_VM_HOST}" "
  set -euo pipefail
  hostname
  cloud-init status --wait >/dev/null
  systemctl is-active ssh >/dev/null
  if systemctl is-active qemu-guest-agent >/dev/null 2>&1; then
    echo qga=active
  else
    echo qga=inactive
  fi
  ip -4 addr show
  ip route
")"

printf '%s\n' "$VALIDATION_OUTPUT" | grep -qx "${WORKLOAD_EXPECTED_HOSTNAME}" || runbook_fail "Guest hostname did not match expected '${WORKLOAD_EXPECTED_HOSTNAME}'."
printf '%s\n' "$VALIDATION_OUTPUT" | grep -q "${WORKLOAD_EXPECTED_GATEWAY}" || runbook_fail "Guest route output did not include expected gateway '${WORKLOAD_EXPECTED_GATEWAY}'."
printf '%s\n' "$VALIDATION_OUTPUT" | grep -q "${WORKLOAD_VM_HOST}" || runbook_fail "Guest network output did not include expected host IP '${WORKLOAD_VM_HOST}'."

if printf '%s\n' "$VALIDATION_OUTPUT" | grep -q '^qga=inactive$'; then
  echo "[WARN] qemu-guest-agent is not active inside the guest yet."
fi

if [ "$GUEST_AGENT_READY" != "yes" ]; then
  echo "[WARN] Proxmox guest agent did not respond during validation."
fi

echo "[INFO] Workload VM validation passed"
echo "[INFO] Expected IP/CIDR: ${WORKLOAD_EXPECTED_IP_CIDR}"
echo "[INFO] Expected gateway: ${WORKLOAD_EXPECTED_GATEWAY}"
