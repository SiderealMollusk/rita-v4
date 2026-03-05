# 0760 - Nextcloud AppAPI HaRP VM Default and Warning Burndown
Date: 2026-03-05

## What changed

1. Added canonical VM AppAPI/HaRP runtime SoT:
- [ops/nextcloud/appapi-runtime.yaml](/Users/virgil/Dev/rita-v4/ops/nextcloud/appapi-runtime.yaml)

2. Added VM-native HaRP runtime apply script:
- [46-configure-nextcloud-appapi-harp-runtime.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/46-configure-nextcloud-appapi-harp-runtime.sh)
- behavior:
  - resolves HaRP shared key from OP ref (or literal secret)
  - installs/starts Docker on `nextcloud-vm` if missing
  - runs HaRP container bound to `127.0.0.1:8780` and `127.0.0.1:8782`
  - registers `harp_local_vm` as default AppAPI daemon through script `18`

3. Updated AppAPI script defaults to HaRP:
- [18-register-nextcloud-appapi-daemon.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/18-register-nextcloud-appapi-daemon.sh)
  - default mode now `harp`
  - supports `--harp-*` flags and OP-ref secret resolution
  - still supports explicit `docker-local` and `manual-install` fallback modes

4. Aligned downstream defaults:
- [19-deploy-nextcloud-flow-exapp.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/19-deploy-nextcloud-flow-exapp.sh) now defaults daemon name to `harp_local_vm`
- [34-verify-nextcloud-exapps-health.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/34-verify-nextcloud-exapps-health.sh) now expects `harp_local_vm` by default

5. Updated workload runbook index:
- [scripts/2-ops/workload/README.md](/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/README.md)

## Runtime result (validated)

1. `app_api:daemon:list` now shows:
- default daemon: `harp_local_vm`
- `Is HaRP: yes`
- host `127.0.0.1:8780`
- FRP address `127.0.0.1:8782`

2. ExApps daemon-only verification passes:
- `EXAPP_REQUIRE_APP_ENABLED=0 ./scripts/2-ops/workload/34-verify-nextcloud-exapps-health.sh`

3. Log warning noise reset:
- `45-flush-nextcloud-logs.sh` run with confirm token
- `nextcloud.log` / nginx logs truncated to 0

4. Maintenance warning burndown actions executed:
- `occ maintenance:repair --include-expensive`
- `occ db:add-missing-indices` (successful on rerun)

## Remaining warnings expected

1. `Second factor configuration` (policy choice; no 2FA provider enabled)
2. `PHP getenv` (PHP-FPM env propagation check; may require explicit FPM pool env config)
3. `Recording backend` / `SIP configuration` (Talk optional integrations)
4. `Email test` (SMTP not configured)
