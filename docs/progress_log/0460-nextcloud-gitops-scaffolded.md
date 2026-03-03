# 0460 - Nextcloud GitOps Scaffolding Landed
Status: VALIDATED
Date: 2026-03-03

## Summary

The repo now has a canonical `workload`-lane GitOps scaffold for a Nextcloud-first collaboration suite.

This includes:
1. a `workload` namespace/source subtree
2. a `nextcloud-redis` HelmRelease scaffold
3. a `nextcloud` HelmRelease scaffold
4. ExternalSecret contracts for:
   - Nextcloud admin password
   - Nextcloud database password
   - Redis password
5. host-side runbooks for:
   - bootstrapping the Nextcloud database on `platform-postgres`
   - enabling the desired collaboration app bundle with `occ`

## Freshness

This note records the scaffold stage only.

The live deployment state has advanced beyond it.

See:
1. `docs/progress_log/0470-nextcloud-live-and-bootstrapped.md`

## Canonical Secret Contract

V1 should converge on one 1Password item:
1. item `nextcloud-main`
2. fields:
   - `nextcloud-admin`
   - `nextcloud-db`
   - `nextcloud-redis`

In-cluster secrets should be derived from that single item rather than requiring three separate 1Password items.

## Current Deployment Contract

The prepared base deployment assumes:
1. external Postgres via `platform-postgres`
2. external Redis via a separate `nextcloud-redis` HelmRelease
3. single-replica Apache Nextcloud
4. cron background jobs
5. Pangolin public exposure at `app.virgil.info`
6. placement on `workload`
7. one shared instance with group-based organization in v1

## Known Footguns Encoded Into The Scaffold

The scaffolding already bakes in the major decisions from the Nextcloud research:
1. no SQLite
2. no internal Redis
3. explicit Redis config
4. explicit reverse-proxy config
5. single replica
6. Apache flavor first

## Remaining Tech Debt / Unknowns

1. `Collectives` dependency behavior had not yet been live-validated at scaffold time
2. org-provisioning automation is still a later layer; only DB bootstrap and suite enablement were scaffolded here

## Files

Primary implementation:
1. `ops/gitops/workload/`
2. `scripts/2-ops/workload/15-bootstrap-nextcloud-db.sh`
3. `scripts/2-ops/workload/16-enable-nextcloud-suite.sh`

Primary plan:
1. `docs/plans/0220-nextcloud-first-collaboration-suite.md`
