# 0720 - Nextcloud Talk HPB No-Adhoc Lane

Date: 2026-03-05

## Summary

Converted HPB recovery from iterative ad-hoc debugging into a clean scripted lane.

## What Was Added

1. [43-bring-up-nextcloud-talk-hpb.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/43-bring-up-nextcloud-talk-hpb.sh)
1. orchestration entrypoint:
1. install HPB runtime
2. apply Nextcloud Talk runtime SoT
3. verify HPB runtime + Nextcloud wiring
4. optional cross-lane Pangolin/Newt verify (`HPB_VERIFY_SITES=1`)

## Script Hardening

1. [41-install-nextcloud-talk-hpb-runtime.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/41-install-nextcloud-talk-hpb-runtime.sh)
1. enables Janus `events.broadcast=true`
2. enables Janus `nat.full_trickle=true`
3. writes `janus.eventhandler.wsevh` config
4. sets required signaling `[sessions] hashkey`
5. binds signaling on `0.0.0.0:8080` so Nextcloud VM upstream can reach it

2. [42-verify-nextcloud-talk-hpb-runtime.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/42-verify-nextcloud-talk-hpb-runtime.sh)
1. verifies service/process/port state
2. verifies public signaling endpoint
3. fails if recent signaling logs show missing `janus.eventhandler.wsevh`
4. fails if recent signaling logs show Full-Trickle not enabled

## Validation

1. `NEXTCLOUD_SNAPSHOT_MODE=off ./scripts/2-ops/workload/43-bring-up-nextcloud-talk-hpb.sh` passed.
2. signaling logs now report:
1. `Found JANUS WebSocketsEventHandler plugin ...`
2. `Full-Trickle is enabled`
3. public endpoint:
1. `https://cloud.virgil.info/standalone-signaling/api/v1/welcome` => `HTTP 200`
