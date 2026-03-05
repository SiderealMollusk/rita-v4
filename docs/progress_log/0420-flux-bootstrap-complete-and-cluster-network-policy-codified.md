# 0420 - Flux Bootstrap Complete And Cluster Network Policy Codified

Date: 2026-03-02  
Status: 🟢 DONE

## Summary
Flux bootstrap for the internal cluster is now complete.

The blocking issues were not Flux configuration problems.
They were infrastructure policy gaps in:
1. host-side kubeconfig generation
2. control-plane API firewall policy
3. inter-node Flannel VXLAN firewall policy

Those gaps are now encoded in repo automation and were re-applied successfully.

## What Was Proven
### 1. Host-side kubeconfig now has a canonical sync path
The canonical user kubeconfig on `observatory` is now regenerated from:
1. `ops/ansible/inventory/observatory.ini`

The canonical apply path is:
1. `/Users/virgil/Dev/rita-v4/scripts/2-ops/observatory/08-sync-kubeconfig.sh`

This closed the earlier drift where:
1. `/home/virgil/.kube/config` contained `https://127.0.0.1:6443`

### 2. Host-side API access is now durably encoded
`observatory` now carries an explicit UFW allowlist for the k3s API.

Current encoded sources:
1. `192.168.5.182`
2. `192.168.5.227`

These are modeled in:
1. `/Users/virgil/Dev/rita-v4/ops/ansible/group_vars/observatory.yml`
2. `/Users/virgil/Dev/rita-v4/ops/ansible/playbooks/11-bootstrap-observatory.yml`

### 3. Inter-node Flannel traffic is now durably encoded
The real root cause of the stuck Flux reconcile was cross-node pod networking failure.

Observed failure:
1. `kustomize-controller` on `platform`
2. could not resolve or reach in-cluster services on `monitoring`
3. failed with DNS and service timeouts while trying to fetch the `source-controller` artifact

Concrete cause:
1. both nodes were listening on `udp/8472`
2. UFW on both nodes was blocking Flannel VXLAN traffic

This is now encoded in:
1. `/Users/virgil/Dev/rita-v4/ops/ansible/group_vars/observatory.yml`
2. `/Users/virgil/Dev/rita-v4/ops/ansible/group_vars/platform.yml`
3. `/Users/virgil/Dev/rita-v4/ops/ansible/playbooks/11-bootstrap-observatory.yml`
4. `/Users/virgil/Dev/rita-v4/ops/ansible/playbooks/13-bootstrap-platform.yml`

## What Was Applied
The following runbooks were applied successfully:
1. `/Users/virgil/Dev/rita-v4/scripts/2-ops/observatory/02-bootstrap-host.sh`
2. `/Users/virgil/Dev/rita-v4/scripts/2-ops/observatory/08-sync-kubeconfig.sh`
3. `/Users/virgil/Dev/rita-v4/scripts/2-ops/worker/02-bootstrap-host.sh`
4. `/Users/virgil/Dev/rita-v4/scripts/2-ops/worker/06-bootstrap-flux-github.sh`

## Flux State
Flux bootstrap now completes successfully against:
1. `SiderealMollusk/rita-v4`
2. path `ops/gitops/clusters/internal`

Verified healthy:
1. `flux check`
2. `flux get all -A`
3. `kubectl get pods -n flux-system -o wide`

Observed healthy state:
1. `bootstrapped: true`
2. `gitrepository/flux-system` is `READY=True`
3. `kustomization/flux-system` is `READY=True`

## Repo Changes In This Closure
### Firewall policy
1. added canonical k3s API allowlist vars for `observatory`
2. added canonical Flannel allowlist vars for `observatory`
3. added canonical Flannel allowlist vars for `platform`
4. wired those vars into the bootstrap playbooks

### Kubeconfig generation
1. strengthened the control-plane kubeconfig rewrite logic
2. added explicit verification of the rendered `server:` line
3. added a dedicated rerender playbook and wrapper

### Host/operator ergonomics
1. Flux bootstrap now reads durable non-secret config from repo
2. Flux bootstrap now reads the GitHub token from 1Password
3. the `observatory` kubeconfig sync wrapper is part of the canonical host-side path

## Current Known Residuals
The main remaining issues are smaller quality items, not blockers.

### 1. Literal allowlist IPs
The firewall allowlists are currently explicit IP lists.

That is acceptable for now, but a more durable next step would be to derive them from inventory identities where possible.

### 2. Ansible fact deprecation warnings
Some playbooks still use `ansible_hostname` rather than `ansible_facts["hostname"]`.

This did not block the phase, but should be cleaned up later.

## Outcome
The internal cluster now has:
1. a real second worker node
2. durable host-side kubeconfig generation
3. durable host-to-control-plane API policy
4. durable inter-node Flannel firewall policy
5. working Flux bootstrap and reconciliation

This closes the `0410` blocker note.

## Freshness Anchor
For the current internal cluster and GitOps state, use:
1. [0180-flux-bootstrap-and-initial-platform-services.md](/Users/virgil/Dev/rita-v4/docs/plans/0180-flux-bootstrap-and-initial-platform-services.md)
2. [adding-a-machine.md](/Users/virgil/Dev/rita-v4/docs/adding-a-machine.md)
