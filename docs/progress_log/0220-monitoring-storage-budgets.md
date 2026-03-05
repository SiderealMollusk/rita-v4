# 0220 Monitoring Storage Budgets

As of this update, the `observatory` monitoring stack has explicit first-pass local storage budgets instead of relying only on time-based retention and whatever disk happened to be available.

## Current budgets

1. Prometheus PVC: `10Gi`
2. Prometheus retention size: `8GB`
3. Grafana PVC: `5Gi`
4. Alertmanager PVC: `2Gi`
5. Loki PVC: `5Gi`

## Why

1. traffic volume is expected to be low
2. `observatory` is a single-node local-first monitoring box
3. bounded local storage is more useful than theoretical long retention right now
4. local disk failure remains more important than preserving short-horizon observability history

## Current retention posture

1. Prometheus keeps `7d` with an `8GB` retention size cap
2. Loki keeps `7d` retention on filesystem storage, bounded in practice by its `5Gi` PVC

## Operational implication

If Loki or Prometheus fills its PVC faster than expected, that is a signal to:

1. inspect actual usage
2. adjust budgets upward deliberately
3. avoid adding S3/MinIO complexity until the single-node local model is clearly insufficient
