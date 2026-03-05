# 0640 - Nextcloud Official Upgrade And Talk Reliability Plan

Date: 2026-03-05

## Deprecation

Deprecated. Use the canonical combined plan:
1. [0650-nextcloud-combined-upgrade-and-reliability-plan.md](/Users/virgil/Dev/rita-v4/docs/plans/0650-nextcloud-combined-upgrade-and-reliability-plan.md)

## Goal

Upgrade and harden the official Nextcloud instance (`cloud.virgil.info`) so:
1. admin-overview warnings are reduced to intentional accepted-risk items only
2. Talk ringing/call-state behavior is reliable on mobile and desktop
3. upgrade path is repeatable with explicit preflight and rollback checkpoints

## Non-Goals

1. Migrating back to legacy k3s Nextcloud
2. Solving all AppAPI/Flow feature work in the same pass
3. Full product-level onboarding policy design beyond immediate security controls

## Inputs

1. Official instance registry:
- [instances.yaml](/Users/virgil/Dev/rita-v4/ops/nextcloud/instances.yaml)

2. Warning tracker baseline:
- [0630-nextcloud-admin-warning-remediation-tracker.md](/Users/virgil/Dev/rita-v4/docs/plans/0630-nextcloud-admin-warning-remediation-tracker.md)

3. Current install path:
- [12-install-nextcloud-core.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/12-install-nextcloud-core.sh)
- [33-install-nextcloud-core.yml](/Users/virgil/Dev/rita-v4/ops/ansible/playbooks/33-install-nextcloud-core.yml)

## Phase 1 - Preflight And Safety

1. Freeze window:
- define maintenance window and communication

2. Snapshot/backup:
- VM snapshot for `nextcloud-core`
- DB backup + config backup

3. Access verification:
- confirm admin login user (`virgil-admin`)
- confirm scripted password rotation path works against OP

4. Baseline capture:
- export current admin warnings and Talk config output
- keep raw outputs in a dated operator note

Exit criteria:
1. rollback assets exist
2. baseline evidence captured

## Phase 2 - Warning Closure (Core)

1. Security/reverse-proxy correctness first:
- `forwarded_for_headers`
- HSTS
- OCS provider rewrite
- `.mjs` MIME mapping

2. Runtime defaults:
- PHP memory >= 512M
- maintenance window start
- default phone region

3. Maintenance jobs:
- `occ maintenance:repair --include-expensive`
- `occ db:add-missing-indices`

Exit criteria:
1. core P0/P1 warnings closed or explicitly accepted-risk with rationale

## Phase 3 - Talk Reliability Layer

1. Configure Talk HPB for official instance
2. Configure STUN/TURN servers
3. Install/configure `notify_push`
4. Re-test call lifecycle:
- invite
- answer
- ringing stop on both ends
- hangup propagation

Exit criteria:
1. ringing persistence issue is no longer reproducible
2. Talk warning reduced/cleared in admin overview

## Phase 4 - Upgrade Execution

1. Verify app compatibility profile:
- easy/core apps mandatory
- experimental profile intentionally gated

2. Perform Nextcloud upgrade in maintenance window
3. Run post-upgrade maintenance commands
4. Re-run warning checks + Talk reliability tests

Exit criteria:
1. official instance upgraded successfully
2. warning tracker updated with `done`/`accepted_risk`

## Phase 5 - Post-Upgrade Hardening

1. Enable at least one 2FA provider and enforce for admins
2. Configure/test SMTP
3. Confirm monitoring and logs for:
- login failures
- Talk signaling/HPB errors
- resource warnings

## Rollback Triggers

Rollback if any occur:
1. login outage for admin users
2. data integrity concern after migrations
3. persistent call-state regression after HPB/TURN setup

## Verification Commands (Minimal Set)

1. Credential validity:
- WebDAV `PROPFIND` on `/remote.php/dav/files/<user>/` expecting `207`

2. Warning checks:
- Nextcloud admin overview + targeted `occ` checks per warning

3. Talk baseline:
- `occ talk:signaling:list`
- `occ talk:stun:list`
- `occ talk:turn:list`

## Deliverables

1. Updated warning tracker with statuses and evidence
2. Progress note documenting what was fixed and what remains
3. Any runbook/script updates needed for repeatability
