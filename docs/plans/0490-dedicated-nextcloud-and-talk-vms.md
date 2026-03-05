# 0490 - Dedicated Nextcloud Core And Talk HPB VMs
Status: ACTIVE
Date: 2026-03-04

## Request

Carve two dedicated VMs out of the current `workload-pve` "giga worker" capacity:
1. `Nextcloud VM`: `4 vCPU / 8 GB RAM`
2. `Talk HPB VM`: `4 vCPU / 8 GB RAM`

Also change the underlying source-of-truth that previously modeled `workload-pve` primarily as one oversized worker VM, so the new split is foundational rather than an afterthought.

## Decision

Keep the existing `workload-vm-worker` lane, but reduce its reserved memory from `49152 MB` to `32768 MB`.

Reserve two additional standalone VM definitions on the same Proxmox host:
1. `nextcloud-core`
   - VM ID `9301`
   - IP `192.168.6.183/22`
   - `4 vCPU`
   - `8192 MB RAM`
   - `120 GB disk`
2. `nextcloud-talk-hpb`
   - VM ID `9302`
   - IP `192.168.6.184/22`
   - `4 vCPU`
   - `8192 MB RAM`
   - `80 GB disk`

## Why This Is Foundational

The repo previously encoded a "single giant worker" assumption under `workload_pve_worker_*`.

That was good enough while `workload-pve` was mainly a k3s worker substrate, but it is the wrong default shape for a collaboration stack where:
1. `Nextcloud core` should be stable and boring
2. `Talk HPB` benefits from being its own failure domain
3. future ExApps and AI workloads should not silently consume the same memory budget as the core collaboration path

## Repo Changes Required

1. extend `ops/ansible/host_vars/workload-pve.yml` with dedicated `nextcloud` and `talk_hpb` VM definitions
2. reduce the old worker reservation so the host-level sizing model still makes sense
3. add dedicated inventories and rebuild runbooks for the two new VMs
4. update workload-lane docs so future operators do not assume the host is still modeled as a single oversized guest

## Outcome

The repo should reflect `workload-pve` as a host with at least three intentional guest roles:
1. `workload-vm-worker`
2. `nextcloud-vm`
3. `talk-hpb-vm`

This does not itself migrate the live Nextcloud deployment off k3s.
It does establish the capacity and operator shape needed to do so cleanly.

## Deferred Cleanup Plan

The initial carve-out deliberately updates the source-of-truth and the new operator path first.
It does not attempt a full repo-wide reference cleanup in the same pass.

Before considering this split fully normalized, perform a cleanup pass with the following scope:

1. Sweep live-reference docs that still describe `workload-pve` as effectively a single oversized guest.
2. Update any operator-facing docs that should now mention three intentional guest roles on `workload-pve`:
   - `workload-vm-worker`
   - `nextcloud-vm`
   - `talk-hpb-vm`
3. Review `docs/vocabulary.md` and adjacent glossary/system-map docs for places where `workload-vm-worker` is described as the only guest identity worth knowing.
4. Review workload-lane runbooks that still assume only one Proxmox guest exists and decide whether they should:
   - remain worker-specific, or
   - grow sibling `nextcloud` / `talk-hpb` variants.
5. Review inventory readmes and node docs so operators can find the new inventories without reading the plan first.
6. Add a short host-capacity note to the relevant node/system docs explaining the current reserved split:
   - worker memory reduced to `32768 MB`
   - `nextcloud-core` reserved at `8192 MB`
   - `nextcloud-talk-hpb` reserved at `8192 MB`
7. Check whether any service-placement docs should explicitly say that `Nextcloud core` and `Talk HPB` are intended to move out of the generic workload-worker lane.
8. Leave historical progress logs alone unless a log is being used as a live operational reference.
9. After the VMs are actually stood up and the migration direction is clearer, decide whether the repo should keep:
   - the current k3s-hosted Nextcloud path as canonical,
   - or a VM-first Nextcloud path as canonical.
10. Once the canonical path is chosen, prune or relabel transitional docs so the repo does not imply two equally-current operator stories when only one is meant to be live.
