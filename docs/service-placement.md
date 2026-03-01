# Service Placement

Validated: 2026-02-27

This placement model matches prior user research and was independently re-validated during current architecture planning.

## Node Roles
1. `ops-brain`
- Hardware: 16 GB laptop
- Purpose: observability, operator-facing control, possible internal cluster control plane

2. `platform-node`
- Hardware: 12 GB NUC
- Purpose: platform services worker capacity and clean declarative lane

3. `workload-node`
- Hardware: 64 GB server
- Purpose: application and compute workloads only

4. `public edge runtime`
- Hardware: VPS
- Purpose: internet-facing Pangolin server and edge networking

## Placement
### ops-brain
- Prometheus
- Grafana
- Loki
- Alertmanager
- Uptime Kuma
- Optional: lightweight internal k8s control plane

Reason:
- monitoring benefits from operator visibility
- laptop is a good "look at it directly" station with attached display

### platform-node
- k3s worker capacity
- Gitea
- Flux-managed platform services
- shared Postgres
- optional CI runners later
- Supporting automation/platform services

Reason:
- better fit for clean declarative platform services than the operator-heavy `ops-brain`
- adds schedulable capacity without creating a second internal cluster

### workload-node
- application workloads
- heavy services
- compute/GPU tasks

Reason:
- preserve most RAM/CPU for actual workload execution
- avoid CI/monitoring/control-plane drift onto the workload box

### public edge runtime
- `pangolin-server`
- Traefik/Gerbil as installed by Pangolin
- Newt only where edge/site function requires it

Reason:
- keep public edge focused on edge concerns, not observability or CI

## Guardrails
1. Do not place the full monitoring stack on the public edge VPS.
2. Do not place CI/CD core services on the workload node unless forced by capacity constraints.
3. Keep the 64 GB server aesthetically and operationally "clean" for workloads.
4. Treat `ops-brain` as the tolerated bootstrap/monitoring edge and prefer clean platform services on `platform-node`.
