# 0690 - n8n VM Nuke-And-Pave Plan
Status: ACTIVE
Date: 2026-03-05

## Goal
Stand up `n8n` cleanly by rebuilding from the dedicated `n8n-vm` lane and reapplying only canonical repo-managed state.

This plan intentionally discards ad hoc live mutations and converges on one durable path:
1. dedicated VM substrate (`n8n-vm`)
2. internal-cluster k3s worker join
3. Flux-managed `n8n` deployment in namespace `platform`
4. 1Password -> ESO -> Kubernetes Secret contract aligned to proven repo format

## Inputs Combined
This plan combines:
1. [0008-n8n-helm-install-on-n8n-vm.md](/Users/virgil/Dev/rita-v4/docs/research/0008-n8n-helm-install-on-n8n-vm.md)
2. [0001-n8n-nextcloud-integration.md](/Users/virgil/Dev/rita-v4/docs/research/0001-n8n-nextcloud-integration.md)
3. [0550-n8n-platform-gitops-scaffolded-but-bring-up-blocked.md](/Users/virgil/Dev/rita-v4/docs/progress_log/0550-n8n-platform-gitops-scaffolded-but-bring-up-blocked.md)
4. [0050-secret-sync-validation.md](/Users/virgil/Dev/rita-v4/docs/progress_log/0050-secret-sync-validation.md)
5. [0440-internal-cluster-eso-canonicalized.md](/Users/virgil/Dev/rita-v4/docs/progress_log/0440-internal-cluster-eso-canonicalized.md)

## Canonical Decisions Locked
1. `n8n` runs on dedicated worker host `n8n` (VM alias `n8n-vm`, IP `192.168.6.185`).
2. `n8n` remains private-first (`ClusterIP`) in `platform` namespace.
3. `n8n` uses `platform-postgres` as DB backend.
4. 1Password item for app secrets is `n8n-secrets` with fields:
   - `db-password`
   - `encryption-key`
5. ESO key format for this cluster store must follow proven repo contract:
   - `remoteRef.key: "<item>/<field>"` (or equivalent simple path shape), not ad hoc mixed formats.

## Nuke-And-Pave Scope
Nuke:
1. existing `n8n` runtime objects in `platform` namespace (deployment/service/pvc/externalsecret/secret as needed)
2. drifted live-only secret wiring changes
3. previous node placement assumptions on `platform` worker

Pave:
1. rebuild `n8n-vm` from Proxmox template
2. bootstrap/join/label/verify `n8n` node in k3s
3. reapply canonical ESO substrate and app manifests from repo
4. bootstrap DB role/database using canonical helper

## Phase 0 - Preflight and Freeze
1. Confirm cluster API and `observatory` SSH reachability.
2. Suspend Flux kustomization temporarily to avoid mid-flight drift during destructive/recreate window.
3. Snapshot current `platform` namespace state for rollback diagnostics:
   - `kubectl get all,secret,externalsecret,pvc -n platform -o wide`

Exit criteria:
1. API reachable and Flux suspended.
2. current state captured.

## Phase 1 - Rebuild Dedicated VM
1. Run dedicated VM rebuild wrapper:
   - `PROXMOX_REBUILD_CONFIRM=n8n-vm-9303 ./scripts/2-ops/workload/29-rebuild-n8n-vm.sh`
2. Apply host bootstrap for `n8n-vm`:
   - `./scripts/2-ops/workload/30-bootstrap-n8n-host.sh`
3. Join k3s worker:
   - `./scripts/2-ops/workload/31-install-n8n-k3s-agent.sh`
4. Label and verify node:
   - `./scripts/2-ops/workload/32-label-n8n-node.sh`
   - `./scripts/2-ops/workload/33-verify-n8n-node.sh`

Exit criteria:
1. node `n8n` is `Ready`.
2. label `rita.role=workload` present.
3. host firewall policy includes required k3s/flannel paths.

## Phase 2 - Rebuild Secret Substrate (Canonical)
1. Reapply ESO bridge (canonical internal path):
   - `./scripts/2-ops/observatory/14-apply-secret-bridge.sh`
2. Ensure OP item `n8n-secrets` exists with required fields (`db-password`, `encryption-key`) and no naming drift.
3. Reset app `ExternalSecret` to canonical format used by stable lanes (simple key path contract).
4. Verify:
   - `ClusterSecretStore/onepassword-cluster-store` is `Ready=True`
   - `ExternalSecret/n8n-secrets` is `Ready=True`
   - `Secret/n8n-secrets` exists in `platform`

Exit criteria:
1. ESO sync is green for both `platform-postgres-auth` and `n8n-secrets`.
2. no stale parse-format errors in external-secrets controller logs for these resources.

## Phase 3 - Recreate n8n App Runtime
1. Remove old n8n app objects if present (deployment/service/pvc/externalsecret/secret) to eliminate stale state.
2. Reapply canonical manifests from `ops/gitops/platform/apps/n8n/`.
3. Confirm node placement contract in deployment:
   - `rita.role=workload`
   - `kubernetes.io/hostname=n8n`
4. Run DB bootstrap helper:
   - `./scripts/2-ops/host/22-bootstrap-n8n-db.sh`
5. Verify pod readiness and logs.

Exit criteria:
1. `deployment/n8n` available.
2. pod scheduled on node `n8n`.
3. DB migrations complete and app startup stable.

## Phase 4 - Flux Resume and Drift Check
1. Resume Flux reconciliation.
2. Reconcile `flux-system` with source.
3. Confirm no drift:
   - desired manifests match live state
   - `n8n` remains Ready after at least one reconcile cycle

Exit criteria:
1. Flux resumed and healthy.
2. n8n remains stable without live patching.

## Optional Phase 5 - Helm Migration (Post-Stability)
From [0008](/Users/virgil/Dev/rita-v4/docs/research/0008-n8n-helm-install-on-n8n-vm.md):
1. migrate n8n manifests to Flux-managed Helm (`OCIRepository` + `HelmRelease`) only after baseline is green.
2. keep behavior parity first (single instance, same DB/secrets/node pinning).
3. defer queue-mode expansion and Redis split to a later phase.

## Rollback
If bring-up fails after destructive steps:
1. keep Flux suspended
2. restore previous app manifests and secret refs from repo baseline
3. re-run secret bridge and app apply
4. capture failure evidence before next attempt:
   - `kubectl describe` on `ExternalSecret`, `Deployment`, `Pod`
   - external-secrets controller logs

## Deliverables
1. running `n8n` on dedicated `n8n-vm`
2. `ExternalSecret` and generated `Secret` both healthy
3. DB bootstrap run completed
4. progress note in `docs/progress_log/` with validation evidence
5. no manual-only steps required for repeat bring-up
