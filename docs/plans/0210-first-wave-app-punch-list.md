# 0210 - First Wave App Punch List
Status: SUPERSEDED
Date: 2026-03-02
Latest validated progress: `docs/progress_log/0450-platform-postgres-live-with-image-workaround.md`

Superseded by: `docs/plans/0220-nextcloud-first-collaboration-suite.md`
Deprecated direction: `Leantime` is no longer an active first-wave target and should be treated as intentionally deferred in favor of the live `Nextcloud` suite.

## Goal
Turn the now-working three-node internal cluster into a usable app platform by executing the first intentionally ordered app wave:
1. `platform-postgres`
2. `Leantime` (deprecated)
3. `Zulip`
4. `n8n`
5. document `Jellyfin` as deferred
6. document `PeerTube` as deferred

## Locked Decisions
These are treated as decided inputs for this phase:

### Placement
1. `platform-postgres` runs on `platform`
2. `Leantime` runs on `workload`
3. `Zulip` runs on `workload`
4. `n8n` runs on `workload` only if a later reason appears; for this phase it is treated as private and can remain platform-adjacent
5. `observatory` is not a general app lane
6. `platform` is not the default general app lane
7. `workload` is the intended default home for general workloads

### Exposure
1. `n8n` is private
2. `Leantime` is public through Pangolin
3. `Zulip` is public through Pangolin
4. `Jellyfin` and `PeerTube` are not part of the current apply phase

### Data / DB
1. `platform-postgres` is the shared Postgres service for Postgres-oriented platform and app needs
2. `Leantime` is explicitly not forced onto Postgres
3. `Leantime` keeps its own MySQL/MariaDB-backed app data shape
4. large-media workloads are deferred until storage improves

### Auth
1. no central IdP yet
2. phase-1 auth remains app-local

## Why This Order
### 1. `platform-postgres`
This creates the first shared stateful primitive without immediately forcing app-facing UX decisions.

### 2. `Leantime` (deprecated)
This was the earlier first public work-management candidate, but it is now deprecated in favor of using `Nextcloud` as the collaboration/workspace center.

### 3. `Zulip`
This is the chosen default chat/collaboration candidate and the first app likely to create visible user/account pressure.

### 4. `n8n`
This is useful, but it is private and more platform-adjacent than the work/friend-facing apps.

### 5. `Jellyfin` and `PeerTube`
These are deliberately deferred because:
1. storage is not ready
2. large bulk state is not the current focus
3. they add avoidable media-path complexity before the lighter app wave is proven

## Phase Scope
### In Scope
1. install and bridge External Secrets on the internal cluster
1. deploy `platform-postgres`
2. `Leantime` is no longer part of the active path
3. deploy `Zulip`
4. deploy `n8n` as a private service
5. document the deferred state for `Jellyfin` and `PeerTube`
6. verify placement, exposure class, and storage expectations for each

### Out Of Scope
1. central IdP
2. `Gitea`
3. `Jellyfin` deployment
4. `PeerTube` deployment
5. final backup implementation
6. final taints

## Stage 0 - External Secrets Bridge
### Target
Install External Secrets Operator on the internal cluster and bridge it to 1Password before the first secret-backed platform app deploys.

### Why
`platform-postgres` already depends on:
1. `ExternalSecret`
2. `ClusterSecretStore`
3. 1Password-backed secret material

Without ESO, the shared Postgres path is blocked before Helm even matters.

### Deliverables
1. ESO installed on the internal cluster
2. `op-token` secret present in `external-secrets`
3. `onepassword-cluster-store` valid and `Ready`

### Verify
1. `kubectl get crd externalsecrets.external-secrets.io`
2. `kubectl get pods -n external-secrets`
3. `kubectl get clustersecretstore onepassword-cluster-store`

## Stage 1 - `platform-postgres`
### Target
Stand up one shared Postgres service on `platform`.

### Status
Completed with a temporary image-source workaround.

### Questions To Resolve
1. chart/operator choice
2. secret contract
3. database/user creation contract
4. placement rules so it stays off `observatory`

### Deliverables
1. GitOps manifests for `platform-postgres`
2. PVC
3. service/secret contract
4. verification output

### Verify
1. pod `Ready`
2. PVC bound
3. service reachable in-cluster
4. placement lands on `platform`

## Stage 2 - `Leantime` (deprecated)
### Target
This stage is intentionally not being executed. `Nextcloud` replaced `Leantime` as the first collaboration/work-management surface.

### Data Shape
1. app deployment on `workload`
2. MySQL/MariaDB backing DB
3. persistent app volumes for userfiles/plugins/logs as needed

### Exposure
1. Pangolin Public Resource

### Verify
1. app is reachable through Pangolin
2. app state is persistent
3. placement lands on `workload`
4. no accidental dependence on `platform-postgres`

## Stage 3 - `Zulip`
### Target
Deploy Zulip as the default chat/collaboration surface on `workload`.

### Data Shape
1. app on `workload`
2. Postgres-backed
3. persistent upload/media state

### Exposure
1. Pangolin Public Resource

### Verify
1. app reachable through Pangolin
2. Postgres connectivity healthy
3. placement lands on `workload`
4. good enough to serve as the first “serious + friend + agent-visible” chat surface

## Stage 4 - `n8n`
### Target
Deploy `n8n` as a private automation service.

### Data Shape
1. Postgres-backed if practical
2. persistent encryption key

### Exposure
1. Pangolin Private Resource or otherwise private-only access path
2. do not make it a generally public browser surface in this phase

### Verify
1. UI reachable privately
2. webhooks/access pattern is deliberate, not accidental
3. app does not become a surprise public endpoint

## Stage 5 - Deferred Media Apps
### `Jellyfin`
Document as deferred because:
1. storage is not ready
2. media bulk data is not the current priority

### `PeerTube`
Document as deferred because:
1. storage is not ready
2. it is heavier than `Jellyfin`
3. federation/domain/storage choices are not worth front-loading yet

## Placement Guardrails
1. no general workloads on `observatory`
2. do not treat `platform` as overflow app capacity by default
3. place general apps on `workload`
4. keep `platform` for platform primitives and platform-adjacent services

## Exposure Guardrails
1. public app UIs go through Pangolin Public Resources
2. private operator/automation tools stay private
3. internal service traffic remains native to k3s, not Pangolin-mediated

## DB Guardrails
1. use `platform-postgres` where the app naturally wants Postgres
2. do not force MySQL-oriented apps into Postgres
3. accept that one shared Postgres service does not imply one universal DB engine

## Success Criteria
This phase is successful when:
1. `platform-postgres` is healthy on `platform`
2. `Leantime` remains deferred and is not part of the active platform path
3. `Zulip` is healthy and public on `workload`
4. `n8n` is healthy and private
5. `Jellyfin` and `PeerTube` are explicitly deferred, not half-started

## Immediate Next Action
Start with:
1. chart/operator choice for `platform-postgres`
2. secret and DB contract for apps that will consume it
