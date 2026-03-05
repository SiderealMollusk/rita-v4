# 0200 Monitoring Stack Log Shipping

As of this update, the `observatory` monitoring lane moved from a thin scaffold to a usable first-pass stack.

## What changed

1. `promtail` was added as the cluster log shipper
2. Grafana is now preconfigured with a Loki datasource
3. `kube-prometheus-stack` was tightened for a single-node k3s control-plane laptop
4. install diagnostics now cover:
   - kube-prometheus-stack
   - Loki
   - Promtail
5. verification now checks:
   - Helm releases
   - pods
   - PVC binding
   - Promtail log output

## Current monitoring shape

1. `kube-prometheus-stack`
   - Prometheus
   - Grafana
   - Alertmanager
   - node-exporter and cluster metrics
2. `loki`
   - single-binary mode
   - local-path persistence
   - 7-day retention
3. `promtail`
   - node/pod log shipping into Loki

## Operating assumptions

1. this stack is intentionally local-first and low-overhead
2. local-path persistence is acceptable for now
3. losing the laptop matters more than losing short-horizon observability data
4. public exposure still remains a later step, after internal verification

## Freshness anchor

If the monitoring behavior changes after this note, treat the runbooks and values files as more authoritative than this summary:

1. `/Users/virgil/Dev/rita-v4/scripts/2-ops/observatory/11-install-monitoring-stack.sh`
2. `/Users/virgil/Dev/rita-v4/scripts/2-ops/observatory/12-verify-monitoring-stack.sh`
3. `/Users/virgil/Dev/rita-v4/ops/helm/monitoring/`
