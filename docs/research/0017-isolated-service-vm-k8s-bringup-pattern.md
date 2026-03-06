# 0017 - Isolated Service VM + k8s Bring-Up Pattern
Date: 2026-03-05
Status: Active research note

## Goal
Define a repeatable pattern to deploy a service on its own VM, join it to internal k3s, wire secrets and public access, and decide quickly whether to do wiring-only repair or full nuke-and-pave.

## Why This Pattern
From today’s execution, isolated VM service delivery succeeded when treated as a strict chain:
1. VM substrate
2. k3s node join/label
3. secret substrate
4. app deployment
5. Pangolin site/resource wiring
6. external validation

This was proven on `n8n-vm` and `observatory` route/service recovery.

## Canonical Pattern (Reusable)

### Phase 0 - Declare Source of Truth
1. Add/update required site record in:
   - [required-sites.yaml](/Users/virgil/Dev/rita-v4/ops/pangolin/sites/required-sites.yaml)
2. Ensure service lane runbooks exist and are ordered.
3. Ensure blueprint exists for external route exposure.

### Phase 1 - Provision Dedicated VM
1. Rebuild/create VM from canonical template runbook.
2. Validate inventory identity and host reachability.

For n8n example:
1. [29-rebuild-n8n-vm.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/29-rebuild-n8n-vm.sh)
2. [30-bootstrap-n8n-host.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/30-bootstrap-n8n-host.sh)

### Phase 2 - Join VM to k3s
1. Install k3s agent.
2. Label node for placement policy.
3. Verify node is `Ready`.

For n8n example:
1. [31-install-n8n-k3s-agent.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/31-install-n8n-k3s-agent.sh)
2. [32-label-n8n-node.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/32-label-n8n-node.sh)
3. [33-verify-n8n-node.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/33-verify-n8n-node.sh)

### Phase 3 - Establish Secret Substrate First
1. Apply ESO bridge and verify cluster secret store readiness.
2. Reconcile site credentials from OP and Pangolin via SoT automation.
3. Confirm required OP item exists in canonical name before app install.

Key scripts:
1. [14-apply-secret-bridge.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/observatory/14-apply-secret-bridge.sh)
2. [27-reconcile-pangolin-sites.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/host/27-reconcile-pangolin-sites.sh)

### Phase 4 - Deploy App Runtime
1. Apply app manifests (or HelmRelease if adopted).
2. Wait for app deployment readiness.
3. Verify pod placement on dedicated node and PVC binding.

For n8n current lane:
1. [platform n8n app manifests](/Users/virgil/Dev/rita-v4/ops/gitops/platform/apps/n8n/kustomization.yaml)

### Phase 5 - Wire Public Access
1. Ensure Pangolin site exists and connector is online.
2. Apply service blueprint with canonical site identifier.
3. Validate external domain response code and expected redirect behavior.

Key scripts:
1. [31-apply-n8n-blueprint.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/host/31-apply-n8n-blueprint.sh)
2. [20-apply-observatory-monitoring-blueprint.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/host/20-apply-observatory-monitoring-blueprint.sh)
3. [28-verify-pangolin-sites-and-newt.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/host/28-verify-pangolin-sites-and-newt.sh)

### Phase 6 - Close with Evidence
1. Capture:
   - node state
   - app pods/services/pvcs
   - route HTTP status behavior
2. Write progress log with freshness stamp.

## Wire vs Nuke Decision Gate

Use wiring-only fix when all are true:
1. Node is `Ready`.
2. App pod is `Running`.
3. Service/PVC exist and healthy.
4. Site and Newt connector are online.
5. External route fails with `404/502` or wrong auth behavior.

Use nuke-and-pave when any are true:
1. VM host state is unknown/drifted.
2. k3s agent join is unstable.
3. Secret substrate repeatedly fails to materialize.
4. App data path has unrecoverable drift.

For n8n this repo already has canonical nuke-and-pave plan + orchestrator:
1. [0690-n8n-vm-nuke-and-pave-plan.md](/Users/virgil/Dev/rita-v4/docs/plans/0690-n8n-vm-nuke-and-pave-plan.md)
2. [39-bring-up-n8n-vm-k8s-pangolin.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/39-bring-up-n8n-vm-k8s-pangolin.sh)

## Recommended Future Template (for any new isolated service)
1. Add `required-sites.yaml` entry for `<service>_vm`.
2. Add VM rebuild/bootstrap/join/label/verify scripts in `scripts/2-ops/workload/`.
3. Add app manifests in `ops/gitops/platform/apps/<service>/` (or workload lane if app lane policy changes).
4. Add OP-backed secret contract and ESO object.
5. Add Pangolin blueprint and apply script.
6. Add one no-adhoc orchestrator script (`bring-up-<service>-vm-k8s-pangolin.sh`).
7. Add one progress log after successful first run.

## Source Evidence
1. Today’s monitoring/public route recovery:
   - [0770-observatory-monitoring-routes-brought-up.md](/Users/virgil/Dev/rita-v4/docs/progress_log/0770-observatory-monitoring-routes-brought-up.md)
2. Today’s n8n route restoration and health verification:
   - [0780-n8n-route-restored-and-observatory-stabilized.md](/Users/virgil/Dev/rita-v4/docs/progress_log/0780-n8n-route-restored-and-observatory-stabilized.md)
3. Existing n8n dedicated-VM chain and runbook structure:
   - [workload README](/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/README.md)
   - [39-bring-up-n8n-vm-k8s-pangolin.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/39-bring-up-n8n-vm-k8s-pangolin.sh)
4. Site/credential/reconcile contract:
   - [required-sites.yaml](/Users/virgil/Dev/rita-v4/ops/pangolin/sites/required-sites.yaml)
   - [27-reconcile-pangolin-sites.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/host/27-reconcile-pangolin-sites.sh)
5. Existing n8n Helm migration research context:
   - [0008-n8n-helm-install-on-n8n-vm.md](/Users/virgil/Dev/rita-v4/docs/research/0008-n8n-helm-install-on-n8n-vm.md)
