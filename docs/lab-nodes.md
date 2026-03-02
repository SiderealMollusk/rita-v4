# Lab Nodes

Human-readable node index.
Canonical machine/IP values for automation live in Ansible inventory.

Use the latest relevant progress note in `docs/progress_log/` as the practical timestamp for how current these summaries are.

## Source of truth
- Hosts/IPs: `ops/ansible/inventory/*.ini`
- Endpoint/domain vars: `ops/ansible/group_vars/*.yml`
- Hittable routes: `ops/network/routes.yml`
- Secrets: 1Password only (not in repo)

## Nodes
- [main-vps](/Users/virgil/Dev/rita-v4/docs/nodes/main-vps.md)
- [ops-brain](/Users/virgil/Dev/rita-v4/docs/nodes/ops-brain.md)
- [platform-node](/Users/virgil/Dev/rita-v4/docs/nodes/platform-node.md)
- [workload-node](/Users/virgil/Dev/rita-v4/docs/nodes/workload-node.md)

## Placement Model
This placement reflects prior user research and later repo-side validation:
- `ops-brain`: monitoring, operator-facing control, internal k3s control plane
- `platform-node`: platform services worker capacity and clean declarative lane
- `workload-node`: application and compute load
- `main-vps`: public edge runtime and `pangolin-server`

## Verify
1. machine identity/IPs: `ops/ansible/inventory/*.ini`
2. role placement: `docs/service-placement.md`
3. public/operator routes: `ops/network/routes.yml`
4. recent validated state: `docs/progress_log/0420-flux-bootstrap-complete-and-cluster-network-policy-codified.md`, `docs/progress_log/0400-platform-worker-joined-and-cluster-mismatch-found.md`, `docs/progress_log/0390-platform-flux-gitea-direction-locked.md`
