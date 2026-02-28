# 0120 - Ops-Brain K3s Monitoring Stack
Status: 🟡 ACTIVE
Date: 2026-02-27

## Goal
Rebuild the 16 GB laptop as the `ops-brain` and run the full monitoring stack on a bare-metal k3s cluster hosted directly on that laptop.

## Decision
Use bare-metal Ubuntu + k3s on the laptop.

Do not add a VM layer first.

Reason:
1. this machine is already dedicated to ops/monitoring duties
2. a VM adds complexity without solving the current problem
3. k3s on bare metal is enough to validate cluster operations, monitoring placement, and future worker joins

## Cluster Role
The laptop becomes:
1. internal k3s control plane
2. first monitoring node
3. operator-facing console with a real display attached

This matches the intended `ops-brain` role.

## Initial Architecture
### Phase 1
Single-node k3s on the laptop:
1. control plane
2. etcd/sqlite state
3. monitoring workloads

This is acceptable at the beginning because:
1. the laptop is intentionally a special-purpose ops machine
2. monitoring is more important than high-availability at this stage
3. you want fast iteration and reproducible automation first

### Phase 2
When other physical targets join:
1. keep laptop as control plane
2. decide which workloads remain pinned to laptop
3. allow selected support workloads to move to other nodes only when intentional

## VM Question
### Recommendation
No VM for the control plane initially.

### Why
1. You already have a real physical host reserved for ops.
2. Nested abstraction makes troubleshooting harder.
3. k3s control plane on bare metal is simpler to automate and recover.
4. You can add a VM boundary later only if isolation becomes necessary.

## Taints and Placement Strategy
### Short Version
Use labels first. Add taints deliberately once more physical nodes exist.

### Initial Single-Node State
On day one, keep the laptop schedulable.

Why:
1. it is the only node in the internal cluster
2. the monitoring stack needs somewhere to run
3. over-constraining the node too early just creates friction

### Prepare for Future Growth
When additional physical workers join:
1. label the laptop as `rita.role=ops-brain`
2. label future nodes by role:
- `rita.role=platform`
- `rita.role=workload`
3. add node affinity to monitoring workloads so they prefer or require `rita.role=ops-brain`

### Taints Later
Once the cluster has other physical nodes:
1. consider tainting the laptop to keep general workloads off it
2. add matching tolerations only to monitoring/control workloads

Recommended future taint example:
```text
rita.role=ops-brain:NoSchedule
```

Recommended matching pattern:
1. monitoring namespace workloads tolerate that taint
2. monitoring workloads also use node affinity for `rita.role=ops-brain`

This gives:
1. explicit placement
2. protection against workload drift onto the ops machine
3. room to add more physical nodes cleanly

## Monitoring Stack to Run Here
1. Prometheus
2. Grafana
3. Loki
4. Alertmanager
5. Uptime Kuma

Optional later:
1. Tempo
2. dedicated log collectors
3. long-term metrics storage if needed

## Why Monitoring Belongs on the Laptop
1. you explicitly want a machine you can physically look at
2. dashboard visibility is an operational advantage
3. alert triage and incident handling benefit from a stable operator-facing console
4. this avoids pushing observability load onto the public edge or workload server

## What This Cluster Should Monitor
1. public edge VPS
2. future NUC platform node
3. workload server
4. Pangolin endpoint(s)
5. Newt-connected services where appropriate

## Bootstrap Plan
1. reinstall Ubuntu on laptop
2. create inventory entry for `ops-brain`
3. bootstrap base host with Ansible
4. install k3s control plane
5. install monitoring namespace and stack manifests/charts
6. configure persistent storage expectations explicitly
7. expose only the right surfaces through Pangolin

## Deliverables
1. `ops-brain` inventory entry
2. node doc for the laptop
3. Ansible scripts/playbooks for:
- host bootstrap
- k3s install
- monitoring stack install
4. monitoring placement policy
5. route exposure policy for external dashboards

## Pass Criteria
1. laptop can be rebuilt and rejoined from repo automation
2. k3s control plane comes up reproducibly
3. monitoring stack becomes healthy on the laptop
4. monitoring workloads have an explicit placement model
5. later worker joins do not accidentally absorb or evict monitoring responsibilities

## Immediate Next Actions
1. add `ops-brain` to inventory/docs
2. create `scripts/2-ops/ops-brain/` or equivalent domain for laptop runbooks
3. define initial labels/taints policy in code and docs
4. choose monitoring deployment method:
- Helm charts
- committed manifests
5. document storage expectations for Prometheus/Grafana/Loki
