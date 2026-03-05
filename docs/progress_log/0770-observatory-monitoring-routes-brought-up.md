# 0770 Observatory Monitoring Routes Brought Up

Freshness stamp:
- 2026-03-05 15:31 PST (background agent)

## Summary
Observatory monitoring services were brought up and verified in-cluster, Pangolin site state was reconciled from SoT, and monitoring routes were re-applied with Pangolin UI auth disabled per operator decision.

## What Changed
1. Ran full observatory bootstrap/services verification and fixed blocking issues.
2. Reconciled Pangolin site and OP items via:
   - `scripts/2-ops/host/27-reconcile-pangolin-sites.sh`
3. Confirmed canonical site item now exists:
   - `pangolin_site_observatory`
4. Applied observatory monitoring blueprint via:
   - `scripts/2-ops/host/20-apply-observatory-monitoring-blueprint.sh`
5. Updated monitoring blueprint auth mode:
   - `auth.sso-enabled: false` for Grafana, Prometheus, Alertmanager, Uptime Kuma
6. Corrected Prometheus/Alertmanager target hostnames in blueprint to match live service names:
   - `observatory-kube-prometheu-prometheus.monitoring.svc.cluster.local`
   - `observatory-kube-prometheu-alertmanager.monitoring.svc.cluster.local`
7. Removed `ops-brain` fallback logic from observatory/host scripts (no legacy fallback path).

## Verified State
1. Monitoring pods/services present and healthy in namespace `monitoring`:
   - Grafana, Prometheus, Alertmanager, Loki, Promtail, Uptime Kuma all running.
2. Newt connector running and targeting observatory service hostnames.
3. External route checks after apply:
   - `grafana.virgil.info` -> reachable (`302 /login`, app-level auth)
   - `prometheus.virgil.info` -> reachable (`302` on GET)
   - `alertmanager.virgil.info` -> reachable (`200`)
   - `uptime.virgil.info` -> reachable (`302 /setup-database`)

## Notes
1. Uptime Kuma is freshly deployed and not initialized yet (`/setup-database` expected).
2. Loki is intentionally internal-only right now (no public Pangolin resource in SoT blueprint).
