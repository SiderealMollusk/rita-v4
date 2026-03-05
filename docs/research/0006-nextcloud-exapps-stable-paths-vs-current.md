# 0006 - Nextcloud ExApps Stable Paths Vs Current Setup
Date: 2026-03-05
Status: Active research note

## Scope
1. Research the most stable current paths to run Nextcloud ExApps (AppAPI).
2. Compare those paths against the current `cloud.virgil.info` repo/operator setup.

## Source-backed stable paths (current docs)

### Path A (recommended): HaRP-based AppAPI deploy daemon
Official AppAPI docs describe HaRP as the recommended deployment configuration for most setups.

Characteristics:
1. AppAPI daemon uses HaRP endpoint rather than direct docker socket path.
2. Host reverse proxy should split traffic so ExApp callbacks under `/exapps/` reach HaRP.
3. Nextcloud app UI remains served by Nextcloud, while ExApp runtime/callback path is routed to daemon side.

Why this is stable:
1. aligns with current upstream guidance
2. better separation between Nextcloud core and ExApp runtime plane
3. avoids direct `www-data` Docker socket coupling model

### Path B (supported fallback): Docker Socket Proxy / docker-local style
Official docs still include Docker-socket-proxy-based deployment.

Characteristics:
1. AppAPI uses Docker API path for deploy operations.
2. Works well for simple single-host deployments.
3. Not the preferred modern path when HaRP is available.

### Path C (specialized): manual-install daemon mode
This is operationally valid for custom environments where automation/deploy is externally managed, but it is not the easiest or most "just works" path.

## What you are currently doing (repo + screenshot evidence)

### Official instance topology today
From repo:
1. official instance is VM-backed: `cloud.virgil.info -> 192.168.6.183:80` ([instances.yaml](/Users/virgil/Dev/rita-v4/ops/nextcloud/instances.yaml:1))
2. Pangolin blueprint for official instance forwards directly to VM host:80 ([nextcloud-cloud.blueprint.yaml](/Users/virgil/Dev/rita-v4/ops/pangolin/blueprints/ops-brain/nextcloud-cloud.blueprint.yaml:1))

### AppAPI daemon registration path in scripts
From runbook script:
1. default mode is `docker-local` ([18-register-nextcloud-appapi-daemon.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/18-register-nextcloud-appapi-daemon.sh:14))
2. only `docker-local|manual-install` are supported modes ([18-register-nextcloud-appapi-daemon.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/18-register-nextcloud-appapi-daemon.sh:33))
3. `docker-local` default host is `/var/run/docker.sock` ([18-register-nextcloud-appapi-daemon.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/18-register-nextcloud-appapi-daemon.sh:86))
4. optional preparation explicitly grants `www-data` Docker access ([18-register-nextcloud-appapi-daemon.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/18-register-nextcloud-appapi-daemon.sh:138))

### Deploy script mismatch to note
1. ExApp deploy script defaults daemon name to `manual_install_vm` ([19-deploy-nextcloud-flow-exapp.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/19-deploy-nextcloud-flow-exapp.sh:16))
2. register script defaults daemon name to `docker_local_vm` in default mode ([18-register-nextcloud-appapi-daemon.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/18-register-nextcloud-appapi-daemon.sh:82))

This default mismatch can create avoidable operator confusion if `--daemon-name` is not passed consistently.

### Screenshot signal
Your admin warning says default deploy daemon is not using HaRP, which is consistent with a docker-local default daemon being active.

## Direct comparison: stable path vs your current path

1. **Daemon type**
- Stable/recommended: HaRP
- Current: docker-local `/var/run/docker.sock`
- Gap: high

2. **Routing shape for ExApp callbacks**
- Stable/recommended: explicit `/exapps/` path routing to daemon side
- Current official VM path: direct pass-through to Nextcloud VM (`cloud.virgil.info -> :80`)
- Gap: medium/high (depends on local Nginx split actually configured on VM)

3. **Operational consistency**
- Stable/recommended: one canonical daemon path + consistent defaults
- Current: mixed-era artifacts (legacy k8s HaRP manifests + VM docker-local runbooks)
- Gap: medium

4. **Security/least privilege posture**
- Stable/recommended: avoid broad direct docker socket coupling where possible
- Current: `www-data` docker-group path in prepare step
- Gap: medium

## Most pragmatic stabilization plan for your setup

### Step 1 - Pick one canonical official-instance AppAPI architecture
For `cloud.virgil.info` VM-first mode, choose and document either:
1. HaRP-on-VM (recommended)
2. docker-local (accepted risk, if you intentionally defer HaRP)

### Step 2 - Align runbook defaults to chosen path
1. If choosing HaRP, add `--mode harp` support to script `18` and make it default.
2. Make script `19` default daemon name match script `18` default daemon name.

### Step 3 - Make `/exapps/` routing explicit for official domain
1. Ensure `cloud.virgil.info` route and VM Nginx config include explicit `/exapps/` forwarding for HaRP path.
2. Keep this distinct from legacy `app.virgil.info` k8s routing assumptions.

### Step 4 - Add verification gates
1. `occ app_api:daemon:list` shows intended daemon and default.
2. Nextcloud admin warning for deploy daemon is cleared (or intentionally accepted risk).
3. Flow/another ExApp deploys without daemon accessibility errors.

## Known non-architecture blocker still present
Your repo documents a Flow `1.3.1` OSS regression and a workaround script.
Even with correct AppAPI/daemon architecture, Flow can still fail at runtime until that upstream behavior is resolved or patched.

## Primary sources
1. Nextcloud ExApps overview: https://docs.nextcloud.com/server/latest/admin_manual/exapps_management/ExAppsOverview.html
2. Nextcloud AppAPI and external apps: https://docs.nextcloud.com/server/latest/admin_manual/exapps_management/AppAPIAndExternalApps.html
3. Nextcloud deploy configurations: https://docs.nextcloud.com/server/latest/admin_manual/exapps_management/DeployConfigurations.html
4. Nextcloud managing deploy daemons: https://docs.nextcloud.com/server/latest/admin_manual/exapps_management/ManagingDeployDaemons.html
5. Repo current daemon script: [18-register-nextcloud-appapi-daemon.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/18-register-nextcloud-appapi-daemon.sh)
6. Repo current ExApp deploy script: [19-deploy-nextcloud-flow-exapp.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/19-deploy-nextcloud-flow-exapp.sh)
7. Official instance routing pointer: [instances.yaml](/Users/virgil/Dev/rita-v4/ops/nextcloud/instances.yaml)
