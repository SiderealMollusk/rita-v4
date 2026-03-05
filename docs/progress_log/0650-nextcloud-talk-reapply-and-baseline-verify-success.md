# 0650 - Nextcloud Talk Reapply And Baseline Verify Success

Date: 2026-03-05

## Summary

Completed a full operator re-apply sequence from host shell and confirmed the Nextcloud/Talk/Pangolin baseline is healthy after recent remediations.

## Commands Executed

1. `./scripts/2-ops/workload/12-install-nextcloud-core.sh`
2. `./scripts/2-ops/workload/28-seed-nextcloud-talk-signaling-secret-op.sh`
3. `./scripts/2-ops/workload/26-configure-nextcloud-talk-runtime.sh`
4. `./scripts/2-ops/workload/27-verify-nextcloud-talk-runtime.sh`
5. `./scripts/2-ops/host/28-verify-pangolin-sites-and-newt.sh`

## Result Snapshot

1. Nextcloud core playbook completed successfully (`failed=0`).
2. Talk signaling secret was updated in OP item `nextcloud-talk-runtime` and canonical OP ref confirmed:
1. `op://5vr4hef2746tpplvjx424xafvu/nextcloud-talk-runtime/password`
3. Talk runtime apply succeeded.
4. Talk runtime verify succeeded.
5. Pangolin + OP read-only check succeeded.
6. Pangolin managed sites are online and VM Newt services are active for:
1. `nextcloud-vm`
2. `talk-hpb-vm`
3. `ops-brain`

## Current Position

1. Core automation path is functioning for re-apply and verification.
2. Remaining work is hardening and reliability closure:
1. TURN configuration for mobile/video reliability
2. MIME guardrail cleanup finalization
3. HPB operationalization + secret lifecycle debt closure (plans 0660/0670)
