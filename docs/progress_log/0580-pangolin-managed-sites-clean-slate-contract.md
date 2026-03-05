# 0580 - Pangolin Managed Sites Clean-Slate Contract

Date: 2026-03-05

## Summary

`observatory`, `nextcloud_vm`, and `talk_hpb_vm` are now all treated as managed Pangolin sites in canonical required-sites state.

The clean-slate cycle has been proven end to end:
1. delete managed Pangolin sites + OP items
2. recreate sites + credentials from required-sites
3. redeploy connectors
4. verify Pangolin online + VM Newt active

## Key Change

[required-sites.yaml](/Users/virgil/Dev/rita-v4/ops/pangolin/sites/required-sites.yaml) now marks `observatory` as:
1. `"managed_mode": "managed"`

This removed the old legacy skip behavior in reconcile for `observatory`.

## What Was Proven

From a clean slate (sites + OP entries removed), this sequence works:

1. Teardown managed:
- `PANGOLIN_TEARDOWN_CONFIRM=delete-managed-sites ./scripts/2-ops/host/29-teardown-pangolin-sites.sh`

2. Reconcile managed records:
- `./scripts/2-ops/host/27-reconcile-pangolin-sites.sh`

3. Deploy connectors:
- `NEWT_FAST_FAIL=1 ./scripts/2-ops/workload/21-wire-vm-newt-connectors.sh`
- `./scripts/2-ops/observatory/10-install-newt.sh`

4. Verify:
- `./scripts/2-ops/host/28-verify-pangolin-sites-and-newt.sh`

Observed successful state:
1. Pangolin sites online for `observatory`, `nextcloud-vm`, `talk-hpb-vm`
2. VM systemd `pangolin-newt` active for `nextcloud-vm` and `talk-hpb-vm`

## Operational Contract Clarified

`27-reconcile-pangolin-sites.sh` only creates/reconciles site records + OP credentials.

It does not make sites online by itself. Site online requires connector deployment:
1. VM connectors via `21-wire-vm-newt-connectors.sh`
2. observatory k8s connector via `10-install-newt.sh`

## Notable Log Interpretation

Journal output may include earlier restart failures (for example old `-endpoint` flag errors) alongside current successful startup lines.

Current health should be judged from latest state indicators:
1. Newt shows websocket connected and tunnel established
2. `systemctl is-active pangolin-newt` is `active` on VM connectors
3. Pangolin verify reports site `online`
