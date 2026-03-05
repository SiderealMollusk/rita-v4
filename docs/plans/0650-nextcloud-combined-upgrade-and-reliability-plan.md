# 0650 - Nextcloud Combined Upgrade And Reliability Plan

Date: 2026-03-05

## Status

Canonical active plan for Nextcloud warning remediation, Talk reliability, and upgrade execution.

Current checkpoint (2026-03-05):
1. Phase 2 core platform correctness work is substantially complete (headers, proxy handling, OCS routing, MIME handling, DB maintenance, memory/window/phone-region defaults).
2. Plan remains active; Talk reliability and hardening scope is still open.
3. Latest evidence snapshots:
- [0610-nextcloud-phase2-core-warning-remediation.md](/Users/virgil/Dev/rita-v4/docs/progress_log/0610-nextcloud-phase2-core-warning-remediation.md)
- [0620-nextcloud-admin-overview-post-remediation-snapshot.md](/Users/virgil/Dev/rita-v4/docs/progress_log/0620-nextcloud-admin-overview-post-remediation-snapshot.md)
- [0630-nextcloud-talk-hpb-runtime-wired-and-upgraded.md](/Users/virgil/Dev/rita-v4/docs/progress_log/0630-nextcloud-talk-hpb-runtime-wired-and-upgraded.md)
- [0640-nextcloud-talk-websocket-https-fix-and-log-cleanup.md](/Users/virgil/Dev/rita-v4/docs/progress_log/0640-nextcloud-talk-websocket-https-fix-and-log-cleanup.md)
- [0650-nextcloud-talk-reapply-and-baseline-verify-success.md](/Users/virgil/Dev/rita-v4/docs/progress_log/0650-nextcloud-talk-reapply-and-baseline-verify-success.md)

Supersedes:
1. [0630-nextcloud-admin-warning-remediation-tracker.md](/Users/virgil/Dev/rita-v4/docs/plans/0630-nextcloud-admin-warning-remediation-tracker.md)
2. [0640-nextcloud-official-upgrade-and-talk-reliability-plan.md](/Users/virgil/Dev/rita-v4/docs/plans/0640-nextcloud-official-upgrade-and-talk-reliability-plan.md)

Related debt tracking:
1. [0660-nextcloud-talk-secret-management-tech-debt.md](/Users/virgil/Dev/rita-v4/docs/plans/0660-nextcloud-talk-secret-management-tech-debt.md)
2. [0670-nextcloud-talk-operationalization-tech-debt.md](/Users/virgil/Dev/rita-v4/docs/plans/0670-nextcloud-talk-operationalization-tech-debt.md)

## Goal

Bring the official Nextcloud instance (`cloud.virgil.info`) to a stable, supportable state with:
1. high-priority admin warnings closed
2. reliable Talk call-state behavior (no persistent ringing after answer)
3. controlled upgrade path with rollback checkpoints

## Source Of Truth Inputs

1. Official instance pointer:
- [instances.yaml](/Users/virgil/Dev/rita-v4/ops/nextcloud/instances.yaml)

2. Install/runtime runbooks:
- [12-install-nextcloud-core.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/12-install-nextcloud-core.sh)
- [33-install-nextcloud-core.yml](/Users/virgil/Dev/rita-v4/ops/ansible/playbooks/33-install-nextcloud-core.yml)

3. Password rotation runbooks:
- [22-rotate-nextcloud-user-password.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/22-rotate-nextcloud-user-password.sh)
- [23-rotate-nextcloud-virgil-admin-password.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/23-rotate-nextcloud-virgil-admin-password.sh)
- [24-rotate-nextcloud-virgil-password.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/24-rotate-nextcloud-virgil-password.sh)

## Execution Phases

### Phase 1 - Preflight And Safety

1. freeze change window
2. snapshot VM + backup DB/config
3. validate admin access and password rotation scripts
4. capture baseline warnings + Talk config outputs

Gate to next phase:
1. rollback assets exist
2. baseline evidence captured

### Phase 2 - Core Warning Closure (P0/P1 first)

Execute in this order:
1. reverse-proxy correctness (`forwarded_for_headers`, OCS provider rewrite)
2. security headers (`HSTS`)
3. static MIME correctness (`.mjs`)
4. DB maintenance (`db:add-missing-indices`, expensive repairs)

Then complete:
1. PHP memory >= 512M
2. maintenance window
3. default phone region

Phase status:
1. in_progress (major items complete; residual warnings tracked in Phase 5/ops integrations)

### Phase 3 - Talk Reliability Baseline

1. configure HPB
2. configure STUN/TURN
3. install/configure `notify_push`
4. validate ringing-state lifecycle on mobile + desktop

Current observed gap that motivates this phase:
1. media can connect while ringing state persists
2. `talk:signaling:list`, `talk:stun:list`, and `talk:turn:list` were empty
3. `notify_push` not present

Phase status:
1. in_progress

### Phase 4 - Upgrade Execution

1. verify app profile gates:
   - easy/core apps always enabled
   - experimental apps explicitly gated
2. perform Nextcloud upgrade in maintenance window
3. run post-upgrade repair/migration commands
4. rerun warning + Talk verification suite

### Phase 5 - Hardening And Closeout

1. enable at least one 2FA provider for admins
2. configure/test SMTP
3. close remaining warnings or mark `accepted_risk` with owner/rationale
4. publish progress note with evidence

Phase status:
1. in_progress

## Combined Tracker

Use statuses:
1. `todo`
2. `in_progress`
3. `blocked`
4. `done`
5. `accepted_risk`

| Item | Status | Priority | Phase | Verification |
|---|---|---|---|---|
| Reverse proxy `forwarded_for_headers` | done | P0 | 2 | `occ config:system:get forwarded_for_headers` + warning clear |
| OCS provider resolving (`/ocs-provider/`) | done | P1 | 2 | `curl -I https://cloud.virgil.info/ocs-provider/` + warning clear |
| HSTS header | done | P1 | 2 | `curl -I https://cloud.virgil.info` includes HSTS >= 15552000 |
| `.mjs` JavaScript MIME | done | P1 | 2 | `curl -I ...mjs` returns JS MIME |
| Missing DB indices | done | P1 | 2 | `occ db:add-missing-indices` success |
| Mimetype migrations | done | P2 | 2/4 | `occ maintenance:repair --include-expensive` success |
| PHP memory limit >= 512M | done | P2 | 2 | `php -i | grep memory_limit` |
| Maintenance window start | done | P2 | 2 | `occ config:system:get maintenance_window_start` |
| High-performance backend (Talk) | in_progress | P2 | 3 | Talk admin warning cleared and browser call controls enabled |
| STUN/TURN configured | in_progress | P2 | 3 | `occ talk:stun:list`, `occ talk:turn:list` non-empty |
| `notify_push` installed/configured | done | P2 | 3 | app present + push validation |
| Ringing persistence repro test | todo | P1 | 3 | no persistent ringing after call answer |
| AppAPI default deploy daemon | todo | P2 | 5 | AppAPI settings show default daemon |
| 2FA provider available | todo | P2 | 5 | admin security page shows provider |
| PHP `getenv("PATH")` warning | blocked | P1 | 2/5 | FPM env strategy decided and validated |
| Collectives SQLite warning | done | P3 | 5 | `php -m | grep -i sqlite` includes `pdo_sqlite` |
| Font `.otf` self-check warning | todo | P3 | 5 | warning clear after DNS/self-connect + MIME check |
| Default phone region | done | P3 | 2 | `occ config:system:get default_phone_region` |
| Email config/test | todo | P2 | 5 | Nextcloud test email succeeds |
| Log warning backlog | in_progress | P2 | 5 | admin warning count reduced/cleared |

## Verification Standard

For auth checks, use WebDAV `PROPFIND` (not plain `GET`):
1. `207` = valid credentials
2. `401` = invalid credentials

## Rollback Triggers

Rollback immediately if:
1. admin login outage
2. data integrity concern post-migration
3. Talk call-state regression worsens after Phase 3 changes
