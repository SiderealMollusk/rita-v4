# Ansible Layout

This repo uses Ansible as the single source of truth for host identity and deploy vars.

## Current Inventory
- `inventory/vps.ini`: current VPS hosts.
- `group_vars/vps.yml`: vars shared by the `[vps]` group and reusable in templates/manifests.
- `../network/routes.yml`: human/audit route catalog for externally hittable endpoints.

## Usage
```bash
ansible -i ops/ansible/inventory/vps.ini vps -m ping
```

Preferred no-arg wrapper (works from host or devcontainer path layouts):
```bash
scripts/2-ops/vps/01-ansible-ping.sh
```

VPS bring-up sequence wrappers:
```bash
scripts/2-ops/vps/02-bootstrap-host.sh
scripts/2-ops/vps/03-install-k3s.sh
scripts/2-ops/vps/04-install-eso.sh
scripts/2-ops/vps/05-apply-secret-bridge.sh
```

## Scaling Later
When you add more nodes/environments, keep this pattern:
- add more hosts to `inventory/vps.ini` (or split into `staging.ini` / `prod.ini`)
- keep shared values in `group_vars/`
- keep host-specific overrides in `host_vars/<hostname>.yml` if needed
