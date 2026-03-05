# 0680 - Workload Worker Removal And Nextcloud Blue/Green VM Plan

Date: 2026-03-05

## Goal

Remove `workload-vm-worker` from active operations and canonical Nextcloud source-of-truth, then move to a VM-only blue/green model for Nextcloud core and Talk HPB.

## Scope

In scope:
1. remove active references to `workload-vm-worker` for Nextcloud operations
2. remove `nextcloud_k3s_legacy` from Nextcloud SoT
3. define canonical blue/green VM identities and run order
4. align Pangolin/Newt and inventory references to VM-only operation

Out of scope:
1. removing all historical k3s documentation across the entire repository
2. deleting observatory k3s control-plane capabilities
3. full data migration automation between blue and green instances

## Current Source-Of-Truth Gaps

1. [instances.yaml](/Users/virgil/Dev/rita-v4/ops/nextcloud/instances.yaml) still carries `nextcloud_k3s_legacy` pointing to `workload-vm-worker`.
2. [workload.ini](/Users/virgil/Dev/rita-v4/ops/ansible/inventory/workload.ini) still defines `workload-vm-worker`.
3. `scripts/2-ops/workload/15-20` remain k8s/AppAPI workflows and can be mistaken for current VM path.
4. [workload README](/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/README.md) still mixes worker-lane and VM-lane sequencing.

## Target State

1. Official Nextcloud path is VM-only and explicit:
   - `nextcloud-blue-vm` (active or standby)
   - `nextcloud-green-vm` (active or standby)
2. Talk HPB has blue/green counterparts with matching lifecycle controls.
3. Pangolin managed sites and Newt wiring are sourced from active VM entries only.
4. No active runbook required for `workload-vm-worker` in Nextcloud/Talk operations.

## Phase 1 - Freeze And Safety

1. Freeze worker-lane scripts for Nextcloud:
   - mark `15-20` as deprecated/blocked for VM-only mode
2. Snapshot active VMs and capture current SoT values:
   - Nextcloud: `nextcloud-vm`
   - Talk HPB: `talk-hpb-vm`
3. Capture current Pangolin site IDs and OP item references.

Gate:
1. operator can no longer accidentally execute k8s Nextcloud flow from workload scripts

## Phase 2 - SoT Cleanup (Worker Removal)

1. Update [instances.yaml](/Users/virgil/Dev/rita-v4/ops/nextcloud/instances.yaml):
   - remove `nextcloud_k3s_legacy`
   - keep only VM-backed instances
2. Update [ops/nextcloud/README.md](/Users/virgil/Dev/rita-v4/ops/nextcloud/README.md):
   - remove legacy guidance
   - document VM-only policy
3. Update [scripts/2-ops/workload/README.md](/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/README.md):
   - separate deprecated worker scripts from active VM scripts
4. Update [ops/ansible/README.md](/Users/virgil/Dev/rita-v4/ops/ansible/README.md):
   - remove “workload worker only” language for Nextcloud domain.

Gate:
1. no Nextcloud canonical SoT points to `workload-vm-worker`

## Phase 3 - Blue/Green VM SoT Model

1. Extend [instances.yaml](/Users/virgil/Dev/rita-v4/ops/nextcloud/instances.yaml) to include:
   - `nextcloud_blue_vm`
   - `nextcloud_green_vm`
2. Add explicit role fields:
   - `color`
   - `lifecycle_state` (`active`, `standby`, `building`, `retired`)
   - `traffic_state` (`serving`, `not_serving`)
3. Add equivalent Talk HPB blue/green records (either in same file or a new `ops/nextcloud/talk-instances.yaml`).
4. Keep one explicit pointer:
   - `official_instance` must reference only one active color.

Gate:
1. blue/green state can be read from one canonical SoT without inference

## Phase 4 - Script And Inventory Alignment

1. Add VM-only selectors to scripts that currently default hardcoded `nextcloud-vm`:
   - password rotation scripts
   - Talk runtime configure/verify scripts
   - Newt wiring scripts where applicable
2. Introduce color-aware wrappers:
   - `nextcloud --color blue|green --action install|verify|configure-talk`
   - wrappers resolve host alias from SoT
3. Restrict direct host defaults:
   - fail if host alias not in active SoT
4. Keep `workload.ini` only if needed for non-Nextcloud tasks; otherwise archive it and remove references.

Gate:
1. all operator runbooks for Nextcloud/Talk resolve through blue/green SoT

## Phase 5 - Cutover And Retirement

1. Build standby color VM and apply full stack.
2. Verify standby with full check suite:
   - core verify
   - Talk runtime verify
   - Pangolin/Newt verify
3. Flip `official_instance` and Pangolin target to new color.
4. Hold bake window, then retire prior color or keep as warm rollback.
5. Decommission `workload-vm-worker` only after explicit non-dependency check.

Gate:
1. blue/green cutover completed with rollback path preserved

## Verification Checklist

1. `./scripts/2-ops/workload/12-install-nextcloud-core.sh`
2. `./scripts/2-ops/workload/13-verify-nextcloud-core.sh`
3. `./scripts/2-ops/workload/26-configure-nextcloud-talk-runtime.sh`
4. `./scripts/2-ops/workload/27-verify-nextcloud-talk-runtime.sh`
5. `./scripts/2-ops/host/28-verify-pangolin-sites-and-newt.sh`
6. admin overview warning check on `cloud.virgil.info`

## Risks

1. hidden dependency on `workload-vm-worker` in older scripts/docs
2. drift between Pangolin site pointers and official instance pointer
3. blue/green ambiguity if both colors are left `serving` without explicit traffic policy

## Immediate Next Actions

1. execute Phase 1 and Phase 2 in one PR:
   - deprecate `15-20` for VM-only mode
   - remove `nextcloud_k3s_legacy` from [instances.yaml](/Users/virgil/Dev/rita-v4/ops/nextcloud/instances.yaml)
   - update README docs listed above
2. execute Phase 3 in a second PR:
   - add blue/green SoT schema and records
3. execute Phase 4/5 after first blue/green standby VM is built.
