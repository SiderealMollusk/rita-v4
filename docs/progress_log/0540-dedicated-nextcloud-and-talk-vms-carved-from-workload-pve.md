# 0540 - Dedicated Nextcloud And Talk VMs Carved From Workload-PVE

Date: 2026-03-04

## Summary

Two dedicated collaboration VMs were carved out of `workload-pve` and the repo source-of-truth was updated so the host is no longer modeled only as one oversized `workload` guest.

Created guests:
1. `nextcloud-core`
   - VM ID `9301`
   - IP `192.168.6.183`
   - `4 vCPU / 8 GB RAM / 120 GB disk`
2. `nextcloud-talk-hpb`
   - VM ID `9302`
   - IP `192.168.6.184`
   - `4 vCPU / 8 GB RAM / 80 GB disk`

Both guests were cloned from the existing Debian template and reached SSH readiness.

## Repo State Change

The canonical Proxmox host vars in [workload-pve.yml](/Users/virgil/Dev/rita-v4/ops/ansible/host_vars/workload-pve.yml) were extended to reserve:
1. the existing `workload-vm-worker`
2. the new `nextcloud-core` VM
3. the new `nextcloud-talk-hpb` VM

The old giant-worker assumption was also reduced at the host-budget level:
1. `workload_pve_worker_memory_mb` changed from `49152` to `32768`

New operator entry points were added:
1. [09-rebuild-nextcloud-vm.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/09-rebuild-nextcloud-vm.sh)
2. [10-rebuild-talk-hpb-vm.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/10-rebuild-talk-hpb-vm.sh)
3. [nextcloud.ini](/Users/virgil/Dev/rita-v4/ops/ansible/inventory/nextcloud.ini)
4. [talk-hpb.ini](/Users/virgil/Dev/rita-v4/ops/ansible/inventory/talk-hpb.ini)

## Important Operational Note

During both clones, Proxmox warned that the thin pool is oversubscribed on paper.

That does not invalidate the new guests, but it does mean storage headroom on `workload-pve` is now a real operational concern and should be treated as a follow-up risk before more large guests or disks are added casually.

## Intentional Non-Goal

This pass did **not** complete a repo-wide reference cleanup.

Reason:
1. the immediate goal was to establish the foundational host sizing and create the VMs
2. not to rewrite every historical or operator-adjacent doc in the same step

The cleanup work was deferred intentionally into the planning record:
1. [0490-dedicated-nextcloud-and-talk-vms.md](/Users/virgil/Dev/rita-v4/docs/plans/0490-dedicated-nextcloud-and-talk-vms.md)

## Next Likely Steps

1. bootstrap the new VMs with the baseline host configuration they actually need
2. decide whether `Nextcloud core` should migrate from k3s to `nextcloud-core`
3. stand up `Talk HPB` on `nextcloud-talk-hpb`
4. return for the deferred repo-wide doc/reference cleanup once the actual steady-state operator path is clearer
