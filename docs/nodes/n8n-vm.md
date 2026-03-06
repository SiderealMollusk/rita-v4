# Node: n8n-vm

## Identity
- Host alias: `n8n-vm`
- Role: dedicated n8n runtime VM and k3s worker
- Hardware class: Proxmox guest VM
- Management IP source of truth: `ops/ansible/inventory/n8n.ini`

## Access
- SSH user: `virgil`
- SSH port: `22`
- Expected admin model: `virgil` + sudo

## Runtime Intent
- Runs n8n workload components scheduled to the dedicated node.
- Exposes n8n through Pangolin-managed route `n8n.virgil.info`.
- Does not host control-plane or monitoring-stack responsibilities.

## Network Intent
- Control-plane access is managed via Newt/Pangolin site record:
  - `slug`: `n8n_vm`
  - `connector_mode`: `vm`
  - `op_item_title`: `pangolin_site_n8n_vm`
- Cluster service access remains private to internal networking.

## Verify
1. `ops/ansible/inventory/n8n.ini`
2. `ops/ansible/host_vars/n8n-vm.yml`
3. `ops/pangolin/sites/required-sites.yaml`
4. `docs/platform/n8n-vm-bringup.md`
