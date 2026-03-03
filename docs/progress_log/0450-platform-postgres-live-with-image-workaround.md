## 0450 - Platform Postgres Live With Image Workaround
Date: 2026-03-03

## Summary

`platform-postgres` is now live on the internal cluster.

The shared Postgres service is running on `platform`, its PVC is bound, and the cluster service endpoints exist.

This completes the first real shared stateful platform primitive for the internal app wave.

## What Changed

1. Fixed worker-to-worker Flannel VXLAN policy so `platform` and `workload` can exchange overlay traffic directly.
2. Re-applied the `platform` and `workload` bootstrap playbooks so the new UFW VXLAN allowlists became live state.
3. Corrected the `platform-postgres` 1Password secret reference path.
4. Reconciled Flux and `platform-postgres` repeatedly until chart retrieval, secret materialization, and install all converged.
5. Applied a temporary image-source workaround in the `HelmRelease` so Bitnami image pulls succeed again.

## Live Validation

Validated live:

1. `HelmRelease/platform-postgres` is `Ready=True`
2. `pod/platform-postgres-0` is `2/2 Running`
3. `PVC/data-platform-postgres-0` is `Bound`
4. cluster services exist:
   - `platform-postgres`
   - `platform-postgres-hl`
   - `platform-postgres-metrics`
5. placement lands on node `platform`

## Root Causes Resolved

### 1. Cross-worker overlay traffic was under-modeled

The repo initially allowed Flannel VXLAN traffic only between each worker and `ops-brain`.

That was sufficient for worker join, but insufficient once Flux controllers landed on different worker nodes and had to talk to pod-backed services across the overlay.

The canonical fix was to extend the worker VXLAN allowlists in:

1. `ops/ansible/group_vars/platform.yml`
2. `ops/ansible/group_vars/workload.yml`

### 2. The Postgres secret path was wrong

The 1Password secret source went through several incorrect shapes before landing on the provider-compatible form.

The current canonical path is encoded in:

1. `ops/gitops/platform/apps/platform-postgres/postgres-auth-externalsecret.yaml`

### 3. Bitnami image tags used by this chart are no longer available on Docker Hub

The chart itself reconciles, but the default image tags it wanted to pull no longer exist.

The current live workaround is to override to `bitnamilegacy/*` image repositories in:

1. `ops/gitops/platform/apps/platform-postgres/helmrelease.yaml`

## Explicit Tech Debt

### 1. Legacy image override

`platform-postgres` currently depends on a temporary workaround:

1. `docker.io/bitnamilegacy/postgresql`
2. `docker.io/bitnamilegacy/postgres-exporter`

This is acceptable as a tactical unblocker, but it is not a durable long-term image sourcing story.

Future cleanup should choose one of:

1. newer chart/app path with maintained images
2. different Postgres deployment/operator
3. mirrored/pinned internal image policy

### 2. ESO status remains stale even though the generated Secret is present and working

The generated secret exists and `platform-postgres` is successfully using it, but the `ExternalSecret` status condition still reports an older provider error.

This appears to be controller/status lag or stale state rather than a functional blocker.

Treat this as cleanup debt, not a reason to block the app wave.

## Current State

Current first-wave platform state is now:

1. internal cluster healthy across `ops-brain`, `platform`, and `workload`
2. Flux healthy
3. ESO installed and bridged to 1Password
4. `platform-postgres` live on `platform`
5. next real app target can move to `Leantime`

## Freshness

This note supersedes `0440` as the main validated state for the first-wave app platform transition.
