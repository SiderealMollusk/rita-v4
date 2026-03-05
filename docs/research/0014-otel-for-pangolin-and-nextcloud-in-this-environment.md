# 0014 - OpenTelemetry for Pangolin + Nextcloud (Environment-Specific)
Date: 2026-03-05
Status: Completed

## Goal
Define a stable, low-risk path to add OpenTelemetry around Pangolin and Nextcloud in this environment, with concrete rollout steps and realistic limits.

## Environment snapshot (from repo)
1. Pangolin endpoint/domain: `https://pangolin.virgil.info` (`ops/network/routes.yml`).
2. Pangolin runs on main VPS (`public-edge`) with expected public ports `80/443` TCP and `51820/21820` UDP (`ops/ansible/group_vars/vps.yml`).
3. Official Nextcloud is VM-first: `cloud.virgil.info -> 192.168.6.183:80` (`ops/nextcloud/instances.yaml`, `ops/pangolin/blueprints/observatory/nextcloud-cloud.blueprint.yaml`).
4. Current Nextcloud version pin is `32.0.6` (`ops/ansible/group_vars/nextcloud.yml`).
5. Existing observability stack is Prometheus + Loki (+ Promtail) on `observatory` (`ops/helm/monitoring/README.md`).

## What Pangolin supports today (relevant to OTEL)
From Pangolin docs, metrics can be enabled globally and exported in OTEL format (OTLP) or scraped by Prometheus:
1. enable metrics globally with env vars per component (e.g. `PANGOLIN_METRICS`, `GERBIL_METRICS`, `TRAEFIK_METRICS`, `NEWT_METRICS`).
2. OTLP export is supported via:
- `*_METRICS_EXPORTER=otlp`
- `*_METRICS_OTLP_ENDPOINT=<collector endpoint>`
3. Prometheus pull mode is also supported via:
- `*_METRICS_EXPORTER=prometheus`
- `*_METRICS_PROMETHEUS_ADDRESS=:<port>`

Pangolin docs also note Newt metrics are served on Newt admin HTTP (`http://localhost:9080/metrics`) when enabled.

## Nextcloud observability reality for your current version
1. Nextcloud OpenMetrics `/metrics` is documented as added in version `33`.
2. Your pinned version is `32.0.6`, so do not assume `/metrics` exists yet.
3. For Nextcloud 32, practical telemetry inputs are:
- Nextcloud logs/audit logs (`log_type=file|syslog|systemd`)
- `serverinfo` API (`/ocs/v2.php/apps/serverinfo/api/v1/info?format=json`)

Inference for this environment:
- OTEL for Pangolin can be first-class now.
- OTEL for Nextcloud should be logs + synthetic/API scraping until you move to NC33.

## Recommended architecture (stable path)

### Phase 1 (now): OTEL gateway on observatory + Pangolin OTLP export
1. Deploy one OpenTelemetry Collector as gateway on observatory.
2. Receive OTLP over gRPC/HTTP (`4317`/`4318`) from Pangolin components.
3. Export metrics to Prometheus-compatible sink (either Collector Prometheus exporter endpoint or OTLP-enabled backend path).
4. Export logs to Loki (or keep Promtail for file logs initially and use OTEL only for metrics/traces).

Why this is safest:
1. You already operate observability infra there.
2. It avoids large changes on Nextcloud VM while giving edge visibility first.

### Phase 2: Traefik traces for request-path debugging
1. Enable Traefik OTEL tracing to OTLP endpoint.
2. Keep sample rate conservative initially (e.g. 0.05 to 0.10).
3. Capture only a narrow header allowlist (avoid high-cardinality leakage).

### Phase 3: Nextcloud integration
For current `32.0.6`:
1. Keep log shipping as primary signal.
2. Add serverinfo poller for coarse metrics.

After upgrade to `33+`:
1. Enable `/metrics` with strict `openmetrics_allowed_clients`.
2. Scrape only from collector/prometheus IPs.
3. Keep `openmetrics_skipped_classes` ready for expensive exporters.

## Environment-specific implementation plan

### A) OTEL Collector placement and routing
1. Place Collector in observatory (same trust domain as Prometheus/Loki).
2. Restrict collector OTLP listeners to:
- private VLAN / Newt-connected addresses only
- no public exposure via Pangolin
3. Treat collector as internal-only service.

### B) Pangolin configuration changes (main-vps)
1. Enable metrics for components you run (`pangolin`, `gerbil`, `traefik`, plus `newt` where applicable).
2. Start with OTLP metrics export to collector:
- `*_METRICS=true`
- `*_METRICS_EXPORTER=otlp`
- `*_METRICS_OTLP_ENDPOINT=http://<collector-internal>:4318/v1/metrics`
3. If OTLP introduces friction, fall back to Prometheus exporter mode temporarily and scrape from observatory.

### C) Nextcloud 32 telemetry pattern (now)
1. Keep/standardize structured logs from Nextcloud and Nginx on `nextcloud-vm`.
2. Ship logs to central backend (existing Promtail/Loki or OTEL filelog receiver path).
3. Add periodic serverinfo query (authenticated token/app-password) and transform to metrics.

### D) Nextcloud 33 telemetry pattern (later)
1. On upgrade, enable `/metrics` only for internal collectors.
2. Add restrictive `openmetrics_allowed_clients`.
3. Validate response time and disable expensive classes if needed.

## Minimal rollout checklist
1. Deploy OTEL Collector gateway in observatory with health endpoint.
2. Enable Pangolin OTLP metrics for one component first (`traefik` or `pangolin`), verify ingest.
3. Add dashboards + alerts for 4 signals:
- edge 5xx rate
- auth failures/429 spikes
- websocket upgrade failures
- tunnel health / reconnect churn
4. Extend to remaining Pangolin components.
5. Add Nextcloud serverinfo+logs collection.
6. Revisit Nextcloud OpenMetrics when moving from `32.0.6` to `33+`.

## Pitfalls to avoid
1. Do not expose collector OTLP ports publicly.
2. Do not enable 100% tracing on day one (cost/noise).
3. Do not expose Nextcloud `/metrics` broadly when you reach NC33.
4. Do not mix "production alerts" and "new telemetry experiments" without separate labels/routes.

## Sources
1. Pangolin metrics (OTEL + Prometheus envs, per-component toggles): https://docs.pangolin.net/additional-resources/metrics
2. Pangolin config file reference (stack config context): https://docs.pangolin.net/self-host/advanced/config-file
3. Pangolin docker-compose layout (Traefik config paths): https://docs.pangolin.net/self-host/manual/docker-compose
4. Traefik tracing (OTEL/OTLP): https://doc.traefik.io/traefik/reference/install-configuration/observability/tracing/
5. Traefik OTEL provider details: https://doc.traefik.io/traefik/v3.4/observability/tracing/opentelemetry/
6. Traefik metrics OTLP exporter: https://doc.traefik.io/traefik/reference/install-configuration/observability/metrics/
7. Traefik OTLP access logs (experimental): https://doc.traefik.io/traefik/master/reference/install-configuration/observability/logs-and-accesslogs/
8. OpenTelemetry Collector configuration model: https://opentelemetry.io/docs/collector/configuration/
9. OpenTelemetry Collector install with Docker: https://opentelemetry.io/docs/collector/install/docker/
10. Nextcloud monitoring (OpenMetrics added in 33): https://docs.nextcloud.com/server/latest/admin_manual/configuration_monitoring/index.html
11. Nextcloud OpenMetrics config params (`openmetrics_allowed_clients`, `openmetrics_skipped_classes`): https://docs.nextcloud.com/server/latest/admin_manual/configuration_server/config_sample_php_parameters.html
12. Nextcloud 33 release notes (OpenMetrics endpoint intro): https://docs.nextcloud.com/server/latest/admin_manual/release_notes/upgrade_to_33.html
13. Nextcloud logging configuration: https://docs.nextcloud.com/server/24/admin_manual/configuration_server/logging_configuration.html
14. Nextcloud serverinfo API app: https://github.com/nextcloud/serverinfo

## Confidence and caveats
1. High confidence: Pangolin/Traefik/OTEL capabilities and config knobs (official docs).
2. High confidence: Nextcloud OpenMetrics availability starts in NC33.
3. Medium confidence (inference): exact best transport mode (OTLP push vs Prometheus pull) for your current VPS-to-observatory network should be validated with a small pilot first.
