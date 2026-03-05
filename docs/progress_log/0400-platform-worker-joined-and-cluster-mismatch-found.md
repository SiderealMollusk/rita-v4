# 0400 - Platform Worker Joined And Cluster Naming Drift Exposed

Date: 2026-03-01  
Status: ✅ COMPLETE

## Summary
The NUC-backed platform worker lane is now real.

Completed outcomes:
1. the physical Proxmox substrate was formalized as `platform-nuc`
2. VM identities were formalized as:
- `platform-vm-newt`
- `platform-vm-worker`
3. VM `9200` was rebuilt from the Debian 12 cloud-init template
4. VM `9200` was renamed in Proxmox to `platform`
5. the worker joined the internal k3s cluster successfully
6. the cluster now has two healthy nodes:
- `monitoring` (control plane)
- `platform` (worker)

## What Was Proven
1. Proxmox access on `platform-nuc` is working from the host runbooks
2. the worker rebuild path can:
- destroy old `9200`
- clone `9000`
- apply cloud-init user/network data
- expand the disk
- install operator SSH keys
3. Ansible can reach the rebuilt worker
4. the worker can join k3s and register as node `platform`
5. the cluster sees both nodes as `Ready`

## Key Runtime Facts Captured
### `platform-nuc`
1. Proxmox host IP:
- `192.168.5.173`

### `platform-vm-newt`
1. VMID:
- `9100`
2. IP:
- `192.168.5.181`

### `platform-vm-worker`
1. VMID:
- `9200`
2. IP:
- `192.168.5.182`
3. gateway:
- `192.168.4.1`
4. in-guest hostname:
- `platform`

## Resource Adjustment
The repo default for the worker VM was reduced from `8192 MB` to `4096 MB`.

Reason recorded by observed host state:
1. the 12 GB NUC did not have enough comfortable headroom for an 8 GB default worker allocation
2. `newt` was observed to be substantially over-allocated on RAM relative to actual use

## Failure Found During Join
The worker did not join cleanly on the first attempt.

Observed failure:
1. `k3s-agent` on `platform` repeatedly failed to validate connection to `https://192.168.6.16:6443`

Root cause:
1. `ufw` on the control-plane host allowed SSH only
2. k3s API traffic from the worker to port `6443/tcp` was blocked

Operational fix applied:
1. allow worker traffic from `192.168.5.182` to `192.168.6.16:6443`
2. restart `k3s-agent`

After that:
1. node `platform` registered successfully
2. the node became `Ready`

## Naming Drift Exposed
The repo still referred to the control-plane Kubernetes node as `observatory`, but the actual cluster node name is `monitoring`.

This caused:
1. label automation to target a nonexistent node name
2. cluster verification to fail against `observatory`

Repo-side tactical fix:
1. internal cluster label mapping now targets:
- `monitoring` => `rita.role=observatory`
- `platform` => `rita.role=platform`
2. cluster verification playbooks were corrected to use properly quoted `kubectl` jsonpath expressions

## Current State
1. the internal cluster is now multi-node
2. `platform` exists as schedulable worker capacity
3. `monitoring` remains the control plane and monitoring home
4. the repo now has a real Proxmox substrate inventory plus explicit worker/newt VM identities

## Follow-Up Work
1. codify the k3s API firewall rule on the control-plane host in automation
2. finish the label/verify worker steps against the corrected node map
3. bootstrap Flux from GitHub
4. deploy `platform-postgres`
5. deploy `Gitea`

## Freshness Anchor
For the current platform worker shape and next actions, use:
1. [0170-platform-worker-execution-plan.md](/Users/virgil/Dev/rita-v4/docs/plans/0170-platform-worker-execution-plan.md)
