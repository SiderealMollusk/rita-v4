# 0630 - Nextcloud Admin Warning Remediation Tracker

Date: 2026-03-05

## Deprecation

Deprecated. Use the canonical combined plan:
1. [0650-nextcloud-combined-upgrade-and-reliability-plan.md](/Users/virgil/Dev/rita-v4/docs/plans/0650-nextcloud-combined-upgrade-and-reliability-plan.md)

## Scope

This document tracks active warnings shown in Nextcloud Administration -> Overview for the official instance (`cloud.virgil.info`).

Source snapshot includes:
1. Security & setup warnings
2. Operational warnings
3. Missing integrations

## Current Status Model

Use this status field per item:
1. `todo`
2. `in_progress`
3. `blocked`
4. `done`
5. `accepted_risk`

## Tracker

| Warning | Status | Priority | Lane | Planned Fix | Verification |
|---|---|---|---|---|---|
| PDO SQLite driver missing (Collectives search) | todo | P3 | VM package + PHP | Install `php-sqlite3` on nextcloud VM and reload php-fpm | `php -m \| grep -i sqlite` and warning disappears |
| `.mjs` MIME type not served correctly | todo | P1 | Nginx config | Add `mjs` mapping to `application/javascript` (or `text/javascript`) in Nextcloud nginx template | `curl -I https://cloud.virgil.info/...mjs` shows JS MIME |
| Reverse proxy `forwarded_for_headers` incorrect | todo | P0 | Nextcloud config + edge headers | Set `forwarded_for_headers`/trusted proxy values to match Pangolin behavior | `occ config:system:get forwarded_for_headers`, verify admin warning clear |
| PHP memory limit below 512M | todo | P2 | PHP tuning | Raise PHP memory limit to >= `512M` in managed php ini template | `php -i \| grep memory_limit` on VM |
| High-performance backend not configured (Talk) | todo | P2 | Talk HPB | Configure and bind HPB for Talk on dedicated host | Talk admin page shows HPB connected |
| Maintenance window start missing | todo | P2 | Nextcloud config | Set `maintenance_window_start` (low-usage hour) | `occ config:system:get maintenance_window_start` |
| Mimetype migrations available | todo | P2 | DB maintenance | Run `occ maintenance:repair --include-expensive` during maintenance window | Command success + warning clear |
| Missing DB indices (`filecache`, `properties`) | todo | P1 | DB maintenance | Run `occ db:add-missing-indices` | Command success + warning clear |
| OCS provider resolving (`/ocs-provider/`) | todo | P1 | Nginx rewrite | Align nginx rewrite/location rules with Nextcloud recommended config | `curl -I https://cloud.virgil.info/ocs-provider/` and warning clear |
| HSTS header missing | todo | P1 | Edge/security headers | Add `Strict-Transport-Security` at edge/proxy | `curl -I https://cloud.virgil.info` includes HSTS >= 15552000 |
| No second factor provider | todo | P2 | Auth policy | Enable at least one 2FA provider app + enforce policy for admins | Admin Security page shows provider available |
| PHP `getenv("PATH")` empty | blocked | P1 | PHP-FPM environment | Configure PHP-FPM env pass-through and/or `clear_env` policy intentionally | `php -r 'var_dump(getenv("PATH"));'` under FPM context |
| Client Push not installed | todo | P2 | Notify Push | Install/configure Nextcloud Client Push stack | Desktop clients confirm push + warning clear |
| AppAPI default deploy daemon not set | todo | P2 | AppAPI/Flow | Register default deploy daemon in AppAPI settings | AppAPI settings show default daemon |
| Font file loading check failed (`.otf`) | todo | P3 | Self-connect DNS/egress + MIME | Ensure server can resolve/connect trusted domain and serves `.otf` | warning clear after connectivity/MIME fix |
| Default phone region missing | todo | P3 | Nextcloud config | Set `default_phone_region` (ISO 3166-1, likely `US`) | `occ config:system:get default_phone_region` |
| Email server not configured/tested | todo | P2 | SMTP config | Set SMTP in Basic Settings and send test message | test email succeeds, warning clear |
| Errors in log (5 warnings) | todo | P2 | Observability triage | Review warning entries and close root causes | warnings reduced/cleared in admin overview |

## Execution Order

1. Fix edge/security correctness first:
`forwarded_for_headers`, HSTS, OCS provider, `.mjs` MIME.

2. Fix core runtime limits/config:
PHP memory limit, maintenance window, phone region.

3. Run maintenance jobs:
mimetype repair, missing DB indices.

4. Enable optional capability layers:
2FA provider, Client Push, Talk HPB, AppAPI deploy daemon, SMTP.

## Symptom Correlation (Observed)

1. Android Talk calls can connect media while ring state continues indefinitely.
2. Current runtime has no external Talk signaling/STUN/TURN configured:
   - `occ talk:signaling:list` => empty
   - `occ talk:stun:list` => empty
   - `occ talk:turn:list` => empty
3. `notify_push` is not installed, which aligns with stale ringing/presence-notification state.

## Auth Verification Note

Do not use plain `GET` on `/remote.php/dav/files/<user>/` as a password validity check.

Use WebDAV `PROPFIND`:
1. `207` = valid credentials
2. `401` = invalid credentials

## Notes

1. Some warnings are environment-specific and may be expected while features are intentionally not enabled (for example AppAPI daemon or Talk HPB). If deferred, mark as `accepted_risk` with rationale and owner.
2. For each completed item, add command output evidence to a follow-up progress note.
