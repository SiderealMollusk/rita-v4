# Ops-Brain Pangolin Blueprints

This directory is the canonical home for Pangolin resource declarations that target the `ops-brain` site.

## Scope
These files define Pangolin resource exposure, not site bootstrap.

Use them for:
1. public resource declarations
2. private resource declarations
3. target mappings to the `ops-brain` site

Do not use them for:
1. site creation
2. Newt credential issuance
3. Kubernetes service installation

## Current Target Policy
Validated Newt-reachable cluster targets:
1. Grafana:
   - `ops-brain-kube-prometheus-grafana.monitoring.svc.cluster.local:80`
2. Prometheus:
   - `ops-brain-kube-prometheus-prometheus.monitoring.svc.cluster.local:9090`

## Freshness
Start with:
1. [0240-newt-can-reach-cluster-services.md](/Users/virgil/Dev/rita-v4/docs/progress_log/0240-newt-can-reach-cluster-services.md)
2. [0150-pangolin-resource-management-for-ops-brain.md](/Users/virgil/Dev/rita-v4/docs/plans/0150-pangolin-resource-management-for-ops-brain.md)
