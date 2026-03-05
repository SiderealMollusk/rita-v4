# 0007 - ExApps Handoff For Struggling Agent
Date: 2026-03-05
Status: Active handoff note

## Purpose
Fast handoff for the current ExApps/AppAPI failure mode on `cloud.virgil.info`.

## What is happening
1. Nextcloud admin warning indicates default deploy daemon is not using HaRP.
2. Current runbook defaults use `docker-local` daemon (`/var/run/docker.sock`) instead of HaRP.
3. Official-instance routing is VM direct pass-through (`cloud.virgil.info -> 192.168.6.183:80`), so ExApp `/exapps/` routing must be explicitly handled on that VM path.
4. Flow may still fail after daemon fixes due to known upstream Flow `1.3.1` OSS regression.

## Evidence in repo
1. Daemon registration defaults to docker-local:
- [18-register-nextcloud-appapi-daemon.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/18-register-nextcloud-appapi-daemon.sh:14)
- [18-register-nextcloud-appapi-daemon.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/18-register-nextcloud-appapi-daemon.sh:82)

2. Deploy script default daemon name differs:
- [19-deploy-nextcloud-flow-exapp.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/19-deploy-nextcloud-flow-exapp.sh:16)

3. Official domain target is VM:
- [instances.yaml](/Users/virgil/Dev/rita-v4/ops/nextcloud/instances.yaml:10)
- [nextcloud-cloud.blueprint.yaml](/Users/virgil/Dev/rita-v4/ops/pangolin/blueprints/observatory/nextcloud-cloud.blueprint.yaml:11)

4. AppAPI warning tracked in plan:
- [0650-nextcloud-combined-upgrade-and-reliability-plan.md](/Users/virgil/Dev/rita-v4/docs/plans/0650-nextcloud-combined-upgrade-and-reliability-plan.md:134)

## Stable path (what to do)
1. Standardize on HaRP-based daemon for official VM instance.
2. Ensure `/exapps/` path routing reaches HaRP while normal paths continue to Nextcloud.
3. Make daemon defaults consistent across scripts (`18` and `19`).
4. Re-test ExApp deploy after daemon/routing corrections.

## Immediate operator checklist
1. Confirm daemon state:
- `sudo -u www-data php /var/www/nextcloud/occ app_api:daemon:list`

2. Confirm default daemon is set and accessible in AppAPI settings.

3. Confirm edge routing behavior for official domain:
- `/exapps/` requests route to daemon side
- non-`/exapps/` routes still reach Nextcloud

4. Deploy ExApp and inspect AppAPI status:
- `sudo -u www-data php /var/www/nextcloud/occ app_api:app:list`

5. If Flow fails on known OSS endpoints, apply temporary patch runbook:
- [20-patch-nextcloud-flow-oss.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/20-patch-nextcloud-flow-oss.sh)

## Don’t confuse these two architectures
1. Legacy k8s path (`app.virgil.info`, nextcloud-edge, in-cluster HaRP) is separate history.
2. Official current path is VM-first (`cloud.virgil.info`) and must be debugged as VM-first.

## Primary references
1. Full comparison memo: [0006-nextcloud-exapps-stable-paths-vs-current.md](/Users/virgil/Dev/rita-v4/docs/research/0006-nextcloud-exapps-stable-paths-vs-current.md)
2. Nextcloud ExApps overview: https://docs.nextcloud.com/server/latest/admin_manual/exapps_management/ExAppsOverview.html
3. Nextcloud AppAPI and external apps: https://docs.nextcloud.com/server/latest/admin_manual/exapps_management/AppAPIAndExternalApps.html
4. Nextcloud deploy configurations: https://docs.nextcloud.com/server/latest/admin_manual/exapps_management/DeployConfigurations.html
5. Nextcloud managing deploy daemons: https://docs.nextcloud.com/server/latest/admin_manual/exapps_management/ManagingDeployDaemons.html
