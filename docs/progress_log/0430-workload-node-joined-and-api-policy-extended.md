# 0430 - Workload Node Joined And API Policy Extended

Date: 2026-03-02  
Status: 🟢 DONE

## Summary
The server-side workload lane is now real.

The `workload-pve` substrate is codified in repo, `9300` was rebuilt from the Debian 12 cloud-init template as `workload`, and the new worker joined the internal k3s cluster successfully.

The final join blocker was not the VM rebuild path.
It was a missing control-plane firewall allowlist entry for the new worker IP.

## What Was Proven
### 1. The workload substrate is now canonical repo state
The physical Proxmox host and workload guest are now modeled in repo as:
1. `workload-pve`
2. `workload-vm-worker`
3. in-guest hostname `workload`

Canonical sources:
1. `/Users/virgil/Dev/rita-v4/ops/ansible/inventory/proxmox.ini`
2. `/Users/virgil/Dev/rita-v4/ops/ansible/inventory/workload.ini`
3. `/Users/virgil/Dev/rita-v4/ops/ansible/inventory/workload-cluster.ini`
4. `/Users/virgil/Dev/rita-v4/ops/ansible/host_vars/workload-pve.yml`
5. `/Users/virgil/Dev/rita-v4/ops/ansible/group_vars/workload.yml`

### 2. Rebuild from template now uses the corrected LAN model
The stale `docker-worker-big` VM state was discarded and `9300` was rebuilt as `workload`.

The corrected canonical guest network model is:
1. `192.168.6.181/22`
2. gateway `192.168.4.1`
3. nameserver `192.168.4.1`

This replaced the stale drifted values:
1. `192.168.6.181/24`
2. gateway `192.168.6.1`
3. nameserver `192.168.6.1`

### 3. First-boot SSH from the Mac was proven
After rebuilding from the corrected canonical values, first-boot SSH became reachable from the Mac host.

That proves the current operator bootstrap path is:
1. local Mac private key
2. checked-in public key path
3. cloud-init SSH key injection
4. first-boot SSH from the Mac

### 4. Workload host baseline bootstrap succeeded
The workload host bootstrap playbook completed successfully.

This proved:
1. expected hostname `workload`
2. baseline packages
3. UFW baseline
4. Flannel VXLAN allowlist on the workload host
5. fail2ban enablement

### 5. The final blocker was missing API policy on `observatory`
The workload worker failed to join k3s because `workload` could not reach:
1. `https://192.168.6.16:6443`

Root cause:
1. `observatory` UFW allowlists had been extended for `platform`
2. but not yet for `workload`

Canonical fix:
1. add `192.168.6.181` to `observatory_k3s_api_allowed_sources`
2. add `192.168.6.181` to `observatory_flannel_allowed_sources`
3. re-apply `/Users/virgil/Dev/rita-v4/scripts/2-ops/observatory/02-bootstrap-host.sh`

This is now encoded in:
1. `/Users/virgil/Dev/rita-v4/ops/ansible/group_vars/observatory.yml`
2. `/Users/virgil/Dev/rita-v4/ops/ansible/playbooks/11-bootstrap-observatory.yml`

## What Was Applied
Successful runbooks:
1. `/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/01-inspect-proxmox.sh`
2. `/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/02-rebuild-workload-vm.sh`
3. `/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/05-bootstrap-host.sh`
4. `/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/06-install-k3s-agent.sh`
5. `/Users/virgil/Dev/rita-v4/scripts/2-ops/observatory/02-bootstrap-host.sh`

Live cluster action:
1. `kubectl label node workload rita.role=workload --overwrite`

## Current Cluster State
Verified:
1. `monitoring` is `Ready` with `rita.role=observatory`
2. `platform` is `Ready` with `rita.role=platform`
3. `workload` is `Ready` with `rita.role=workload`

This means the internal cluster now has three real nodes:
1. control-plane / bootstrap edge
2. platform lane
3. workload lane

## Known Residuals
### 1. Workload validation still warns on guest-agent readiness
`03-validate-vm.sh` was relaxed so that lack of `qemu-guest-agent` does not masquerade as a silent hard failure.

This is acceptable for now, but the template should still eventually prove:
1. `qemu-guest-agent` active
2. cloud-init complete
3. SSH active

### 2. Thin-pool oversubscription is acknowledged tech debt
Proxmox warned that total thin-provisioned virtual size exceeds current thin-pool size.

This is not the current blocker, but it is real storage debt pending the NAS/storage plan.

### 3. Taints are still not applied
The cluster is still in labels-first mode.

Current validated labels:
1. `rita.role=observatory`
2. `rita.role=platform`
3. `rita.role=workload`

Intended placement policy:
1. `observatory` should not carry general app workloads
2. `platform` should prefer platform services, not become the default app lane
3. `workload` should become the default general workload target

Taints remain unapplied enforcement work, not an undecided philosophy.

### 4. Template quality still needs one stronger guarantee
The workload validation path now warns instead of failing hard when `qemu-guest-agent` is missing or inactive.

That is current tech debt.

The template should eventually guarantee:
1. `qemu-guest-agent` installed
2. `qemu-guest-agent` enabled
3. first-boot agent readiness as part of normal VM lifecycle

## Outcome
The repo now has:
1. a canonical workload substrate identity
2. a canonical workload worker identity
3. a working rebuild path from template
4. a working first-boot SSH path
5. a working workload bootstrap path
6. a joined and labeled workload worker in the internal cluster
7. extended control-plane firewall policy encoded in automation

## Freshness Anchor
For current internal cluster node topology and machine-onboarding state, use:
1. [0190-workload-node-onboarding-and-tainting.md](/Users/virgil/Dev/rita-v4/docs/plans/0190-workload-node-onboarding-and-tainting.md)
2. [adding-a-machine.md](/Users/virgil/Dev/rita-v4/docs/adding-a-machine.md)
