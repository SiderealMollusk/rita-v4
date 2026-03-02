# NUC / Proxmox Runbooks

These scripts cover the pre-worker phases on the NUC/Proxmox lane:
1. inspect current Proxmox state
2. rebuild VM `9200` as `platform`

Freshness anchor:
1. [0170-platform-worker-execution-plan.md](/Users/virgil/Dev/rita-v4/docs/plans/0170-platform-worker-execution-plan.md)

Direct-entry scripts:
1. `01-inspect-proxmox.sh`
2. `02-rebuild-platform-vm.sh`

Primary config source:
1. `ops/ansible/inventory/proxmox.ini`
2. `ops/ansible/host_vars/platform-nuc.yml`

Required environment for rebuild:
1. `PROXMOX_REBUILD_CONFIRM=platform-vm-worker-9200`

Optional environment:
1. No stable machine/IP settings should need shell exports.
2. The SSH public key path defaults from `host_vars/platform-nuc.yml`.
3. If network/spec details change, update inventory or `host_vars/platform-nuc.yml`.
