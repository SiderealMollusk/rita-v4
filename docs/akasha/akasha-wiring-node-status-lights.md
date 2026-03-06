# Akasha Wiring: Fast Node Onboarding + Composite Status Lights
Date: 2026-03-06
Status: Draft

## Goal
Make it easy and efficient to add random nodes and status lights without rewriting core logic each time.

## Core design rule
Use plugin-style node definitions and keep one centralized reducer as the "brain".

This prevents logic drift and keeps node onboarding mostly data-entry, not code changes.

## System wiring

### 1) Node Registry (Git SoT)
One file per node (`yaml` or `json`) containing:
1. identity
2. intent
3. checks
4. dependencies
5. light rules

Suggested fields:
1. `id`
2. `type`
3. `owner`
4. `intent`
5. `checks[]`
6. `dependencies[]`
7. `light_rules`

### 2) Check Runner (Effect.js service)
Runner executes checks by `check.type` and emits normalized outcomes only.

Recommended check types:
1. `cmd`
2. `http`
3. `promql`
4. `logql`
5. `dns`

Output contract (normalized):
1. `node_id`
2. `check_id`
3. `ok` (boolean)
4. `observed_value`
5. `summary`
6. `evidence_ref`
7. `ts`

### 3) Evidence bus and storage
1. write all check evidence/events to Loki (JSON lines)
2. write numeric health/time-series to Prometheus
3. maintain a local SQLite snapshot for low-latency UI reads

Important: treat Loki and Prometheus as sibling sinks, not chained sinks.

### 4) Reducer Engine (single source of status truth)
Reducer pulls:
1. latest normalized check outputs
2. node intent and light rules
3. dependency state
4. SoT drift signals

Reducer emits `NodeState`:
1. `color` (`green`/`yellow`/`red`/`unknown`)
2. `why[]` (human-readable reason codes)
3. `failed_checks[]`
4. `last_transition`
5. `evidence_links[]`

### 5) Akasha API
Recommended endpoints:
1. `GET /nodes`
2. `GET /nodes/:id/state`
3. `GET /nodes/:id/evidence`
4. `WS /stream` (live transitions + terminal feed)

### 6) UI (React + React Flow)
1. graph layout from Node Registry + dependencies
2. status lights from reducer output only
3. tooltip from `why[]` and evidence links
4. terminal feed from websocket stream

## Why this scales for "random nodes"
1. New node usually means new registry file, not new backend logic.
2. Existing check types are reused across node domains.
3. Reducer semantics stay consistent.
4. UI remains generic and data-driven.

## Guardrails
1. Keep collectors/checks dumb; keep interpretation in reducer.
2. Cap label cardinality in metrics/log fields.
3. Define cadence classes (`fast`, `normal`, `slow`) and enforce globally.
4. Version the node schema.
5. Persist reducer decision artifacts for explainability.

## Suggested file layout
```text
akasha/
  schema/
    node.schema.json
  registry/
    nodes/
      nextcloud-core.yaml
      pangolin-edge.yaml
      dns-cloud-virgil.yaml
  checks/
    plugins/
      cmd.ts
      http.ts
      promql.ts
      logql.ts
      dns.ts
  reducer/
    reducer.ts
    rules.ts
  api/
    server.ts
  ui/
    ...
```

## Minimal node spec example
```yaml
id: nextcloud-core
type: service
owner: workload
intent: "reachable + docs-pass + expected-route"
checks:
  - id: ping
    type: cmd
    run: "ping -c1 cloud.virgil.info"
    cadence: 60s
  - id: status
    type: http
    url: "https://cloud.virgil.info/status.php"
    expect_status: 200
    cadence: 30s
  - id: route_sot
    type: cmd
    run: "./scripts/check-route.sh cloud.virgil.info"
    cadence: 5m
dependencies:
  - pangolin-edge
light_rules:
  green:
    - ping.ok
    - status.ok
    - route_sot.ok
  yellow:
    - ping.ok && status.ok && !route_sot.ok
  red:
    - !ping.ok || !status.ok
```

## Recommended first build slice
1. Implement only `service`, `vm`, and `dns` node types.
2. Support only `cmd`, `http`, and `dns` checks initially.
3. Ship reducer + tooltip evidence first; postpone advanced graph behavior.
4. Add Prometheus/LogQL checks after first end-to-end slice works.

## Practical verdict
This wiring is viable and efficient for your use case.

It stays hackable while preserving a stable contract for adding new nodes and status lights.
