# Lab Nodes

Human-readable inventory for lab machines and roles.
Canonical machine/IP values for automation live in Ansible inventory.

## Source of truth
- Hosts/IPs: `ops/ansible/inventory/*.ini`
- Endpoint/domain vars: `ops/ansible/group_vars/*.yml`
- Hittable routes: `ops/network/routes.yml`
- Secrets: 1Password only (not in repo)

## Nodes
- [main-vps](/Users/virgil/Dev/rita-v4/docs/nodes/main-vps.md)
- Planned:
  - `ops-brain` (16 GB laptop): monitoring stack, operator-facing services, possible internal control plane
  - `platform-node` (12 GB NUC): CI/CD, registry, Git, deployment platform services
  - `workload-node` (64 GB server): application workloads only

## Placement Model
This placement reflects prior user research and was independently re-validated during current planning:
- `ops-brain`: best fit for monitoring because it can drive a real display/console workflow and favors operator visibility over raw compute
- `platform-node`: best fit for CI/CD and platform support services
- `workload-node`: kept clean for application and compute load
