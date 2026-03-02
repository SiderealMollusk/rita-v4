# Clusters

This doc answers: what clusters/environments exist, what they are for, and where to verify them.

For the most recent validated state, use the latest relevant progress note in `docs/progress_log/`.

## 1. Public Edge Runtime
Purpose:
- host `pangolin-server`
- terminate public/operator-facing access

Shape:
- single VPS runtime
- Docker + Docker Compose v2
- not the internal k3s control plane

Verify:
1. `scripts/2-ops/vps/06-verify-pangolin-server.sh`
2. `ops/ansible/inventory/vps.ini`
3. `ops/network/routes.yml`

## 2. Internal Ops Cluster
Purpose:
- internal k3s control plane
- monitoring stack home

Shape:
- current control plane is `ops-brain`
- repo now carries a codified worker-join path for the `platform-node`
- intended steady-state shape is `ops-brain` + `platform-node`

Verify:
1. `scripts/2-ops/ops-brain/07-verify-cluster.sh`
2. `scripts/2-ops/worker/05-verify-cluster.sh`
3. `ops/ansible/inventory/internal-cluster.ini`
4. `ops/ansible/group_vars/internal_cluster.yml`
5. `docs/adding-a-machine.md`
6. `docs/progress_log/0420-flux-bootstrap-complete-and-cluster-network-policy-codified.md`

## 3. Local Simulation Cluster
Purpose:
- local experiments and throwaway validation

Shape:
- local k3d/k3s-style simulation context
- not a canonical production/runtime environment

Verify:
1. `scripts/2-ops/devcontainer/`
2. `scripts/1-session/`

## Notes
1. `main-vps` and `ops-brain` are separate operational domains.
2. A fresh agent should not assume there is only one cluster.
3. Service placement lives in `docs/service-placement.md`, not here.
