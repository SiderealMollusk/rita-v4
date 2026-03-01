# Node: platform-node

## Identity
- Host alias: `platform-node`
- Role: internal platform services worker lane
- Hardware class: 12 GB NUC

## Access
- Login model should follow `virgil` + sudo
- Canonical future host details belong in `ops/ansible/inventory/*.ini`

## Intended Role
- worker capacity for the internal k3s cluster
- Gitea
- Flux-managed platform services
- shared Postgres for platform and early app workloads
- optional CI runners later
- supporting platform automation

## Not Intended For
- full public edge runtime
- full monitoring stack primary placement
- heavy application/compute workloads

## Verify
1. `docs/service-placement.md`
2. `docs/plans/0160-platform-flux-gitea-and-worker-expansion.md`
3. future inventory entry under `ops/ansible/inventory/`

## Status
Planned. Do not treat this doc as proof that the node is installed or configured.
