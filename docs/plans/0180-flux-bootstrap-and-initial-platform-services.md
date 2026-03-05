# 0180 - Flux Bootstrap And Initial Platform Services
Status: ACTIVE
Date: 2026-03-01

## Goal
Use the now-working two-node internal cluster to establish the first real GitOps-managed platform lane.

This phase covers:
1. bootstrapping `Flux` from GitHub
2. proving the repo-managed GitOps tree reconciles cleanly
3. codifying the immediate platform prerequisites that were still manual during worker bring-up
4. deploying the first platform services:
- `platform-postgres`
- `Gitea`

## Freshness
Start with the latest relevant progress note before trusting this plan:
1. [0410-flux-bootstrap-blocked-by-kubeconfig-and-host-api-tech-debt.md](/Users/virgil/Dev/rita-v4/docs/progress_log/0410-flux-bootstrap-blocked-by-kubeconfig-and-host-api-tech-debt.md)

## Current Needs
The cluster has crossed the threshold where manual bootstrap work is no longer the main blocker.

Current needs are:
1. move from ad-hoc node/bootstrap operations into a repo-reconciled platform lane
2. stop treating Flux bootstrap inputs as disposable operator trivia
3. prove the current `ops/gitops/` tree is viable against the real internal cluster
4. turn the `platform` worker into the preferred home of platform services
5. install the first durable-ish stateful platform services in a way that matches the longer-term architecture

## Current Goals
1. `Flux` should reconcile this repo against the internal cluster
2. the platform GitOps tree should apply cleanly without manual post-fix work
3. worker and control-plane placement should be encoded, not implied
4. `platform-postgres` should come up as the first shared stateful service
5. `Gitea` should come up on top of `platform-postgres`
6. the current manual fixes discovered during worker join should be absorbed back into automation where appropriate

## Phase Scope
### In Scope
1. GitHub-backed Flux bootstrap
2. GitOps source/reconciliation validation
3. platform namespace and source definitions
4. platform Helm repositories and secret references
5. first-pass observability targets for platform services
6. `platform-postgres`
7. `Gitea`
8. explicit verification for each stage

### Out Of Scope
1. shared app identity / Authentik
2. NAS-backed durable storage
3. final backup implementation
4. broader off-the-shelf app onboarding beyond proving the platform lane
5. making Gitea the primary forge immediately

## Relation To Larger Plan
This phase is a direct continuation of:
1. [0160-platform-flux-gitea-and-worker-expansion.md](/Users/virgil/Dev/rita-v4/docs/plans/0160-platform-flux-gitea-and-worker-expansion.md)
2. [0170-platform-worker-execution-plan.md](/Users/virgil/Dev/rita-v4/docs/plans/0170-platform-worker-execution-plan.md)

It starts after:
1. `platform-vm-worker` exists
2. the worker has joined the cluster
3. both nodes are `Ready`
4. role labels are present

It advances the larger plan by:
1. turning the cluster into a real GitOps-managed platform
2. proving the platform-services lane before broader app onboarding
3. setting the stage for later off-the-shelf apps and later inward movement toward Gitea

## The Play
### Stage 1 - Prepare Flux Bootstrap Inputs
1. confirm `flux` CLI is present on the Mac host
2. confirm the current Git remote is the intended bootstrap source
3. resolve the GitHub owner and repo from the remote or checked-in config
4. decide how the bootstrap token is sourced:
- operator env
- 1Password-backed read
5. confirm the bootstrap path:
- `ops/gitops/clusters/internal`
6. confirm host-side kubeconfig is regenerated from canonical inventory truth
7. confirm the Mac host has a durable path to the control-plane API

### Stage 2 - Bootstrap Flux
1. run the host-side Flux bootstrap against GitHub
2. let Flux install its controllers into the cluster
3. let Flux point at the internal-cluster GitOps path in this repo

### Stage 3 - Verify GitOps Baseline
1. verify Flux controllers are healthy
2. verify the source is reachable
3. verify reconciliation completes without stuck errors
4. verify the namespace/source tree applies
5. inspect whether any missing secret or dependency blocks the first sync

### Stage 4 - Absorb Known Manual Fixes
1. codify the k3s API firewall rule on the control-plane host
2. keep the internal cluster node-name mapping aligned with reality
3. ensure the GitOps tree reflects the current node/placement model
4. ensure the user kubeconfig on `observatory` is rendered from canonical inventory truth

### Stage 5 - Deploy `platform-postgres`
1. reconcile the Postgres app definition through Flux
2. ensure its namespace, Helm source, and secrets path exist
3. verify pod readiness, service readiness, PVC binding, and secret material
4. verify the database/role contract intended for Gitea exists

### Stage 6 - Deploy `Gitea`
1. reconcile the Gitea app definition through Flux
2. verify DB connectivity to `platform-postgres`
3. verify pod readiness, service readiness, and PVCs
4. verify bootstrap/admin access path

### Stage 7 - Prove The Platform Lane
1. confirm platform services are landing on `platform` as intended
2. confirm they are observable enough to operate
3. confirm backup-state declarations are visible even if backups are not real
4. confirm this repo now acts as the operative GitOps source for the internal cluster

## Verification
### Flux Bootstrap Verification
1. `flux check`
2. `kubectl get pods -n flux-system`
3. `kubectl get kustomizations -A`
4. `kubectl get gitrepositories -A`

Pass condition:
1. Flux controllers are healthy
2. Git source is reachable
3. reconciliation is active

### GitOps Tree Verification
1. `kubectl kustomize ops/gitops/clusters/internal`
2. `flux get sources git -A`
3. `flux get kustomizations -A`

Pass condition:
1. the committed GitOps tree renders and reconciles
2. no critical dependency is unresolved without being understood

### Platform Placement Verification
1. `kubectl get pods -A -o wide`
2. `kubectl get nodes --show-labels`

Pass condition:
1. platform services prefer the `platform` worker
2. `monitoring` remains the control-plane/monitoring home

### Postgres Verification
1. `kubectl get pods,svc,pvc -n platform`
2. inspect HelmRelease/Kustomization status
3. verify generated secrets exist where expected

Pass condition:
1. `platform-postgres` is healthy
2. storage is bound
3. the Gitea DB contract is usable

### Gitea Verification
1. `kubectl get pods,svc,pvc -n platform`
2. inspect HelmRelease/Kustomization status
3. verify Gitea can connect to Postgres
4. verify the operator bootstrap/admin path works

Pass condition:
1. Gitea is healthy
2. Gitea is backed by Postgres
3. the platform lane is usable for the next phase

## Known Risks In This Phase
1. GitHub bootstrap credentials remain operator-bound and need a cleaner retrieval path
2. some durable config for Flux bootstrap inputs is not yet encoded as cleanly as other infrastructure facts
3. stateful services are still landing before real backup implementation exists
4. the control-plane node name remains `monitoring` while the role concept remains `observatory`
5. host-side control-plane API reachability is still an active integration boundary, not yet fully codified policy

## Deliverables
1. host-side Flux bootstrap workflow
2. healthy Flux controllers
3. active GitOps reconciliation from this repo
4. codified fix for the k3s API firewall gap
5. healthy `platform-postgres`
6. healthy `Gitea`
7. verification outputs proving the platform lane is real

## Pass Criteria
1. Flux is active against this repo and the internal cluster
2. the GitOps tree reconciles without unexplained failures
3. platform services land on the intended node
4. `platform-postgres` is healthy
5. `Gitea` is healthy and DB-backed
6. the phase leaves the repo in a better automated state than the manual worker-join phase

## Immediate Next Actions
1. rerender the canonical kubeconfig on `observatory`
2. verify host-side kubeconfig reaches the real control-plane address
3. codify the host-side `6443/tcp` access rule if direct Mac access is the intended model
4. rerun Flux bootstrap from the Mac host
5. verify Flux reconciliation
6. reconcile `platform-postgres`
7. reconcile `Gitea`
