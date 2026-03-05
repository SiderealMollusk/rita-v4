# 0150 - Pangolin Resource Management For Ops-Brain
Status: ACTIVE
Date: 2026-03-01

## Goal
Move `observatory` service exposure from ad-hoc port-forwarding to repo-managed Pangolin resource declarations.

This plan starts after:
1. `pangolin-server` is working on the VPS
2. the `observatory` site exists in Pangolin
3. Newt is connected from `observatory`
4. the `observatory` monitoring stack is running

## Freshness
Start with the latest relevant progress note before trusting this plan:
1. [0240-newt-can-reach-cluster-services.md](/Users/virgil/Dev/rita-v4/docs/progress_log/0240-newt-can-reach-cluster-services.md)

## What Was Verified
The following was proven from the Newt pod itself:

1. cluster-local DNS resolves from the site perspective
2. Grafana is reachable at:
   - `observatory-kube-prometheus-grafana.monitoring.svc.cluster.local:80`
3. Prometheus is reachable at:
   - `observatory-kube-prometheus-prometheus.monitoring.svc.cluster.local:9090`

That means Pangolin resources can target `*.svc.cluster.local` addresses from the site perspective.

## Resource Model
Pangolin resources should be managed as a separate declarative layer from Kubernetes.

### Layer 1 - Cluster Truth
Owned by:
1. Helm values
2. Kubernetes Services
3. namespaces and ports

Examples:
1. `observatory-kube-prometheus-grafana.monitoring.svc.cluster.local:80`
2. `observatory-kube-prometheus-prometheus.monitoring.svc.cluster.local:9090`
3. `observatory-loki.monitoring.svc.cluster.local:3100`

### Layer 2 - Pangolin Resource Truth
Owned by:
1. blueprint files in repo
2. Pangolin apply workflow from the Mac host

Examples:
1. Grafana public resource
2. optional Prometheus public resource

### Layer 3 - Verification
Owned by:
1. runbooks
2. curl/browser checks
3. Pangolin UI confirmation

## What Blueprints Are For
Use blueprints for:
1. public resource definitions
2. private resource definitions
3. resource target mappings to sites
4. repeatable route/access declarations

Do not use blueprints for:
1. site creation
2. Newt credential issuance
3. bootstrap identity flows

## Exposure Policy
### First Public Candidate
1. Grafana

Reason:
1. it is the main operator UI
2. it has clear human value
3. we already proved Newt can reach it from the site side

### Optional Second Candidate
1. Prometheus

Reason:
1. useful for operator debugging
2. less friendly than Grafana
3. should remain optional, not default

### Keep Internal For Now
1. Loki
2. Alertmanager
3. operator internals

Reason:
1. no strong reason to publish them yet
2. smaller public/operator surface is safer and easier to reason about

## Canonical Repo Locations
1. blueprint artifacts:
   - `ops/pangolin/blueprints/observatory/`
2. host-side operator scripts:
   - `scripts/2-ops/host/`
3. service verification:
   - `scripts/2-ops/observatory/12-verify-monitoring-stack.sh`

## Proposed Blueprint Targets
### Grafana
1. site: Pangolin site identifier from `pangolin_site_observatory.identifier`
2. hostname:
   - `observatory-kube-prometheus-grafana.monitoring.svc.cluster.local`
3. method: `http`
4. port: `80`

### Prometheus
1. site: Pangolin site identifier from `pangolin_site_observatory.identifier`
2. hostname:
   - `observatory-kube-prometheus-prometheus.monitoring.svc.cluster.local`
3. method: `http`
4. port: `9090`

## Execution Sequence
### Phase 1 - Artifact Definition
1. create `ops/pangolin/blueprints/observatory/`
2. add first monitoring blueprint draft
3. keep it limited to validated targets only

### Phase 2 - CLI Validation
1. install Pangolin CLI on the Mac host
2. verify actual `apply blueprint` support and syntax
3. verify auth/login workflow against `pangolin-server`

### Phase 3 - First Apply
1. apply Grafana resource only
2. confirm resource appears in Pangolin
3. confirm browser access works through Pangolin

### Phase 4 - Expand Carefully
1. optionally add Prometheus
2. keep Loki internal unless a concrete use case emerges

## Deliverables
1. one canonical monitoring blueprint for `observatory`
2. one host-side apply workflow
3. one verification workflow for Pangolin-routed Grafana

## Guardrails
1. do not duplicate Kubernetes service truth in multiple docs beyond the blueprint artifact and current verification docs
2. do not expose Loki just because it is available
3. do not assume the Pangolin CLI schema without checking the live CLI
4. treat cluster-local service DNS as valid only because it was explicitly verified from the Newt pod

## Immediate Next Actions
1. add the blueprint directory and draft artifact
2. verify/install Pangolin CLI on the Mac host
3. apply Grafana first
4. verify route externally
