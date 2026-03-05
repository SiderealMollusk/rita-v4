# Pangolin Blueprint Manifests

This directory is the canonical home for Pangolin resource declarations owned by this repo lane.

## Scope
These files define Pangolin resource exposure, not site bootstrap.

Use them for:
1. public resource declarations
2. private resource declarations
3. target mappings to the expected site identifier for each resource

Do not use them for:
1. site creation
2. Newt credential issuance
3. Kubernetes service installation

## Current Target Policy
Validated Newt-reachable cluster targets:
1. Grafana:
   - `observatory-kube-prometheus-grafana.monitoring.svc.cluster.local:80`
2. Prometheus:
   - `observatory-kube-prometheus-prometheus.monitoring.svc.cluster.local:9090`
3. n8n:
   - `10.43.171.251:5678` (routed through `n8n-vm` connector)

## Freshness
Start with:
1. [0240-newt-can-reach-cluster-services.md](/Users/virgil/Dev/rita-v4/docs/progress_log/0240-newt-can-reach-cluster-services.md)
2. [0150-pangolin-resource-management-for-observatory.md](/Users/virgil/Dev/rita-v4/docs/plans/0150-pangolin-resource-management-for-observatory.md)
