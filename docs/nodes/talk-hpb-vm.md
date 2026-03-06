# Node: talk-hpb-vm

## Identity
- Host alias: `talk-hpb-vm`
- Role: dedicated Nextcloud Talk HPB/signaling runtime VM
- Hardware class: Proxmox guest VM
- Management IP source of truth: `ops/ansible/inventory/talk-hpb.ini`

## Access
- SSH user: `virgil`
- SSH port: `22`
- Expected admin model: `virgil` + sudo

## Runtime Intent
- Runs Talk signaling/HPB runtime for Nextcloud.
- Works with `nextcloud-vm` as part of the Talk lane.
- Does not host control-plane or monitoring-stack responsibilities.

## Network Intent
- Control-plane access is managed via Newt/Pangolin site record:
  - `slug`: `talk_hpb_vm`
  - `connector_mode`: `vm`
  - `op_item_title`: `pangolin_site_talk_hpb_vm`
- HPB traffic and admin access remain policy-bound to intended callers.

## Verify
1. `ops/ansible/inventory/talk-hpb.ini`
2. `ops/ansible/host_vars/talk-hpb-vm.yml`
3. `ops/pangolin/sites/required-sites.yaml`
4. `docs/service-placement.md`
