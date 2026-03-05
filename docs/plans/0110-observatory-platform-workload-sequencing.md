# 0110 - Ops-Brain / Platform / Workload Sequencing
Status: 🟡 ACTIVE
Date: 2026-02-27

## Goal
Build the next phase of the lab in the right order:
1. rebuild the 16 GB laptop as the `observatory`
2. stand up a full monitoring stack there
3. learn and use the Pangolin CLI for route/blueprint management against the working `pangolin-server`
4. design and implement the CI/CD platform on the 12 GB NUC
5. bring the 64 GB GPU workload server back online cleanly
6. unify health checks across machines, containers, and apps

## Freshness
The overall sequencing still holds, but the platform-service details have moved forward.

For the current platform direction, use:
1. [0160-platform-flux-gitea-and-worker-expansion.md](/Users/virgil/Dev/rita-v4/docs/plans/0160-platform-flux-gitea-and-worker-expansion.md)

This plan assumes the currently validated placement model:
- `observatory` = laptop
- `platform-node` = NUC
- `workload-node` = 64 GB server
- `public edge runtime` = VPS

## Phase 1 - Rebuild Ops-Brain Laptop
### Objective
Reinstall Ubuntu on the laptop and make it the long-term home for monitoring and operator-facing control.

### Approach
1. Reinstall Ubuntu on bare metal.
2. Use Ansible from this repo to bootstrap the laptop directly.
3. Install k3s on the laptop as the internal control plane.
4. Run the monitoring stack on that cluster.

### Decision
No VM is required initially on the laptop.
Use bare-metal k3s on the laptop as the `observatory` control plane and initial monitoring node.

### Deliverables
1. New inventory entry and node doc for `observatory`
2. Ansible/bootstrap scripts for laptop runtime + k3s control plane
3. Repeatable monitoring deployment scripts

### Pass Criteria
1. Laptop is reproducibly bootstrapped from this repo
2. k3s control plane is installed via automation
3. Monitoring stack comes up after a fresh install without hand edits

## Phase 2 - Full Monitoring Stack
Detailed plan:
- `docs/plans/0120-observatory-k3s-monitoring-stack.md`

### Target Stack
1. Prometheus
2. Grafana
3. Loki
4. Alertmanager
5. Uptime Kuma

### Notes
1. Keep storage/processing on the laptop, not the public edge VPS.
2. Laptop is intentionally the machine with the monitor attached so the operator can directly inspect dashboards and alerts.

### Monitoring Scope
1. public edge VPS
2. future NUC platform node
3. workload server
4. Pangolin endpoint(s)

### Pass Criteria
1. dashboards are reachable locally on the laptop
2. alerts can fire from synthetic or host conditions
3. public edge health is externally and internally visible

## Phase 3 - Learn Pangolin CLI for Route Management
Detailed plan:
- `docs/plans/0130-pangolin-cli-route-management.md`

### Objective
Use the actual Pangolin CLI correctly this time, for blueprints and route management, against the already-working `pangolin-server`.

### Questions to Answer
1. how blueprints are represented
2. how routes are created/updated/deleted by CLI
3. how monitoring services should be exposed through Pangolin
4. which services should stay internal-only vs Pangolin-managed

### Deliverables
1. documented Pangolin CLI workflow
2. one or more route-management scripts or runbooks
3. updated route catalog in `ops/network/routes.yml`

### Pass Criteria
1. monitoring routes can be created reproducibly
2. route changes are documented and reversible

## Phase 4 - CI/CD Platform Design on NUC
### Objective
Design the platform-node before installing everything blindly.

This phase is superseded in detail by:
1. [0160-platform-flux-gitea-and-worker-expansion.md](/Users/virgil/Dev/rita-v4/docs/plans/0160-platform-flux-gitea-and-worker-expansion.md)

### Questions to Answer
1. what actually belongs in CI/CD
2. what deploys through GitOps vs manual runbooks
3. which services need Gitea
4. how Flux is bootstrapped and becomes authoritative
5. how registry, build artifacts, and deployment manifests are organized

### Expected Services
1. Gitea
2. Flux
3. shared Postgres
4. optional CI runners later
5. optional registry later

### Deliverables
1. service design doc for CI/CD flow
2. deployment boundaries between `platform-node`, `observatory`, `workload-node`, and VPS
3. implementation runbooks/scripts

### Pass Criteria
1. clear answer for what goes through CI/CD
2. clear deployment model for apps and infrastructure
3. NUC services fit within the RAM budget

## Phase 5 - Bring GPU Workload Server Back Online
### Objective
Restore the 64 GB workload server as a clean workload-only machine.

### Target Services
1. vLLM
2. Newt
3. any required workload-side support only

### Guardrail
Do not drift CI/CD or the full monitoring stack onto the workload server.

### Pass Criteria
1. vLLM runs cleanly
2. Newt connectivity is established if required
3. workload server remains focused on workload duties

## Phase 6 - Healthz Unification
### Objective
Create a consistent model for health visibility across:
1. machines
2. containers
3. applications
4. Pangolin-exposed services

### Areas to Cover
1. host health
2. Docker/container health
3. app-specific `/healthz` or equivalent endpoints
4. synthetic probes via Kuma
5. Prometheus scrape targets and alert rules

### Deliverables
1. healthz inventory or conventions doc
2. per-service health checks
3. alerting criteria

### Pass Criteria
1. every critical service has an agreed health signal
2. every critical node has host-level monitoring
3. Pangolin routes expose only what should be externally checked

## Execution Order
1. Reinstall laptop
2. Bootstrap laptop with k3s control plane
3. Stand up monitoring stack
4. Learn Pangolin CLI and expose monitoring services appropriately
5. Design CI/CD flow on NUC
6. Implement NUC platform services
7. Restore GPU workload server
8. Unify healthz across all layers

## Immediate Next Actions
1. add a node doc and inventory path for the laptop `observatory`
2. create laptop bootstrap scripts under the appropriate ops domain
3. define the initial k3s placement model for laptop-hosted monitoring
4. document which monitoring services should be Pangolin-routed vs internal-only
