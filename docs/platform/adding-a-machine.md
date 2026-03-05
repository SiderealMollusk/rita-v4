# Adding A Machine

Freshness stamp: 2026-03-05 (background agent)

This doc defines the durable repo process for adding a new machine or VM.

It is for:
- new physical hosts
- new Proxmox-backed guest VMs
- new internal cluster nodes
- new operator hosts that need controlled access to cluster APIs

It is not for:
- app deployment
- one-off shell access
- secrets-only changes

## Canonical Sources
- inventory identity and management IP: `ops/ansible/inventory/*.ini`
- host-specific facts: `ops/ansible/host_vars/*.yml`
- role/domain defaults: `ops/ansible/group_vars/*.yml`
- node role intent: `docs/nodes/*.md`
- cluster membership and labels: `ops/ansible/group_vars/internal_cluster.yml`
- host/operator bootstrap runbooks: `scripts/2-ops/`

## Machine Classes
### Physical host
Examples:
- `platform-nuc`
- `ops-brain`
- `main-vps`

Required updates:
1. add inventory entry
2. add `host_vars` if the machine has unique facts
3. add or update node doc if the machine is a durable architectural role
4. update access/firewall allowlists if the machine must participate in cluster traffic

### Proxmox guest VM
Examples:
- `platform-vm-worker`
- `platform-vm-newt`

Required updates:
1. add inventory entry for the guest
2. add or update substrate facts in `ops/ansible/host_vars/platform-nuc.yml`
3. ensure the guest has a stable hostname and management IP
4. update any cluster/firewall allowlists that depend on the guest IP

### Internal cluster node
Examples:
- `platform`
- future workload workers

Required updates:
1. add the machine to the relevant inventory
2. add or update worker/control-plane bootstrap vars
3. update `ops/ansible/group_vars/internal_cluster.yml`
4. update host firewalls for:
   - k3s API access where needed
   - Flannel VXLAN `udp/8472`
5. apply bootstrap runbooks
6. verify labels, readiness, and cross-node traffic

## Required Update Order
1. decide the canonical machine identity
2. add inventory entries
3. add `host_vars` for machine-specific facts
4. add or update `group_vars` for role-level defaults
5. update firewall allowlists if the machine affects cluster or operator traffic
6. apply bootstrap runbooks
7. verify the machine in its real runtime role
8. update the relevant node doc or progress note if the architecture changed

## Inventory Rules
Put the primary management address in inventory as `ansible_host`.

Examples:
- physical host management IP
- guest VM management IP
- control-plane laptop management IP

Do not treat inventory as a scratchpad.
If the IP is stable enough for automation, it belongs there.

## Host Vars Rules
Put machine-specific facts in `host_vars`.

Examples:
- Proxmox VM IDs
- cloud-init guest IP/CIDR/gateway intent
- bridge name
- physical location
- hardware class
- stable site-specific facts

Do not put secrets here.

## Group Vars Rules
Put role-level or shared policy here.

Examples:
- shared firewall allowlists
- shared platform worker defaults
- k3s role labels
- cluster-wide expected node mappings

If multiple machines of the same class need the same rule, it belongs here.

## Firewall Rules
When adding or changing cluster nodes, update the canonical allowlists first.

Current relevant vars:
- `ops/ansible/group_vars/ops_brain.yml`
  - `ops_brain_k3s_api_allowed_sources`
  - `ops_brain_flannel_allowed_sources`
- `ops/ansible/group_vars/platform.yml`
  - `platform_flannel_allowed_sources`

Meaning:
- `ops_brain_k3s_api_allowed_sources`
  controls who may reach `ops-brain` on `6443/tcp`
- `ops_brain_flannel_allowed_sources`
  controls which worker nodes may send Flannel VXLAN traffic to `ops-brain`
- `platform_flannel_allowed_sources`
  controls which control-plane nodes may send Flannel VXLAN traffic to `platform`

If a machine participates in pod networking, do not skip the Flannel allowlist updates.

## Current Programmatic Apply Paths
Apply the machine state by rerunning the canonical wrappers, not by hand-editing the host.

Current paths:
- `scripts/2-ops/ops-brain/02-bootstrap-host.sh`
- `scripts/2-ops/ops-brain/08-sync-kubeconfig.sh`
- `scripts/2-ops/worker/02-bootstrap-host.sh`
- `scripts/2-ops/worker/03-install-k3s-agent.sh`
- `scripts/2-ops/worker/04-label-nodes.sh`
- `scripts/2-ops/worker/05-verify-cluster.sh`
- `scripts/2-ops/nuc/01-inspect-proxmox.sh`
- `scripts/2-ops/nuc/02-rebuild-platform-vm.sh`

## Verification Contract
If you add a machine, the change is not done until the runtime role is verified.

Examples:
- physical host: reachable by inventory identity
- guest VM: reachable by inventory identity and expected hostname
- cluster worker: `Ready`, labeled, and cross-node traffic works
- control-plane host: host-side kubeconfig works and API traffic is intentionally allowed

## Current Internal Cluster Example
To add a new internal worker-like machine, update at least:
1. `ops/ansible/inventory/platform.ini` or another role inventory
2. `ops/ansible/inventory/internal-cluster.ini`
3. `ops/ansible/group_vars/internal_cluster.yml`
4. `ops/ansible/group_vars/ops_brain.yml`
5. the machine-specific `host_vars` if needed
6. the relevant runbooks under `scripts/2-ops/worker/` and `scripts/2-ops/ops-brain/`

Then apply:
1. host bootstrap
2. worker join
3. node labeling
4. cluster verification

## Anti-Pattern
Do not leave “adding a machine” as:
- a remembered shell command
- a local-only `ufw allow`
- a one-off host file edit
- a progress-log-only fact

If the machine matters operationally, its onboarding path must exist in repo state.

## Dedicated VM Example: n8n
If the target is a new dedicated VM for `n8n`, use this order and keep it repo-native:
1. reserve VM identity and sizing in `ops/ansible/host_vars/workload-pve.yml`
2. add dedicated inventory at `ops/ansible/inventory/n8n.ini` with canonical alias `n8n-vm`
3. add a workload rebuild wrapper following the existing Proxmox VM pattern
4. add bootstrap/install/verify playbooks and shell wrappers under `scripts/2-ops/workload/`
5. add the VM to `ops/pangolin/sites/required-sites.yaml` (`connector_mode: vm`) if it will be externally routed
6. apply in runtime order: rebuild -> bootstrap -> install -> verify -> connector wire-up
7. record final verified state in `docs/progress_log/`

For the full lane-specific procedure, see:
- [n8n-vm-bringup.md](/Users/virgil/Dev/rita-v4/docs/platform/n8n-vm-bringup.md)
