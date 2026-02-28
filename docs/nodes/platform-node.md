# Node: platform-node

## Identity
- Host alias: `platform-node`
- Role: internal platform services node
- Hardware class: 12 GB NUC

## Access
- Login model should follow `virgil` + sudo
- Canonical future host details belong in `ops/ansible/inventory/*.ini`

## Intended Role
- Gitea
- CI runners
- Argo CD
- Zot
- supporting platform automation

## Not Intended For
- full public edge runtime
- full monitoring stack primary placement
- heavy application/compute workloads

## Verify
1. `docs/service-placement.md`
2. `docs/plans/0110-ops-brain-platform-workload-sequencing.md`
3. future inventory entry under `ops/ansible/inventory/`

## Status
Planned. Do not treat this doc as proof that the node is installed or configured.
