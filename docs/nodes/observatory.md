# Node: observatory

## Identity
- Host alias: `observatory`
- Role: internal k3s control plane and monitoring node
- Hardware class: 16 GB laptop

## Freshness
- Start with the latest relevant progress note before trusting this summary.
- Current best anchor: [0200-monitoring-stack-log-shipping.md](/Users/virgil/Dev/rita-v4/docs/progress_log/0200-monitoring-stack-log-shipping.md)

## Access
- SSH user: `virgil`
- SSH port: `22`
- Root access: bootstrap/break-glass only
- Expected admin model: `virgil` + sudo

## Network
- Inventory source: `ops/ansible/inventory/observatory.ini`
- Current automation IP is stored in inventory, not duplicated here
- Public routes should not be inferred from this node doc

## Runtime
- OS: Debian 12
- Cluster role: single-node k3s control plane (current)
- Intended services: monitoring stack, operator-facing observability services, Newt
- Not intended for: CI/CD core services, general workload sprawl

## Runs Now
1. Debian 12 base host
2. k3s single-node control plane
3. Helm client for cluster installs
4. `rita.role=observatory` node label
5. Newt as a Helm-managed site connector
6. first-pass monitoring lane in repo:
   - `kube-prometheus-stack`
   - `loki`
   - `promtail`

Verify:
1. `scripts/2-ops/observatory/07-verify-cluster.sh`
2. `kubectl get nodes --show-labels`
3. `scripts/2-ops/observatory/02-services/00-run-all.sh`

## Planned Next
1. verify monitoring stack healthy on-cluster
2. expose selected monitoring surfaces through Pangolin
3. add route/blueprint discipline from the Mac host

Verify in repo:
1. `scripts/2-ops/observatory/10-install-newt.sh`
2. `scripts/2-ops/observatory/11-install-monitoring-stack.sh`
3. `scripts/2-ops/observatory/12-verify-monitoring-stack.sh`
4. `docs/plans/0140-observatory-monitoring-and-pangolin-access.md`

## Must Not Run
1. CI/CD core services
2. general application workload sprawl
3. public edge runtime responsibilities that belong on `main-vps`

Cross-check:
1. `docs/service-placement.md`
2. `docs/nodes/platform-node.md`
3. `docs/nodes/workload-node.md`

## Verify
1. `scripts/2-ops/observatory/07-verify-cluster.sh`
2. `ops/ansible/group_vars/observatory.yml`
3. `docs/progress_log/0200-monitoring-stack-log-shipping.md`
