# 0670 - n8n VM Nuke-And-Pave Executed

Date: 2026-03-05
Status: INCOMPLETE
Author: background agent
Freshness stamp: 2026-03-05

## Summary

Executed plan 0690 end-to-end through VM rebuild, cluster join, ESO recovery, DB bootstrap, and n8n rollout on dedicated node `n8n`.

## Commands Executed

1. `PROXMOX_REBUILD_CONFIRM=n8n-vm-9303 ./scripts/2-ops/workload/29-rebuild-n8n-vm.sh`
2. `./scripts/2-ops/workload/30-bootstrap-n8n-host.sh`
3. `./scripts/2-ops/workload/31-install-n8n-k3s-agent.sh`
4. `./scripts/2-ops/workload/32-label-n8n-node.sh`
5. `./scripts/2-ops/workload/33-verify-n8n-node.sh`
6. `./scripts/2-ops/observatory/14-apply-secret-bridge.sh`
7. `./scripts/2-ops/host/22-bootstrap-n8n-db.sh`
8. `flux resume kustomization flux-system -n flux-system`

## Runtime Fixes Applied During Execution

1. Cleared stale k3s node identity collision for hostname `n8n` by removing old node and node-password secret before rejoin.
2. Corrected ExternalSecret key contract for this cluster lane to canonical `<item>/<field>` format:
1. `platform-postgres/postgres-password`
2. `n8n-secrets/db-password`
3. `n8n-secrets/encryption-key`

## Validation Snapshot

1. `kubectl get nodes -o wide` shows `n8n` is `Ready` at `192.168.6.185`.
2. `kubectl get externalsecret -n platform` shows:
1. `n8n-secrets` -> `SecretSynced=True`
2. `platform-postgres-auth` -> `SecretSynced=True`
3. `kubectl rollout status deploy/n8n -n platform` completed successfully.
4. `kubectl get deploy,svc,pvc,secret -n platform` confirms n8n runtime objects are present and bound.
5. `flux get all -A` confirms `flux-system` resumed and healthy.

## Why Incomplete

Runtime execution is complete, but repo cleanup/PR packaging is still pending in a multi-agent workspace:
1. stage/commit with neighboring changes unresolved
2. optional post-bringup ingress/product checks not yet recorded in this log

## Next Step

Finalize git packaging for the manifest key-format corrections, then run one post-reconcile check and record n8n access validation.
