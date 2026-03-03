# Topology

This is a discovery aid, not a duplicated source of truth.

Use it to answer:
1. what major nodes exist
2. which boundaries are public vs internal
3. where to verify the current state

For the most recent validated state, check the latest relevant progress note in `docs/progress_log/`.

## Current Topology Shape
1. `main-vps`
- public edge runtime
- runs `pangolin-server`
- front door for operator-facing remote access

2. `ops-brain`
- internal laptop on the LAN
- runs the internal k3s control plane
- intended home of the monitoring stack
- intended Pangolin site via Newt

3. `platform-node`
- planned internal NUC on the LAN
- intended home of a clean k3s worker node for platform services

4. `workload-node`
- planned internal 64 GB server on the LAN
- intended home of application and compute workloads

## Connection Model
1. Public internet reaches `main-vps`.
2. Operator-facing remote access is intended to go through Pangolin.
3. Internal nodes live on the LAN and are discovered/managed from repo inventories.
4. `ops-brain` is the first internal k3s cluster/control-plane node.
5. `main-vps` is not the internal cluster control plane.
6. Pangolin resources for `ops-brain` should target addresses resolvable from the Newt/site perspective, including verified `*.svc.cluster.local` cluster-local service names.

## Verify
1. Hosts/IPs:
- `ops/ansible/inventory/*.ini`
2. Public routes:
- `ops/network/routes.yml`
3. Pangolin deployment model:
- `docs/pangolin/0001-deploy-model.md`
4. Node roles:
- `docs/service-placement.md`
5. Recent validated state:
- `docs/progress_log/0100-ops-brain-bootstrap-complete.md`
- `docs/progress_log/0090-pangolin-server-working-and-node-placement.md`
- `docs/progress_log/0240-newt-can-reach-cluster-services.md`
