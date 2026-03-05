# 0600 - Nextcloud Auth Rotation And Talk Ringing Diagnostics

Date: 2026-03-05

## Summary

Today confirmed two important operational behaviors:
1. password rotation automation works, but item-to-user mapping must be explicit
2. Talk can establish media while still presenting stale ringing when HPB/push/signaling layers are incomplete

## What Was Proven

1. Password rotation scripts now support stable, explicit mapping:
- logic script:
  - [22-rotate-nextcloud-user-password.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/22-rotate-nextcloud-user-password.sh)
- no-arg wrappers:
  - [23-rotate-nextcloud-virgil-admin-password.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/23-rotate-nextcloud-virgil-admin-password.sh)
  - [24-rotate-nextcloud-virgil-password.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/24-rotate-nextcloud-virgil-password.sh)

2. `virgil` and `quell` user resets were executed successfully through `occ`.

3. Real auth verification must use WebDAV `PROPFIND`:
1. `207` indicates valid credentials
2. prior `GET` check returning `200` was a false-positive auth test

## Root Cause Clarification From Operator Testing

Observed mismatch was caused by rotating user `virgil` from item `virgil-admin`.

That means:
1. Nextcloud `virgil` password matched the `virgil-admin` item
2. operator expected it to match the `virgil` item

This is now addressed by:
1. dedicated no-arg wrapper for `virgil` item/user
2. username-match safety option (`--require-op-username-match`)

## Talk Diagnostics Snapshot

From `nextcloud-core`:
1. `spreed` is installed (`22.0.9`)
2. no external signaling servers configured
3. no STUN/TURN servers configured
4. `notify_push` app not present

This is consistent with the reported symptom:
1. call media can connect
2. ring state may remain stale across clients

## Documentation Updates Made

1. Stale host README fields corrected from `id` to `newt_id`:
- [scripts/2-ops/host/README.md](/Users/virgil/Dev/rita-v4/scripts/2-ops/host/README.md)

2. Warning tracker enriched with Talk symptom correlation and auth verification guidance:
- [0630-nextcloud-admin-warning-remediation-tracker.md](/Users/virgil/Dev/rita-v4/docs/plans/0630-nextcloud-admin-warning-remediation-tracker.md)

3. New upgrade/reliability plan added:
- [0640-nextcloud-official-upgrade-and-talk-reliability-plan.md](/Users/virgil/Dev/rita-v4/docs/plans/0640-nextcloud-official-upgrade-and-talk-reliability-plan.md)

## Current Position

1. Auth rotation lane is now operational with explicit per-user wrappers.
2. Next action should focus on Talk reliability stack completion:
- HPB
- STUN/TURN
- `notify_push`
