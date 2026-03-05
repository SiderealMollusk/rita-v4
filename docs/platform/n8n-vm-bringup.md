# n8n Dedicated VM Bring-Up

Freshness stamp: 2026-03-05 (background agent)

## Purpose
This runbook defines the canonical repo path for adding and wiring a dedicated `n8n` VM on `workload-pve`.

It is designed to replace ad hoc host edits with durable inventory, host vars, runbooks, and verification.

## Scope
This runbook covers:
1. VM identity and provisioning contract
2. host bootstrap/install/verify contract
3. Pangolin connector wiring for VM mode

This runbook does not cover:
1. cluster-side `platform/apps/n8n` GitOps manifests
2. app-specific workflow design inside `n8n`

## Prerequisites
1. `workload-pve` is reachable from the operator host
2. Proxmox template VM is healthy (`workload_pve_template_vm_id`)
3. static management IP selected for `n8n-vm`
4. 1Password item `n8n-secrets` contains:
- `db-password`
- `encryption-key`
5. if public/internal routed access is desired, Pangolin site item exists for `n8n-vm` connector wiring

## Canonical Files To Update
1. `ops/ansible/host_vars/workload-pve.yml`
2. `ops/ansible/inventory/n8n.ini`
3. `scripts/2-ops/workload/29-rebuild-n8n-vm.sh` (new)
4. `ops/ansible/playbooks/36-bootstrap-n8n-vm.yml` (new)
5. `ops/ansible/playbooks/37-install-n8n-vm.yml` (new)
6. `ops/ansible/playbooks/38-verify-n8n-vm.yml` (new)
7. `scripts/2-ops/workload/30-bootstrap-n8n-host.sh` (new)
8. `scripts/2-ops/workload/31-install-n8n.sh` (new)
9. `scripts/2-ops/workload/32-verify-n8n.sh` (new)
10. `ops/pangolin/sites/required-sites.yaml` (if connector mode is required)
11. `scripts/2-ops/workload/README.md`

## Procedure
### 1) Declare VM identity and substrate facts
In `ops/ansible/host_vars/workload-pve.yml`, add `n8n` VM reservation fields:
1. VM ID
2. VM name (`n8n`)
3. IP/CIDR and gateway
4. bridge
5. ciuser and ssh public key path
6. nameserver
7. cores, memory, disk

This is the canonical source for rebuild-time VM shape.

### 2) Add dedicated inventory
Create `ops/ansible/inventory/n8n.ini`:
1. group: `n8n_vms`
2. host alias: `n8n-vm`
3. `ansible_host=<static-ip>`
4. `ansible_user=virgil`
5. `ansible_python_interpreter=/usr/bin/python3`

### 3) Add rebuild runbook
Create `scripts/2-ops/workload/29-rebuild-n8n-vm.sh` by following:
1. `09-rebuild-nextcloud-vm.sh`
2. `10-rebuild-talk-hpb-vm.sh`

Required behavior:
1. read all VM shape values from `workload-pve.yml`
2. use `PROXMOX_REBUILD_CONFIRM=n8n-vm-<vmid>` guardrail
3. clone from template, set net/cloud-init/ssh key, start VM
4. wait until guest agent or SSH readiness

### 4) Bootstrap host baseline
Create:
1. `ops/ansible/playbooks/36-bootstrap-n8n-vm.yml`
2. `scripts/2-ops/workload/30-bootstrap-n8n-host.sh`

Baseline should mirror dedicated VM pattern:
1. install baseline packages (`ufw`, `fail2ban`, etc.)
2. default firewall policy
3. allow SSH
4. assert expected hostname

### 5) Install n8n runtime
Create:
1. `ops/ansible/playbooks/37-install-n8n-vm.yml`
2. `scripts/2-ops/workload/31-install-n8n.sh`

Install contract:
1. install container runtime and compose tooling
2. render runtime env from canonical secret refs
3. deploy `n8n` as a managed service
4. persist app data on local durable path

### 6) Verify runtime
Create:
1. `ops/ansible/playbooks/38-verify-n8n-vm.yml`
2. `scripts/2-ops/workload/32-verify-n8n.sh`

Verification contract:
1. service is active
2. listener is present on expected port
3. local health endpoint responds
4. process survives reboot

### 7) Wire Pangolin connector (VM mode)
If `n8n` must be routed via Pangolin:
1. add `n8n-vm` record in `ops/pangolin/sites/required-sites.yaml` with `connector_mode: vm`
2. ensure corresponding OP item exists with endpoint/newt_id/secret
3. run `scripts/2-ops/host/27-reconcile-pangolin-sites.sh` to create/reconcile site + OP item
4. run `scripts/2-ops/workload/21-wire-vm-newt-connectors.sh`
5. run `scripts/2-ops/host/31-apply-n8n-blueprint.sh` to expose `n8n.virgil.info`
6. verify connector service active on `n8n-vm`

### 8) End-to-end no-arg chain
For a deterministic rebuild + publish run, use:
1. `scripts/2-ops/workload/39-bring-up-n8n-vm-k8s-pangolin.sh`

This chain intentionally keeps secure-cookie mode and publishes n8n through Pangolin HTTPS rather than local insecure access patterns.

### 8) Update runbook index and log outcome
1. add new script entries to `scripts/2-ops/workload/README.md`
2. write a progress note in `docs/progress_log/` with:
- date
- verified runtime checks
- unresolved blockers, if any

## Definition Of Done
`n8n` dedicated VM onboarding is complete only when:
1. VM rebuild is reproducible from repo wrappers
2. inventory identity resolves and ansible can reach host
3. install + verify wrappers pass without ad hoc edits
4. Pangolin connector is active if routing is required
5. a progress log records the verified end state
