# Akasha Setup Plan (Docker + React/Server + Testing)
Date: 2026-03-06
Status: Proposed

## 1) Objectives for v0
1. Run Akasha locally with one command.
2. Show topology nodes with composite status lights.
3. Stream terminal/check output to the UI.
4. Expose deterministic reducer logic with explainable `why` reasons.
5. Validate with automated tests before expanding node/check types.

## 1.1) Engineering principle
Use EffectTS as much as possible for core logic and integration boundaries.
1. Check orchestration and scheduling use Effect runtimes/services.
2. Reducer and state transitions are modeled as pure Effect-friendly modules.
3. API handlers delegate to Effect programs (minimal imperative glue).
4. Background workers, retry logic, and timeout policies are defined in Effect.
5. Shared errors are modeled as typed domains, not ad-hoc exceptions.

## 2) Recommended stack
Frontend:
1. React + React Flow
2. Flow type checking (via Babel + flow-bin)
3. Vite dev server for fast local iteration
4. EffectTS client layer for stream subscriptions and API effects

Backend:
1. Node.js service (Fastify)
2. EffectTS for check orchestration (cmd/http/dns)
3. WebSocket stream for live terminal + state transitions

Data/observability:
1. SQLite for low-latency current snapshot
2. Loki for evidence/event logs
3. Prometheus for numeric metrics
4. OpenTelemetry Collector as fan-in/fan-out

Container runtime:
1. Docker Compose as dev control plane

## 3) Repo layout to create
```text
docs/akasha/
akasha/
  apps/
    web/                  # React Flow UI (Flow)
    api/                  # Fastify + Effect runner + reducer
  packages/
    schema/               # node/check/state contracts
    reducer/              # pure reducer logic + rule tests
    checks/               # check plugins (cmd/http/dns)
    sot/                  # SoT loading/validation
  infra/
    compose.yaml
    prometheus/
    loki/
    otel/
  registry/
    nodes/
  scripts/
```

## 4) Docker project plan
Phase A: Compose baseline
1. Services: `akasha-api`, `akasha-web`, `prometheus`, `loki`, `otel-collector`, `sqlite-init`.
2. Optional debug profile: `grafana` (disabled by default).
3. Bind mount repo for hot reload in `web` and `api`.
4. Healthchecks for every service.

Phase B: Networking and persistence
1. Dedicated network: `akasha_net`.
2. Volumes: `prom_data`, `loki_data`, `akasha_sqlite`.
3. Internal-only ports except web/API UI ports.
4. Compose profiles:
   - `core`: web + api + sqlite
   - `obs`: prometheus + loki + otel
   - `debug`: grafana

Phase C: Operational scripts
1. `scripts/akasha-up` -> starts `core` + `obs`.
2. `scripts/akasha-down` -> stop stack.
3. `scripts/akasha-reset` -> clear local volumes (explicitly destructive).
4. `scripts/akasha-smoke` -> curl/health/stream smoke checks.

## 5) Off-the-shelf app bootstrap plan
Web app (`apps/web`):
1. Create with Vite React template.
2. Add Flow config + Babel Flow strip.
3. Add React Flow, state store, and WS client.
4. Put network and stream interactions behind EffectTS services.
5. Build 3-pane layout:
   - topology graph
   - terminal feed
   - detail tooltip/drawer

API app (`apps/api`):
1. Fastify bootstrap.
2. EffectTS runtime service for scheduled checks.
3. Plugin system for `cmd`, `http`, `dns` checks.
4. Reducer service produces `NodeState`.
5. Endpoints:
   - `GET /healthz`
   - `GET /nodes`
   - `GET /nodes/:id/state`
   - `GET /nodes/:id/evidence`
   - `WS /stream`

Shared contracts (`packages/schema`):
1. `NodeSpec`, `CheckSpec`, `NodeState`, `EvidenceEvent`.
2. Schema versioning field required.
3. Runtime validation at load time.

## 6) First reducer/state contract
`green` only when all pass:
1. Required checks succeeded.
2. Node is reachable.
3. Node has documentation/SoT pass.
4. Dependencies meet required state.

`unknown`:
1. Missing evidence.
2. Evidence stale beyond TTL.

`yellow` and `red` (initial proposal):
1. `yellow`: partial degradation, core path still available.
2. `red`: core path down or critical check failure.

Every state includes:
1. `color`
2. `why[]`
3. `failed_checks[]`
4. `last_transition`
5. `evidence_refs[]`

## 7) Testing strategy
Test pyramid:
1. Unit tests (high volume)
2. Integration tests (medium)
3. End-to-end smoke (small, deterministic)

Unit tests:
1. Reducer truth tables (most important).
2. Check plugin parsing/normalization.
3. Schema validation and SoT loading.

Integration tests:
1. API + SQLite + mock check runners.
2. WS stream event ordering.
3. TTL/staleness transition behavior.
4. Failure/retry/timeout handling for command checks.

E2E tests:
1. Compose-based smoke with 2-3 sample nodes.
2. Confirm UI color changes from injected evidence.
3. Confirm tooltip `why` lines match reducer reasons.

Contract tests:
1. Snapshot tests on API payload contracts.
2. Backward compatibility tests for schema versions.

Non-functional tests:
1. Soak test check scheduler for 30-60 minutes.
2. Basic perf target: UI update latency < 1s for state changes.
3. Security tests: command allowlist, timeout, output truncation.
4. EffectTS runtime tests for interruption/cancellation/retry schedules.

## 8) Security and safety constraints (v0)
1. Command checks execute from an allowlisted command registry, not arbitrary user input.
2. Per-check timeout and max output bytes.
3. Redaction rules for secrets in terminal stream/evidence logs.
4. Run containers as non-root where possible.
5. Strict separation between raw logs and reduced state facts.

## 9) Delivery milestones
Milestone 0: Scaffolding (1-2 days)
1. Create folder structure and bootstrap web/api.
2. Stand up Compose core stack.
3. Implement `/healthz` and placeholder UI.

Milestone 1: First vertical slice (2-4 days)
1. Implement `cmd` + `http` + `dns` checks.
2. Add reducer and NodeState API.
3. Render node lights and tooltip evidence.
4. Add unit + integration tests for reducer/check runner.

Milestone 2: Observability hardening (2-3 days)
1. Wire Loki + Prometheus + OTel.
2. Stream terminal feed via WS.
3. Add staleness/TTL logic and transition history.

Milestone 3: Home-lab onboarding (ongoing)
1. Add node registry files from SoT.
2. Encode dependency edges.
3. Tune cadence classes (`fast`, `normal`, `slow`).

## 10) Definition of done for v0
1. `docker compose --profile core --profile obs up` brings up a usable stack.
2. At least 5 real nodes onboarded (mix of service/vm/dns).
3. Status lights are reducer-driven and explainable via tooltip evidence.
4. Terminal feed shows live check execution and results.
5. CI runs unit + integration tests; smoke test passes locally.
