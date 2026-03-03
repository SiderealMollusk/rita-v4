# 0470 - Nextcloud Live And Bootstrapped
Status: VALIDATED
Date: 2026-03-03

## Summary

Nextcloud is live on the `workload` lane, backed by:
1. external PostgreSQL on `platform-postgres`
2. external Redis on `nextcloud-redis`
3. a single shared v1 instance exposed at `app.virgil.info`

The requested collaboration suite is enabled:
1. `Collectives`
2. `Contacts`
3. `Calendar`
4. `Deck`
5. `Notes`
6. `Tasks`
7. `Talk`

## Validated State

Validated from the live cluster:
1. `pod/nextcloud-*` is `2/2 Running`
2. `pod/nextcloud-redis-master-0` is `1/1 Running`
3. `service/nextcloud` exists in namespace `workload` on port `8080`
4. `php occ status` reports `installed: true`
5. background jobs are set to `cron`

## Important Fixes

### 1. Redis image drift required a temporary workaround

The Redis chart default tried to pull a Bitnami image tag that no longer existed.

The current working release explicitly pins:
1. repository `bitnamilegacy/redis`
2. tag `7.4.2-debian-12-r6`

This is deliberate short-term tech debt, not the final image sourcing strategy.

### 2. DB bootstrap is now canonical and password-safe

The canonical DB/bootstrap path is:
1. `scripts/2-ops/workload/15-bootstrap-nextcloud-db.sh`

That script now:
1. reads the live Kubernetes secrets
2. creates or updates the `nextcloud` role password
3. creates the DB if missing
4. grants DB privileges

This fixed password drift between:
1. the `nextcloud-main` 1Password item
2. the `nextcloud-db-secret` Kubernetes Secret
3. the actual role password in `platform-postgres`

### 3. Suite enablement became install-aware

The canonical Nextcloud bootstrap path is:
1. `scripts/2-ops/workload/16-enable-nextcloud-suite.sh`

That script now:
1. waits for the deployment
2. checks `occ status`
3. runs `maintenance:install` if Nextcloud is still uninstalled
4. enables the collaboration apps
5. sets cron mode

This matters because Helm can leave the deployment healthy while Nextcloud itself is still uninstalled if first-run DB setup races the initial pod start.

### 4. Host-side kube access now prefers project config

The host-side workload scripts now prefer `.labrc` for local operator config, especially:
1. `KUBECONFIG_INTERNAL`
2. `OP_VAULT_ID`

This reduces repeated ad hoc `export KUBECONFIG=...` usage for the canonical runbooks.

## Canonical Secret Contract

V1 converges on one 1Password item:
1. item `nextcloud-main`
2. fields:
   - `nextcloud-admin`
   - `nextcloud-db`
   - `nextcloud-redis`

The workload `ExternalSecret` resources derive the Kubernetes secrets from that single item.

## Exposure Model

V1 public host:
1. `app.virgil.info`

V1 routing:
1. DNS `CNAME app -> pangolin.virgil.info`
2. Pangolin public resource targeting the `ops-brain` site
3. backend target `http://nextcloud.workload.svc.cluster.local:8080`
4. Pangolin backend SSL remains enabled for the working v1 path, even though the target is the in-cluster Nextcloud service on port `8080`

This keeps v1 simple and avoids introducing a separate workload-local Newt/site before it is needed.

## Remaining Tech Debt

1. Redis still depends on a legacy image namespace workaround
2. Jitsi is not yet integrated; `Talk` is live, but video-conferencing backend choice and configuration remain a separate step
3. org/group bootstrap automation is still the next layer, not done yet

## Next Step

The base suite is now good enough to move on to:
1. group/org bootstrap automation inside the shared instance
2. opinionated defaults for folders, boards, and collaboration spaces
