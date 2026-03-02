# Node: platform-node

## Identity
- Host alias: `platform-node`
- Role: internal platform services node
- Hardware class: 12 GB NUC

## Access
- Login model should follow `virgil` + sudo
- Canonical host details belong in:
  - `ops/ansible/inventory/platform.ini`
  - `ops/ansible/inventory/internal-cluster.ini`

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
3. `scripts/2-ops/nuc/`
4. `scripts/2-ops/worker/`
5. `ops/gitops/clusters/internal/`

## Status
Planned. Do not treat this doc as proof that the node is installed or configured.
