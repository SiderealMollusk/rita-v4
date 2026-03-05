# 0160 - Platform Worker Expansion With Flux, Gitea, and Shared Postgres
Status: ACTIVE
Date: 2026-03-01

## Goal
Expand the current internal k3s cluster beyond `observatory`, convert the NUC into a clean `platform-node` worker node, and establish the first declarative platform-services foundation for:
1. `Flux`
2. `Gitea`
3. shared platform/app `Postgres`
4. automatic observability defaults

This plan also locks a boundary between:
1. `observatory` as the operator/bootstrap edge
2. `platform` capacity as the preferred home of clean IoC-managed services

## Freshness
Start with the latest relevant progress note before trusting this plan:
1. [0390-platform-flux-gitea-direction-locked.md](/Users/virgil/Dev/rita-v4/docs/progress_log/0390-platform-flux-gitea-direction-locked.md)

## Decisions Locked
### Cluster Shape
Use one internal k3s cluster for now.

Do not create a second independent cluster on the NUC.

Reason:
1. one cluster keeps GitOps, secrets, monitoring, and placement simpler
2. a second cluster adds operational overhead before there is a real isolation need
3. the current need is more schedulable capacity, not a second control plane

### Node Roles
1. `observatory`
- k3s control plane
- monitoring home
- bootstrap edge
- hand-rolled and operator-facing integrations are allowed here when needed

2. `platform`
- Proxmox-hosted worker VM on the NUC
- preferred home of GitOps-managed platform services
- intentionally cleaner and more declarative than `observatory`

3. `workload-node`
- future worker capacity for application and compute workloads
- should stay cleaner than `observatory`

### GitOps Choice
Use `Flux`, not `Argo CD`.

Reason:
1. desired operating model is Git and repo state as the control surface
2. AI-assisted repo edits are a better match for controller-driven reconciliation than UI-driven sync workflows
3. Flux image automation is a better fit once custom images become routine

### Git Forge Choice
Deploy `Gitea` on the cluster.

Initial truth remains GitHub for bootstrap.

Reason:
1. avoids bootstrap deadlock while the cluster-side forge is still being created
2. allows Gitea to become more central later without blocking early progress

### Database Choice
Use `Postgres` from day one for `Gitea` and future stateful apps.

Do not start Gitea on SQLite.

Reason:
1. migration cost is not worth the temporary simplicity
2. current tooling maturity is already enough to manage Postgres cleanly
3. multiple future apps are already expected to want Postgres

## Postgres Strategy
### Recommendation
Start with one shared Postgres instance in-cluster, but enforce logical isolation.

Use:
1. separate databases per app where appropriate
2. separate users/credentials per app
3. separate Kubernetes secrets per app
4. clear ownership boundaries in manifests and docs

### Why Not One Postgres Per App Initially
1. wastes RAM earlier than necessary
2. duplicates operational surface area
3. increases backup and lifecycle overhead without current benefit

### Why Not One Flat Shared Database/User For Everything
1. poor blast-radius control
2. unclear ownership
3. harder future migration to dedicated database instances

### Practical Starting Model
One `platform-postgres` service hosts:
1. `gitea` database + role
2. future platform-service databases as needed
3. future app databases as needed until a split is justified

### Future Split Trigger
Split platform and app databases into separate instances only when one or more of these become true:
1. RAM or IO pressure becomes visible
2. backup/restore cadence differs materially
3. trust boundaries differ materially
4. one app becomes operationally noisy enough to deserve isolation
5. a future NAS/storage tier makes a cleaner state separation practical

Until then:
1. share the instance
2. isolate at the database/role/secret level
3. keep migration paths obvious

## Placement Model
### Immediate Placement
1. control plane remains on `observatory`
2. monitoring remains primarily on `observatory`
3. `Flux`, `Gitea`, and `platform-postgres` should prefer the `platform` worker

### Node Labels
At minimum:
1. `rita.role=observatory`
2. `rita.role=platform`
3. later: `rita.role=workload`

### Taints
Do not start with aggressive taints until the `platform` worker is actually in service.

Once the worker is healthy, prefer:
1. keeping `observatory` special-purpose
2. pushing platform services away from `observatory`
3. reserving `observatory` for monitoring, control-plane duties, and messy/bootstrap exceptions

Possible later taint:
```text
rita.role=observatory:NoSchedule
```

Only add that once enough non-`observatory` capacity exists.

## Bootstrap Model
### Phase 1
Bootstrap `Flux` from GitHub into the existing cluster.

Reason:
1. avoids circular dependency on an in-cluster Git forge
2. lets the first GitOps lane be proven before Gitea becomes authoritative

### Phase 2
Use Flux to create:
1. platform namespace(s)
2. shared Postgres
3. Gitea
4. observability defaults for platform services

### Phase 3
After off-the-shelf app deployment is proven:
1. decide whether Gitea becomes primary or mirrored
2. decide when app development workflow should move inward

## Storage Stance
### Current Reality
The real long-term storage answer is not available yet because the NAS is not in place.

### Interim Rule
Design for migration, not permanence.

That means:
1. keep stateful storage isolated and named clearly
2. avoid node-specific assumptions in app docs and manifests
3. treat current storage as temporary and replaceable
4. separate app state from large bulk assets conceptually even if they temporarily land on the same hardware pool

### Data Classes
1. repo/config truth
- backed by Git

2. durable app state
- DBs
- uploaded files
- app config needing restore

3. large bulk assets
- media files
- model files
- cached downloads

### Current Storage Policy
1. durable app state should be explicitly identified even if backup is not yet real
2. large bulk assets may live in a temporary bucket/path for now
3. all storage choices should assume later migration to NAS-backed management

## Backup Policy
### Current Stance
Real backups are intentionally deferred.

### Interim Policy
Implement a declared-but-nonfunctional backup layer.

This is acceptable only if it is explicit.

### Clown Backup Strategy
For stateful apps, track:
1. whether the workload is stateful
2. what data class it owns
3. whether it is considered disposable or durable
4. what the intended backup target will eventually be
5. that no actual backup is currently performed

### What This Should Do Now
1. surface stateful apps with no real backup
2. log/report the gap automatically
3. avoid pretending restore guarantees exist

### What This Should Not Do
1. silently imply safety
2. block experimentation yet
3. force full backup engineering before the NAS arrives

## Auth Stance
Do not add `Authentik` yet.

Use Pangolin as the current access boundary while trusted-user count stays very small.

Revisit shared identity when:
1. apps need durable per-user data
2. human identity must map cleanly to app records across multiple services
3. Pangolin access control is no longer enough

## Automatic Observability Contract
New platform and app services should not require ad-hoc opt-in monitoring work after deployment.

The intended contract is:
1. metrics/scrape configuration where available
2. logs collected by the existing logging lane where practical
3. uptime/synthetic checks where operator value exists
4. metadata or conventions that make unmonitored stateful services visible

This should be applied declaratively, not by UI cleanup.

## Deliverables
1. clean `platform` worker VM from the Debian 12 template
2. worker join flow into the existing k3s cluster
3. node labels/placement policy for `observatory` vs `platform`
4. Flux bootstrap from GitHub
5. Flux-managed platform namespace layout
6. shared Postgres deployment
7. Gitea deployment using Postgres
8. observability defaults for platform services
9. explicit backup metadata/reporting for stateful services

## Pass Criteria
1. NUC capacity joins the current cluster as a worker, not a second cluster
2. `platform` services can be scheduled away from `observatory`
3. Flux manages the platform lane from Git-backed declarations
4. Gitea runs on-cluster against Postgres
5. stateful services declare their backup status even when backups are intentionally absent
6. repo docs reflect `Flux + Gitea + shared Postgres` rather than the old `Argo/Zot` direction

## Execution Sequence
1. rebuild `9200` as the `platform` worker VM
2. join it to the existing cluster
3. add node labels and initial placement rules
4. bootstrap Flux from GitHub
5. define Flux repo layout for platform services
6. deploy shared Postgres
7. deploy Gitea on top of Postgres
8. wire in automatic observability defaults
9. add declared backup-policy metadata/reporting
10. onboard first off-the-shelf platform/app services

## Immediate Next Actions
1. rebuild the NUC VM as `platform`
2. codify the worker join path in `ops/` and `scripts/`
3. define Flux repo structure in this repo
4. define initial `platform-postgres` contract:
- database naming
- role naming
- secret ownership
5. deploy Gitea from GitHub-backed Flux manifests
6. create the first automatic observability policy for new services
