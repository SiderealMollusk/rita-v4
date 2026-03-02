# Node: workload-node

## Identity
- Host alias: `workload-node`
- Role: internal application and compute node
- Hardware class: 64 GB server
- Current substrate alias: `workload-pve`
- Current worker VM target: `workload-vm-worker`

## Access
- Login model should follow `virgil` + sudo
- Canonical host details now belong in:
  - `ops/ansible/inventory/proxmox.ini`
  - `ops/ansible/inventory/workload.ini`
  - `ops/ansible/inventory/workload-cluster.ini`
  - `ops/ansible/host_vars/workload-pve.yml`

## Intended Role
- application workloads
- compute tasks
- GPU-related services such as vLLM
- only minimal support agents needed for workload participation

## Not Intended For
- full monitoring stack
- CI/CD core services
- public edge role

## Verify
1. `docs/service-placement.md`
2. `docs/plans/0190-workload-node-onboarding-and-tainting.md`
3. `docs/adding-a-machine.md`
4. `scripts/2-ops/workload/`

## Status
Worker joined and labeled.
Do not treat this doc as proof that tainting or workload-local Newt decisions are complete.

## Freshness Anchor
1. [0430-workload-node-joined-and-api-policy-extended.md](/Users/virgil/Dev/rita-v4/docs/progress_log/0430-workload-node-joined-and-api-policy-extended.md)
2. [0190-workload-node-onboarding-and-tainting.md](/Users/virgil/Dev/rita-v4/docs/plans/0190-workload-node-onboarding-and-tainting.md)
