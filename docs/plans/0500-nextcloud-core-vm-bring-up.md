# 0500 - Nextcloud Core VM Bring-Up
Status: ACTIVE
Date: 2026-03-04

## Goal

Bring up `nextcloud-core` on the dedicated VM as a boring, fast baseline:
1. plain VM install
2. local `PostgreSQL`
3. local `Redis`
4. `nginx + php-fpm`
5. production `Cron`
6. `APCu + Redis + OPcache` enabled from day one

Keep `Flow`, `AppAPI`, `HaRP`, and Windmill-specific integration out of the first-pass install.
The objective is a stable Nextcloud core that can later talk to standalone Windmill without inheriting ExApp fragility on day one.

## Why This Path

For the dedicated VM build, the easiest performance wins are also baseline hygiene:
1. `APCu` for local cache
2. `Redis` for distributed cache and file locking
3. `Cron` background jobs instead of `AJAX`
4. sane `OPcache` settings

These are not risky late optimizations.
They are the right default shape for a production-ish self-hosted Nextcloud.

## Operator Sequence

1. Rebuild the VM if needed with [09-rebuild-nextcloud-vm.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/09-rebuild-nextcloud-vm.sh)
2. Bootstrap the host baseline with [11-bootstrap-nextcloud-host.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/11-bootstrap-nextcloud-host.sh)
3. Export the install-time environment:
   - `NEXTCLOUD_ADMIN_USER`
   - optional: `NEXTCLOUD_DB_NAME`
   - optional: `NEXTCLOUD_DB_USER`
   - optional: `NEXTCLOUD_VERSION`
   - optional: `NEXTCLOUD_TRUSTED_PROXY`
   - optional: `NEXTCLOUD_OVERWRITE_PROTOCOL`
   - optional secret-ref overrides:
     - `NEXTCLOUD_OP_ITEM`
     - `NEXTCLOUD_ADMIN_PASSWORD_OP_REF`
     - `NEXTCLOUD_DB_PASSWORD_OP_REF`
4. Install the core stack with [12-install-nextcloud-core.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/12-install-nextcloud-core.sh)
5. Verify the baseline with [13-verify-nextcloud-core.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/13-verify-nextcloud-core.sh)
6. Only after the VM is stable, decide on:
   - Pangolin routing
   - data migration from the k3s-hosted Nextcloud
   - standalone Windmill integration
   - whether Flow should be reintroduced at all

## Baked-In Performance Baseline

The current runbooks/playbooks intentionally bake these defaults into the initial install:

1. `APCu`
   - `memcache.local = \OC\Memcache\APCu`
   - `apc.enable_cli=1`
   - `apc.shm_size=128M`
2. `Redis`
   - `memcache.distributed = \OC\Memcache\Redis`
   - `memcache.locking = \OC\Memcache\Redis`
   - local redis on `127.0.0.1:6379`
3. `Cron`
   - `php occ background:cron`
   - `/etc/cron.d/nextcloud`
4. `OPcache`
   - enabled
   - `memory_consumption=128`
   - `interned_strings_buffer=16`
   - `max_accelerated_files=10000`
   - `revalidate_freq=60`

## Secret Handling

The install wrapper is intentionally `op`-first.

Default behavior:
1. `NEXTCLOUD_DOMAIN` defaults from repo config to `app.virgil.info`
2. `NEXTCLOUD_ADMIN_USER` defaults to the current shell user unless explicitly set
3. `NEXTCLOUD_ADMIN_PASSWORD` defaults to `op://$OP_VAULT_ID/nextcloud-main/nextcloud-admin`
4. `NEXTCLOUD_DB_PASSWORD` defaults to `op://$OP_VAULT_ID/nextcloud-main/nextcloud-db`

This keeps stable non-secret operator context in the repo-local environment and keeps actual secrets in 1Password.

## Non-Goals For This Pass

1. `Flow`
2. `AppAPI`
3. `HaRP`
4. remote ExApp containers
5. Talk `HPB` installation
6. full migration of user data from the k3s-hosted instance

## Expected Outcome

At the end of this bring-up, `nextcloud-core` should be:
1. reachable locally over `HTTP` on the VM
2. using `PostgreSQL` and `Redis`
3. running with `Cron` background jobs
4. already carrying the obvious cache/runtime tuning that would otherwise get added later

That is the right foundation for a Windmill-friendly architecture where automation is added after the core collaboration stack is boring and fast.
