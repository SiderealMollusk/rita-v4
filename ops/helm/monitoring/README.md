# Monitoring Helm Config

This directory is the canonical home for the initial `ops-brain` monitoring stack.

Planned contents:
1. committed values files for kube-prometheus-stack, Loki, and Promtail
2. first-pass storage/retention settings
3. no public ingress by default

Current policy:
1. use k3s local-path storage first
2. accept rebuild/data loss for now
3. target 7-day local log retention
4. keep secrets out of git
5. keep Grafana and Prometheus internal until Pangolin routing is added deliberately
6. keep explicit local storage budgets small and visible

Current files:
1. `kube-prometheus-stack.values.yaml`
2. `loki.values.yaml`
3. `promtail.values.yaml`

Current first-pass storage budgets:
1. Prometheus PVC: `10Gi`
2. Prometheus retention size: `8GB`
3. Grafana PVC: `5Gi`
4. Alertmanager PVC: `2Gi`
5. Loki PVC: `5Gi`
