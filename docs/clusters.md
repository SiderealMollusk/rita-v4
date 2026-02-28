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
- currently single-node `k3s` on `ops-brain`
- intended to grow later with additional physical nodes

Verify:
1. `scripts/2-ops/ops-brain/07-verify-cluster.sh`
2. `ops/ansible/inventory/ops-brain.ini`
3. `ops/ansible/group_vars/ops_brain.yml`
4. `docs/progress_log/0100-ops-brain-bootstrap-complete.md`

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
