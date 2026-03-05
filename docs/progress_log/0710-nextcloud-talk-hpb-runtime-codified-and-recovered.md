# 0710 - Nextcloud Talk HPB Runtime Codified And Recovered

Date: 2026-03-05

## Summary

The missing HPB provisioning gap on `talk-hpb-vm` is now codified and working.  
Before this change, `cloud.virgil.info/standalone-signaling` returned `502` because no HPB runtime existed on the dedicated Talk VM.

After these changes:
1. HPB runtime install/config is scripted.
2. HPB verification is scripted.
3. Public signaling endpoint is healthy (`HTTP 200`, signaling `v2.1.0`).

## Changes

1. Added HPB install runbook:
- [41-install-nextcloud-talk-hpb-runtime.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/41-install-nextcloud-talk-hpb-runtime.sh)

2. Added HPB verify runbook:
- [42-verify-nextcloud-talk-hpb-runtime.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/42-verify-nextcloud-talk-hpb-runtime.sh)

3. Updated workload runbook index:
- [README.md](/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/README.md)

## Validation Evidence

1. `41-install-nextcloud-talk-hpb-runtime.sh` completed successfully.
2. `42-verify-nextcloud-talk-hpb-runtime.sh` passed:
1. `nextcloud-spreed-signaling`, `janus`, `nats-server` active.
2. local welcome endpoint returned JSON with version `v2.1.0`.
3. public endpoint check passed.
4. Nextcloud Talk runtime verification (`27`) passed.
3. Direct public check:
1. `curl -si https://cloud.virgil.info/standalone-signaling/api/v1/welcome` => `HTTP/2 200`
2. body includes `"version":"v2.1.0"`

4. Baseline infra check:
1. `28-verify-pangolin-sites-and-newt.sh` passed (`nextcloud-vm`, `talk-hpb-vm`, `n8n-vm` online/newt active; `observatory` offline warning unchanged).

## Notes / Remaining Caveats

1. Janus warning remains:
1. `Plugin janus.eventhandler.wsevh not found, realtime usage will not be available`
2. This can still affect call UX quality (for example stale ringing/state propagation edge cases).
2. Janus logs also show:
1. `Full-Trickle is NOT enabled in Janus!`
2. Calls still function, but this is not yet an optimized/fully tuned HPB state.
