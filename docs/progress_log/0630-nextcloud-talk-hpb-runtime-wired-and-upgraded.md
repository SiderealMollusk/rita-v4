# 0630 - Nextcloud Talk HPB Runtime Wired And Upgraded

Date: 2026-03-05

## Summary

Established an automated Talk runtime lane for the official Nextcloud instance and moved HPB wiring from ad-hoc/manual steps into repo-backed scripts + SoT.

Current checkpoint:
1. Talk runtime apply and verify scripts are in place and passing.
2. Pangolin sites and Newt connectors are healthy (`online` + VM services active).
3. Talk runtime is now configured with signaling + STUN from repo state.

## Changes Captured

1. Added Talk runtime desired state:
- [talk-runtime.yaml](/Users/virgil/Dev/rita-v4/ops/nextcloud/talk-runtime.yaml)

2. Added/updated Talk runtime scripts:
- [25-configure-nextcloud-talk-runtime.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/25-configure-nextcloud-talk-runtime.sh)
- [26-configure-nextcloud-talk-runtime.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/26-configure-nextcloud-talk-runtime.sh)
- [27-verify-nextcloud-talk-runtime.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/27-verify-nextcloud-talk-runtime.sh)
- [28-seed-nextcloud-talk-signaling-secret-op.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/28-seed-nextcloud-talk-signaling-secret-op.sh)

3. Documented workload runbook entry points:
- [README.md](/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/README.md)

## Evidence Snapshot

1. `./scripts/2-ops/host/28-verify-pangolin-sites-and-newt.sh`
- passed
- `ops-brain`, `nextcloud-vm`, `talk-hpb-vm` all present and online
- VM Newt services active on both workload VMs

2. `./scripts/2-ops/workload/26-configure-nextcloud-talk-runtime.sh`
- applied successfully
- signaling server set
- STUN list non-empty

3. `./scripts/2-ops/workload/27-verify-nextcloud-talk-runtime.sh`
- passed

## Remaining Work

1. Talk signaling runtime file has been switched to OP reference (`secret_op_ref`) and plaintext secret removed from repo.
2. Ensure OP item is present with canonical path `op://5vr4hef2746tpplvjx424xafvu/nextcloud-talk-runtime/password`.
3. Add TURN server configuration for production-grade NAT traversal.
4. Confirm admin Overview HPB warning state after full signaling version alignment check on `talk-hpb-vm`.
