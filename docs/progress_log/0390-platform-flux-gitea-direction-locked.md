# 0390 - Platform Direction Locked Around Flux, Gitea, and a Worker Expansion

Date: 2026-03-01  
Status: ✅ COMPLETE

## Summary
The next platform direction is now explicit.

The lab will:
1. keep `observatory` as the single current k3s control plane and monitoring home
2. rebuild the NUC as a clean `platform` worker VM
3. use `Flux` instead of `Argo CD`
4. deploy `Gitea` on-cluster
5. use `Postgres` from day one
6. bootstrap from GitHub first, then let Gitea become more important later

This replaces the earlier vague `Argo CD + Zot + CI/CD box` direction with a more precise `platform worker + GitOps + forge + shared Postgres` model.

## Decisions Locked
1. no second independent cluster on the NUC yet
2. one internal cluster remains simpler than splitting GitOps and platform services across multiple small clusters
3. `observatory` is now the accepted quarantine zone for bootstrap-edge and hand-rolled work
4. the NUC and later worker capacity should represent the cleaner declarative lane
5. `Gitea` should use `Postgres`, not SQLite
6. a single shared Postgres instance is acceptable initially if isolation is enforced by separate databases, roles, and secrets

## Storage And Backup Stance
1. real backup engineering is intentionally deferred until the NAS situation improves
2. stateful workloads should still declare their data class and lack of backup coverage
3. a deliberately nonfunctional "clown backup strategy" is acceptable for now if it is explicit and machine-visible

## Auth Stance
1. shared app identity remains deferred
2. Pangolin is sufficient as the current access boundary while trusted-user count remains very small
3. revisit a real IdP only when apps need persistent user identity mapped to stored data

## Why This Matters
This gives the repo a cleaner operating split:

1. `observatory`
- monitoring
- control plane
- operator edge
- tolerated messy bootstrap work

2. `platform`
- GitOps-managed platform services
- Gitea
- shared Postgres
- future CI helpers/runners if needed

3. `workload-node`
- future application and compute workloads

## Detailed Plan
See:
- [0160-platform-flux-gitea-and-worker-expansion.md](/Users/virgil/Dev/rita-v4/docs/plans/0160-platform-flux-gitea-and-worker-expansion.md)

## Immediate Next Actions
1. rebuild `9200` into the clean `platform` worker VM
2. join it to the existing cluster
3. bootstrap Flux from GitHub
4. define and deploy shared `platform-postgres`
5. deploy `Gitea`
