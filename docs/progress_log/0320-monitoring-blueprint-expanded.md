# 0320 Monitoring Blueprint Expanded

As of this update, the `observatory` Pangolin monitoring blueprint no longer targets only Grafana.

What changed:
1. the monitoring blueprint now includes:
   - `grafana.virgil.info`
   - `prometheus.virgil.info`
   - `alertmanager.virgil.info`
2. all three resources are marked with:
   - `auth.sso-enabled: true`
3. the route catalog now includes canonical entries for:
   - `prometheus.virgil.info`
   - `alertmanager.virgil.info`

What did not change:
1. Loki is still intentionally internal-only
2. the blueprint still targets cluster-local service DNS from the Newt/site perspective

Why:
1. Grafana, Prometheus, and Alertmanager are operator UIs with clear human value
2. Loki is better consumed through Grafana for now
3. publishing the raw Loki API is not justified yet
