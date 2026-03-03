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
   - Nextcloud admin credentials
   - Nextcloud database credentials
   - Redis password
5. host-side runbooks for:
   - bootstrapping the Nextcloud database on `platform-postgres`
   - enabling the desired collaboration app bundle with `occ`

## Important Boundary

This scaffold is **not yet activated** in the live cluster root.

Safe-to-merge-now pieces:
1. `ops/gitops/workload/namespaces/`
2. `ops/gitops/workload/sources/`

Prepared-but-not-rooted-yet pieces:
1. `ops/gitops/workload/apps/nextcloud-redis/`
2. `ops/gitops/workload/apps/nextcloud/`

This keeps the live cluster stable while the remaining activation decisions are made:
1. 1Password item creation
2. app bring-up order

## Canonical Secret Contracts

Prepared 1Password item/field contracts:
1. item `nextcloud-admin`
   - `nextcloud-username`
   - `nextcloud-password`
2. item `nextcloud-db`
   - `db-name`
   - `db-user`
   - `db-password`
3. item `nextcloud-redis`
   - `redis-password`

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

1. the app lane is not yet activated in the live root
2. `Collectives` dependency behavior still needs live validation after bring-up
3. org-provisioning automation is still a later layer; only DB bootstrap and suite enablement are scaffolded so far

## Files

Primary implementation:
1. `ops/gitops/workload/`
2. `scripts/2-ops/workload/15-bootstrap-nextcloud-db.sh`
3. `scripts/2-ops/workload/16-enable-nextcloud-suite.sh`

Primary plan:
1. `docs/plans/0220-nextcloud-first-collaboration-suite.md`
