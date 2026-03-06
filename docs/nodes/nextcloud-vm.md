# Node: nextcloud-vm

## Identity
- Host alias: `nextcloud-vm`
- Role: dedicated Nextcloud core runtime VM
- Hardware class: Proxmox guest VM
- Management IP source of truth: `ops/ansible/inventory/nextcloud.ini`

## Access
- SSH user: `virgil`
- SSH port: `22`
- Expected admin model: `virgil` + sudo

## Runtime Intent
- Runs Nextcloud core application runtime.
- Serves as the primary app host for `cloud.virgil.info`.
- Does not host control-plane or monitoring-stack responsibilities.

## Network Intent
- Control-plane access is managed via Newt/Pangolin site record:
  - `slug`: `nextcloud_vm`
  - `connector_mode`: `vm`
  - `op_item_title`: `pangolin_site_nextcloud_vm`
- Internal service dependencies remain LAN/private.

## Verify
1. `ops/ansible/inventory/nextcloud.ini`
2. `ops/ansible/host_vars/nextcloud-vm.yml`
3. `ops/pangolin/sites/required-sites.yaml`
4. `docs/service-placement.md`
