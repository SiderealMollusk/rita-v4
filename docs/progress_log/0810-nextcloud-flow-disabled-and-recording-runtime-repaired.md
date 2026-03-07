# 0810 - Nextcloud Flow Disabled And Recording Runtime Repaired

Date: 2026-03-06
Status: Completed

## Summary
Executed requested mitigation and repair actions:
1. disabled `flow` ExApp to stop recurring AppAPI warning/log noise
2. re-applied and verified Talk recording runtime/config runbooks
3. documented full incident analysis in research

Research output:
1. [0018-nextcloud-flow-appapi-and-recording-incident-2026-03-06.md](/Users/virgil/Dev/rita-v4/docs/research/0018-nextcloud-flow-appapi-and-recording-incident-2026-03-06.md)

## Actions Executed

### 1. Immediate log/warning control
1. log flush and throttle cleanup runbooks were used earlier in the session
2. final operator-requested state change applied:
- `flow` disabled on `nextcloud-vm`

### 2. Recording backend repair
Runbooks executed in order:
1. [47-install-nextcloud-talk-recording-runtime.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/47-install-nextcloud-talk-recording-runtime.sh)
2. [48-configure-nextcloud-talk-recording-runtime.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/48-configure-nextcloud-talk-recording-runtime.sh)
3. [49-verify-nextcloud-talk-recording-runtime.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/49-verify-nextcloud-talk-recording-runtime.sh)

Result:
1. recording runtime verification returned OK

### 3. Flow stabilization attempts (not adopted)
Attempted but not retained as final state:
1. reconfigure HaRP runtime
2. redeploy/patch/re-verify Flow
3. manual unregister/reregister cycles

Observed outcome remained noisy/unreliable for this lane; Flow was therefore left disabled per operator request.

## Current Intended State
1. Nextcloud core remains operational.
2. Talk recording runtime is verified healthy.
3. Flow ExApp is disabled pending future dedicated stabilization work.
