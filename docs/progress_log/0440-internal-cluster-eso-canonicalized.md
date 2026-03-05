## 0440 - Internal Cluster ESO Canonicalized
Date: 2026-03-02

## Summary

The internal cluster now has a canonical, repo-managed External Secrets bootstrap path rooted on `observatory`.

This replaces the older VPS-shaped ESO automation as the source of truth for the internal cluster.

## What Changed

1. Added internal-cluster ESO install playbook:
   - `ops/ansible/playbooks/32-install-eso-internal.yml`
2. Added internal-cluster secret-bridge playbook:
   - `ops/ansible/playbooks/42-apply-secret-bridge-internal.yml`
3. Added no-arg operator wrappers:
   - `scripts/2-ops/observatory/13-install-eso.sh`
   - `scripts/2-ops/observatory/14-apply-secret-bridge.sh`
4. Kept the `ClusterSecretStore` manifest canonical in GitOps:
   - `ops/gitops/platform/sources/onepassword-cluster-store.yaml`
5. Added `eso_namespace` to `observatory` vars.

## Live Validation

The new internal-cluster path was applied successfully.

Validated live:

1. `external-secrets` namespace exists
2. ESO controller pods are running
3. `ClusterSecretStore/onepassword-cluster-store` is `Ready=True`

## Why This Matters

`platform-postgres` and later app-level `ExternalSecret` resources depend on ESO existing before Flux can reconcile their secrets correctly.

The cluster secret substrate is now treated as:

1. bootstrap capability owned by Ansible/runbooks
2. app secret consumers owned by Flux/GitOps

## Current State

Internal cluster status is now:

1. Flux bootstrapped
2. `platform` worker joined
3. `workload` worker joined
4. ESO installed on the internal cluster
5. 1Password cluster store bridged and ready

## Remaining Gap

The remaining blocker for `platform-postgres` is no longer ESO.

The remaining step is to ensure the current local GitOps changes are committed/pushed so Flux can reconcile the updated `platform-postgres` tree.

## Freshness

This note supersedes older assumptions that ESO for the internal cluster was still tied to the old VPS-shaped automation path.
