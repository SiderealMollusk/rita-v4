# Ansible Layout

This repo uses Ansible as the single source of truth for host identity and deploy vars.

## Current Inventory
- `inventory/vps.ini`: current VPS hosts.
- `inventory/proxmox.ini`: Proxmox substrates and guest identities.
- `inventory/ops-brain.ini`: current control-plane laptop.
- `inventory/platform.ini`: platform worker VM only.
- `inventory/workload.ini`: workload worker VM only.
- `inventory/workload-cluster.ini`: ops-brain + workload worker cluster operations.
- `inventory/internal-cluster.ini`: combined `ops-brain` + `platform` cluster operations.
- `group_vars/vps.yml`: vars shared by the `[vps]` group and reusable in templates/manifests.
- `group_vars/ops_brain.yml`: vars shared by the control-plane lane.
- `group_vars/platform.yml`: vars shared by the platform worker lane.
- `group_vars/workload.yml`: vars shared by the workload worker lane.
- `group_vars/internal_cluster.yml`: vars shared by cross-node cluster operations.
- `../network/routes.yml`: human/audit route catalog for externally hittable endpoints.

## Usage
```bash
ansible -i ops/ansible/inventory/vps.ini vps -m ping
```

Preferred no-arg wrapper (works from host or devcontainer path layouts):
```bash
scripts/2-ops/vps/01-ansible-ping.sh
```

Internal cluster wrappers:
```bash
scripts/2-ops/ops-brain/01-ansible-ping.sh
scripts/2-ops/worker/01-ansible-ping.sh
scripts/2-ops/worker/03-install-k3s-agent.sh
```

VPS bring-up sequence wrappers:
```bash
scripts/2-ops/vps/02-bootstrap-host.sh
scripts/2-ops/vps/03-install-runtime.sh
scripts/2-ops/vps/04-install-pangolin-server.sh
scripts/2-ops/vps/05-capture-setup-token.sh
scripts/2-ops/vps/06-verify-pangolin-server.sh
```

## Scaling Later
When you add more nodes/environments, keep this pattern:
- add more hosts to `inventory/vps.ini` (or split into `staging.ini` / `prod.ini`)
- add substrate hosts such as Proxmox nodes to `inventory/proxmox.ini`
- add more cluster nodes to `inventory/internal-cluster.ini`
- keep shared values in `group_vars/`
- keep host-specific overrides in `host_vars/<hostname>.yml`
