# 0570 - Nextcloud Core VM Live And Verified

Date: 2026-03-04

## Summary

`nextcloud-core` is now live and verified on the dedicated VM at `192.168.6.183`.

The VM-first install path completed successfully:
1. [11-bootstrap-nextcloud-host.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/11-bootstrap-nextcloud-host.sh)
2. [12-install-nextcloud-core.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/12-install-nextcloud-core.sh)
3. [13-verify-nextcloud-core.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/13-verify-nextcloud-core.sh)

## Validated State

Validated on `nextcloud-core`:
1. `nginx` running
2. `php8.2-fpm` running
3. `redis-server` running
4. `cron` running
5. PostgreSQL accepting local connections
6. `php occ status` reports `installed: true`
7. `memcache.local = \OC\Memcache\APCu`
8. `memcache.locking = \OC\Memcache\Redis`
9. `backgroundjobs_mode = cron`
10. `http://127.0.0.1/status.php` returns the installed Nextcloud status payload when addressed with the canonical host header `app.virgil.info`

## Important Operator Outcome

The install path now works without manual secret exports.

The immediate blocker that forced this cleanup was removed:
1. secret-reading runbooks no longer require a human `op signin` session specifically
2. they now accept either:
   - a human 1Password session, or
   - `OP_SERVICE_ACCOUNT_TOKEN`

That means the canonical `nextcloud-core` bring-up path is now compatible with the repo's existing operator environment instead of fighting it.

## Fixes Required During Bring-Up

This live pass surfaced and corrected three real implementation issues:

1. the initial 1Password helper behavior rejected service-account mode for secret reads
2. the PostgreSQL role/database tasks in the install playbook had quoting and `become_user` issues
3. the web-stack handlers needed to flush before the DB/app install phase so a partial failure would not leave `nginx`, `php-fpm`, or `redis` running stale config

The verification playbook was also corrected to match Debian and this Nextcloud version:
1. PostgreSQL is checked by readiness rather than a fragile unit-name assumption
2. background jobs are checked through `config:app:get core backgroundjobs_mode`
3. the local HTTP probe uses the canonical host header

## Current Position

The repo now has two distinct Nextcloud stories:
1. the older validated k3s-hosted shared instance at `app.virgil.info`
2. the newly validated dedicated `nextcloud-core` VM baseline

The VM path is now real enough to support the next decision:
1. whether to migrate the public route from the old shared instance to the new VM
2. whether to stand up `nextcloud-talk-hpb`
3. whether to revisit Flow at all, or move to standalone Windmill-first integration

## Next Likely Steps

1. capture the canonical public routing plan for moving `app.virgil.info` onto `nextcloud-core`
2. decide whether the old k3s-hosted Nextcloud remains transitional or should now be treated as legacy
3. keep Flow/Windmill work separate from the core VM validation that was just achieved
