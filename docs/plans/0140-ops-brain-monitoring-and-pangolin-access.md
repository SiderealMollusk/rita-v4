# 0140 - Ops-Brain Monitoring and Pangolin Access
Status: ACTIVE
Date: 2026-02-28

## Goal
Turn the laptop `ops-brain` into the first internal monitoring/control-plane node, connect it to the working public `pangolin-server`, and establish the initial access model for dashboards and health surfaces.

## Inputs Confirmed
1. `ops-brain` is now a working Debian 12 host with SSH, sudo, k3s, Helm, and node label `rita.role=ops-brain`.
2. `pangolin-server` on the VPS is working and an organization already exists.
3. The laptop must run Newt.
4. The Mac control machine should hold the Pangolin CLI and be the place where blueprints are applied.
5. Monitoring data on the laptop is temporary for now.
6. Local retention target is short: 7 days of logs.
7. Durable storage and offsite backup are deferred until disks/enclosures arrive.

## Planning Decisions
### 1. Newt Placement
Install Newt directly on `ops-brain`.

Reason:
1. Newt is site connectivity, not central control-plane logic.
2. The laptop is the monitoring site and should register directly with Pangolin.
3. This avoids inventing another hop before the monitoring stack is even online.

### 2. Pangolin CLI Placement
Install Pangolin CLI on the Mac development/control machine, not on the laptop.

Reason:
1. Blueprints are operator workflows.
2. The Mac is already the place where 1Password, repo automation, and SSH orchestration happen.
3. This keeps the laptop focused on running the monitoring workloads, not acting as the operator workstation.

### 3. Storage Policy
Use local storage on the laptop for the first monitoring iteration.

Policy:
1. Logs retained for 7 days.
2. Metrics/data may be lost on rebuild or disk failure.
3. This is acceptable until dedicated storage arrives.

Implication:
1. Start with k3s local-path storage.
2. Do not over-engineer persistence yet.
3. Document that this is explicitly temporary and non-HA.

### 4. Access Policy
Default toward exposing operator UIs and health surfaces through Pangolin instead of raw LAN-only access.

Reason:
1. This gives one consistent access model.
2. It reduces ad-hoc direct exposure patterns.
3. It aligns with the goal of central route management via blueprints.

Constraint:
1. Do not assume Pangolin will automatically prefer direct LAN paths in a way that changes operator-visible behavior.
2. Treat Pangolin routes as the canonical operator entrypoint unless a service is deliberately LAN-only.
3. Local/LAN access can still exist as a fallback, but it is not the primary plan.

## Scope of This Phase
### In Scope
1. Install Newt on `ops-brain`.
2. Install Pangolin CLI on the Mac.
3. Verify the `ops-brain` site registration from `ops-brain` to `pangolin-server`.
4. Install the initial monitoring stack on k3s.
5. Expose selected monitoring endpoints through Pangolin.
6. Start defining blueprint-managed route declarations.
7. Define first-pass health coverage across node, pods, and apps.

### Out of Scope
1. Durable storage.
2. Offsite backups.
3. HA control plane.
4. Multi-node taint strategy.
5. Full CI/CD platform work on the NUC.
6. GPU workload restoration.

## Execution Sequence
### Phase 1 - Verify and Connect Ops-Brain
1. Add `07-verify-cluster.sh`.
2. Verify:
- `kubectl get nodes`
- node label present
- `helm version`
- kubeconfig works as `virgil`
3. Create a Pangolin site named `ops-brain` for `ops-brain`.
4. Store Newt site credentials in 1Password.
5. Install Newt on the laptop as a persistent systemd service.
6. Confirm `ops-brain` appears as connected in Pangolin.

### Phase 2 - Install Monitoring Stack
1. Create canonical chart/value locations in repo, for example:
- `ops/helm/monitoring/`
2. Pin chart sources and versions.
3. Create a no-arg runbook to install the monitoring namespace and baseline stack:
- Prometheus
- Grafana
- Loki
- Alertmanager
4. Set Loki retention target to 7 days.
5. Use local-path-backed PVCs where needed.
6. Keep exposure internal at first until services are healthy.

### Phase 3 - Add Pangolin Access Model
1. Install Pangolin CLI on the Mac.
2. Authenticate CLI against the self-hosted `pangolin-server`.
3. Create blueprint files in repo for monitoring endpoints.
4. Apply blueprints from the Mac.
5. Expose only the intended operator surfaces first:
- Grafana
- Uptime/health dashboard if added
- optional read-only Prometheus later
6. Keep Alertmanager and Loki private unless there is a strong reason to publish them.

### Phase 4 - Healthz Coverage
Define health surfaces at four layers:
1. machine health
- node exporter
- reachability
- disk, RAM, load, filesystem
2. cluster health
- node readiness
- system pods
- namespace pod health
3. app health
- Prometheus targets
- Grafana readiness
- Loki readiness
- Alertmanager readiness
4. edge/access health
- Pangolin route availability
- Newt connectivity
- public HTTPS checks for selected endpoints

## Proposed Repo Deliverables
### Scripts
1. `scripts/2-ops/ops-brain/01-bootstrap/00-run-all.sh`
2. `scripts/2-ops/ops-brain/02-services/00-run-all.sh`
3. `scripts/2-ops/ops-brain/07-verify-cluster.sh`
4. `scripts/2-ops/ops-brain/10-install-newt.sh`
5. `scripts/2-ops/ops-brain/11-install-monitoring-stack.sh`
6. `scripts/2-ops/ops-brain/12-verify-monitoring-stack.sh`

### Playbooks / Config
1. Ansible or templated systemd/config path for Newt on laptop
2. Helm values under `ops/helm/monitoring/`
3. Pangolin blueprint definitions under `ops/pangolin/blueprints/`

### Secrets / References
1. Newt site credentials stored in 1Password only
2. Pangolin CLI auth kept outside repo
3. Monitoring secrets treated minimally until stronger secret automation is introduced

## Open Technical Choices
### Monitoring Deployment Method
Recommendation:
1. Helm charts with committed values files
2. one runbook script that applies the pinned stack

Reason:
1. consistent with the k3s/ops-brain model
2. reproducible from repo
3. easier to revise than one-off raw manifests

### Newt Deployment Method
Recommendation:
1. native binary + systemd service on `ops-brain`

Reason:
1. direct machine/site identity
2. simpler than putting site connectivity inside a separate container layer on the control-plane laptop
3. aligns with Pangolin documentation for a persistent machine install

## Pass Criteria
1. `ops-brain` is visible and connected in Pangolin through Newt.
2. Monitoring stack installs reproducibly from repo.
3. Logs retain approximately 7 days locally.
4. At least one operator-facing dashboard is reachable through Pangolin.
5. Route definitions are applied from repo-driven blueprint files using Pangolin CLI on the Mac.
6. Node, pod, app, and route health all have defined checks.

## Immediate Next Actions
1. create/store the `ops-brain` Pangolin site credentials in 1Password
2. run `scripts/2-ops/ops-brain/02-services/00-run-all.sh`
3. choose the initial monitoring chart set and pinned versions
4. create `ops/helm/monitoring/` with committed values
5. install Pangolin CLI on the Mac and confirm auth flow against the self-hosted server
