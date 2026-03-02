# 0410 - Flux Bootstrap Blocked By Kubeconfig And Host API Tech Debt

Date: 2026-03-02  
Status: 🟡 IN PROGRESS

## Summary
The platform worker phase completed, but Flux bootstrap did not complete cleanly on the first pass.

The current blockers are not Flux-specific logic bugs.

They are two host/control-plane integration debts that were still implicit:
1. the user kubeconfig on `ops-brain` was not being durably rendered from canonical inventory data
2. the control-plane API exposure model for Mac-hosted operator tools remains incomplete

## What Was Observed
### 1. Wrong kubeconfig source on `ops-brain`
The file:
1. `/home/virgil/.kube/config`

still contained:
1. `server: https://127.0.0.1:6443`

That broke:
1. copied host-side kubeconfig use
2. Mac-hosted `kubectl`
3. Flux bootstrap verification on the host

This proved the source artifact itself was wrong, not just a host-side consumer.

### 2. Manual fix proved the real desired server value
After editing the file on `ops-brain`, the desired value was:
1. `server: https://192.168.6.16:6443`

That value should come from:
1. `ops/ansible/inventory/ops-brain.ini`

### 3. Worker join already exposed the firewall issue once
Earlier in the worker phase:
1. `platform` could not join until `6443/tcp` was opened from the worker to the control plane

That problem is now broader than just the worker:
1. host-side tools on the Mac also need a durable and explicit path to the Kubernetes API

## Repo Changes Made
### Canonical kubeconfig sync path
The repo now has:
1. a dedicated playbook to regenerate the user kubeconfig on `ops-brain` from canonical inventory identity
2. a no-arg wrapper script to run that sync explicitly
3. a Flux bootstrap wrapper that calls the canonical sync path before copying kubeconfig

Files added:
1. `/Users/virgil/Dev/rita-v4/ops/ansible/playbooks/27-sync-ops-brain-kubeconfig.yml`
2. `/Users/virgil/Dev/rita-v4/scripts/2-ops/ops-brain/08-sync-kubeconfig.sh`

Files updated:
1. `/Users/virgil/Dev/rita-v4/ops/ansible/playbooks/21-install-k3s-ops-brain.yml`
2. `/Users/virgil/Dev/rita-v4/scripts/2-ops/worker/06-bootstrap-flux-github.sh`

## Current Untested Tech Debt
This workstream is currently carrying explicit untested debt in two places.

### A. Host-side API reachability model
It is still not fully codified how Mac-hosted operator tools should reach the control-plane API.

Known facts:
1. worker-to-control-plane `6443/tcp` needed an explicit firewall rule
2. host-side `kubectl` also depends on that path being reachable

What is not yet durably encoded:
1. whether the Mac host should be allowed directly to `6443/tcp`
2. whether only a specific host IP should be allowed
3. whether the repo should model a host-operator subnet rule instead

### B. Kubeconfig generation path
The durable source path is now defined in repo code, but it has not yet been re-proven end-to-end through the full Flux bootstrap run.

That means:
1. the intended fix is in the repo
2. the entire pipe is not yet proven closed

## Current Plan
The immediate play is:
1. rerender the canonical kubeconfig on `ops-brain`
2. verify the host-side copied kubeconfig points at `192.168.6.16`
3. verify host-side API reachability from the Mac
4. if needed, codify the missing `6443/tcp` rule for host-side access
5. rerun Flux bootstrap

## Why This Matters
The point of scripting here is durability.

So the repo should not rely on:
1. manual file edits on `ops-brain`
2. accidental kubeconfig contents
3. remembered one-off firewall exceptions

Those must become explicit automation or explicit policy.

## Next Verification Gate
This note should be superseded once all of the following are true:
1. `scripts/2-ops/ops-brain/08-sync-kubeconfig.sh` reliably regenerates the correct server address
2. host-side copied kubeconfig works without manual patching
3. Flux bootstrap completes
4. `flux-system` and Flux CRDs exist and reconcile cleanly

## Freshness Anchor
For the current Flux/bootstrap phase after the worker join, use:
1. [0180-flux-bootstrap-and-initial-platform-services.md](/Users/virgil/Dev/rita-v4/docs/plans/0180-flux-bootstrap-and-initial-platform-services.md)
