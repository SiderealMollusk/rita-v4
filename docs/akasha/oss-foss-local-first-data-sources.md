# Akasha: OSS/FOSS Local-First Data Sources
Date: 2026-03-06
Status: Draft

## Question
Is it viable to stand up many collection tools, feed Loki/Prometheus, and build a personalized hacky web app on top?

## Short answer
Yes, viable.

But architecture should be:
1. many collectors/sources
2. normalization/route layer (prefer OTel Collector)
3. split sinks:
   - metrics -> Prometheus
   - logs/events -> Loki
4. Akasha app reads from both + repo SoT

Not literally "Loki -> Prometheus" as a pipeline.
They are sibling stores for different data shapes.

## Recommended baseline architecture

### 1) Source producers (local-first)
1. command/effect checks (your own scripts + Effect runner)
2. node/system metrics (`node_exporter`, cAdvisor, smartctl textfile collectors)
3. service probes (`blackbox_exporter`, uptime checks)
4. container/runtime events (Docker logs, systemd journal)
5. network/DNS probes (dig, ping, traceroute, curl)
6. SoT validators (repo schema checks, required file presence, inventory drift)

### 2) Collection + normalization
1. `OpenTelemetry Collector` as central fan-in/fan-out
2. Prometheus scraping for exporter metrics
3. log shipper (`promtail` or OTel filelog receiver) for logs/command output
4. optional queueing/retry when sources are bursty

### 3) Storage
1. `Prometheus` for time-series metrics
2. `Loki` for logs and command/evidence streams
3. optional local JSONL evidence cache for Akasha explainability

### 4) Akasha app data access
1. query Prometheus for numeric state and trend checks
2. query Loki for command output and "why" evidence lines
3. read repo SoT directly for intent/expected state
4. run reducer in app/backend to compute composite status color

## Why this is a good fit for your model
1. your composite "green" requires multiple evidence types, not only metrics
2. terminal feed naturally maps to logs/events more than dashboards
3. SoT drift checks are easiest as explicit command/effect jobs
4. local-first is preserved because all core components run in-lab

## Guardrails (important)
1. cap cardinality early (labels/tags explode costs/latency)
2. enforce check cadence classes:
   - fast (5-15s)
   - normal (1-5m)
   - slow/manual (10m+)
3. separate raw telemetry from reduced status facts
4. keep a tiny canonical node schema and version it
5. store reducer decisions + evidence references for auditability

## "Nail-gun" implementation slices

### Slice A (weekend 1)
1. 3 node types: `vm`, `service`, `dns`
2. 6 checks total
3. write check output to Loki
4. write simple metrics to Prometheus
5. display topology + per-node tooltip evidence in Akasha

### Slice B (weekend 2)
1. add SoT validators (documented/reachable/expected route)
2. add status transition history (last green/yellow/red timestamps)
3. add one dependency edge rule (pangolin depends on site reachability)

## OSS/FOSS building blocks shortlist
1. OpenTelemetry Collector
2. Prometheus + Alertmanager
3. Loki (+ Grafana optional for debugging)
4. Promtail or OTel filelog receiver
5. node_exporter / blackbox_exporter / cAdvisor
6. NetBox (optional infra SoT augmentation)
7. Uptime Kuma (optional fast probe bootstrap)

## Opinionated recommendation
Use one custom Akasha reducer service as the "brain" and keep all collectors dumb.

If you let every collector encode business meaning, you'll get drift and spend time reconciling semantics.
