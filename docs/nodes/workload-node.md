# Node: workload-node

## Identity
- Host alias: `workload-node`
- Role: internal application and compute node
- Hardware class: 64 GB server

## Access
- Login model should follow `virgil` + sudo
- Canonical future host details belong in `ops/ansible/inventory/*.ini`

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
2. `docs/plans/0110-ops-brain-platform-workload-sequencing.md`
3. future inventory entry under `ops/ansible/inventory/`

## Status
Planned. Do not treat this doc as proof that the node is installed or configured.
