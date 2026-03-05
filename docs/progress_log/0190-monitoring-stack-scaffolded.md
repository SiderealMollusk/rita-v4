# 0190 Monitoring Stack Scaffolded

As of this update, the `observatory` services lane now includes a first-pass monitoring stack install and verification path.

## What was added

1. `scripts/2-ops/observatory/11-install-monitoring-stack.sh`
2. `scripts/2-ops/observatory/12-verify-monitoring-stack.sh`
3. `ops/helm/monitoring/kube-prometheus-stack.values.yaml`
4. `ops/helm/monitoring/loki.values.yaml`

## Deployment shape

The current monitoring stack is intentionally pragmatic:

1. `kube-prometheus-stack`
   - Prometheus
   - Grafana
   - Alertmanager
   - node-exporter and cluster metrics
2. `loki`
   - monolithic single-binary mode
   - filesystem storage
   - 7-day retention

## Operational policy

1. storage is local-path on `observatory`
2. rebuild/data loss is accepted for now
3. no public ingress is enabled by default
4. Newt remains the prerequisite layer before monitoring

## What this does not do yet

1. it does not expose Grafana or Prometheus through Pangolin yet
2. it does not add a cluster log shipper beyond the Loki backend
3. it does not solve long-term durable storage

## Next reading anchor

If monitoring install behavior changes, treat this note as the current scaffold timestamp and check the runbooks and values files directly.
