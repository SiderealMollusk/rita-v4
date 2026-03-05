# 0770 - Nextcloud HaRP Baseline Snapshot
Date: 2026-03-05

## Snapshot

1. Coordinated Nextcloud pair snapshot completed:
- `p-46-appapi-harp-stabilized-260305153507`
- VM `9301` (`nextcloud-core`)
- VM `9302` (`nextcloud-talk-hpb`)

2. Snapshot mode:
- crash-consistent (`vmstate=0`) because QGA is not reachable on both VMs

## Baseline state at snapshot time

1. AppAPI daemon default is now HaRP on VM path:
- daemon: `harp_local_vm`
- `Is HaRP: yes`
- host: `127.0.0.1:8780`
- FRP: `127.0.0.1:8782`

2. AppAPI/HaRP is codified in repo:
- [ops/nextcloud/appapi-runtime.yaml](/Users/virgil/Dev/rita-v4/ops/nextcloud/appapi-runtime.yaml)
- [46-configure-nextcloud-appapi-harp-runtime.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/46-configure-nextcloud-appapi-harp-runtime.sh)
- [18-register-nextcloud-appapi-daemon.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/18-register-nextcloud-appapi-daemon.sh) defaults to `harp`

3. Warning burndown actions already executed before snapshot:
- log flush (`45-flush-nextcloud-logs.sh`)
- `occ maintenance:repair --include-expensive`
- `occ db:add-missing-indices` (successful)

## Remaining warning classes (expected next)

1. `PHP getenv` (FPM env propagation)
2. policy/integration warnings:
- second factor provider
- SMTP/email test
- Talk recording/SIP (optional integrations)
