# 0550 - n8n Platform GitOps Scaffolded But Bring-Up Blocked

Date: 2026-03-04
Status: INCOMPLETE

## Summary

The repo now contains a first-pass `n8n` platform deployment shape, but the live bring-up did not complete.

The GitOps slice was added and aligned to the current 1Password layout, then cluster-side validation was attempted.

The blocking issue was not the manifest render.
It was loss of reachability to `observatory` from the Mac host during the apply/verify phase.

## Repo Changes Made

New `n8n` platform app manifests were added in:
1. [kustomization.yaml](/Users/virgil/Dev/rita-v4/ops/gitops/platform/apps/n8n/kustomization.yaml)
2. [n8n-secrets-externalsecret.yaml](/Users/virgil/Dev/rita-v4/ops/gitops/platform/apps/n8n/n8n-secrets-externalsecret.yaml)
3. [n8n-pvc.yaml](/Users/virgil/Dev/rita-v4/ops/gitops/platform/apps/n8n/n8n-pvc.yaml)
4. [n8n-deployment.yaml](/Users/virgil/Dev/rita-v4/ops/gitops/platform/apps/n8n/n8n-deployment.yaml)
5. [n8n-service.yaml](/Users/virgil/Dev/rita-v4/ops/gitops/platform/apps/n8n/n8n-service.yaml)

Cluster reconciliation and metadata were extended in:
1. [internal kustomization](/Users/virgil/Dev/rita-v4/ops/gitops/clusters/internal/kustomization.yaml)
2. [platform observability targets](/Users/virgil/Dev/rita-v4/ops/gitops/platform/observability/targets.tsv)
3. [platform backup-state inventory](/Users/virgil/Dev/rita-v4/ops/gitops/platform/backup-state/services.tsv)

A matching database bootstrap helper was also added:
1. [22-bootstrap-n8n-db.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/host/22-bootstrap-n8n-db.sh)

## Placement And Secret Decisions Locked In

The current repo shape assumes:
1. `n8n` runs on the `platform` worker via `nodeSelector: rita.role=platform`
2. service exposure is private-first via `ClusterIP`
3. app state uses a PVC named `n8n-data`
4. app DB is `platform-postgres`

The 1Password layout was updated to match the actual operator-created item shape:
1. item name: `n8n-secrets`
2. field: `db-password`
3. field: `encryption-key`

That means the current ExternalSecret no longer expects split refs like:
1. `platform/postgres/n8n-password`
2. `platform/n8n/encryption-key`

It now reads both values from the single `n8n-secrets` item instead.

## What Was Verified

Verified locally:
1. `kubectl kustomize ops/gitops/clusters/internal` renders successfully
2. [22-bootstrap-n8n-db.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/host/22-bootstrap-n8n-db.sh) passes `bash -n`
3. kubeconfig target is `https://192.168.6.16:6443`

## Live Bring-Up Blocker

The live bring-up is incomplete because the control-plane host became unreachable from the Mac host during validation.

Observed on 2026-03-04 around 09:41 AM PST:
1. `kubectl --request-timeout=8s get --raw=/readyz` returned `dial tcp 192.168.6.16:6443: connect: host is down`
2. `ssh virgil@192.168.6.16` returned `Host is down`

That prevented:
1. Flux reconciliation
2. verification that `Secret/n8n-secrets` materialized in namespace `platform`
3. running the DB bootstrap helper against `platform-postgres`
4. checking pod/service/PVC readiness for `n8n`

## Remaining Bring-Up Steps

Once `observatory` and the cluster API are reachable again, resume with:
1. `flux reconcile kustomization flux-system -n flux-system --with-source`
2. `kubectl get secret n8n-secrets -n platform`
3. [22-bootstrap-n8n-db.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/host/22-bootstrap-n8n-db.sh)
4. `kubectl get pods,svc,pvc -n platform`
5. `kubectl logs -n platform deploy/n8n --tail=200` if the pod is not `Ready`

## State Of This Work

This work should be treated as:
1. repo scaffolding complete
2. cluster bring-up incomplete
3. blocked on control-plane reachability, not on known manifest syntax errors
