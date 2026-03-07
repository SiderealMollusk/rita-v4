# Akasha Testing Plan (EffectTS-First)
Date: 2026-03-06
Status: Proposed

## 1) Goals
1. Prove reducer correctness for status lights and `why` evidence.
2. Prevent regressions in check execution and stream behavior.
3. Keep tests deterministic despite async/runtime concurrency.
4. Enforce security constraints around command execution and secret handling.

## 2) Test layers
1. Unit tests (pure logic, very fast, highest count).
2. Integration tests (component boundaries: API, DB, WS, runner).
3. End-to-end smoke tests (Docker Compose happy-path and failure-path).
4. Contract tests (schema/API compatibility over time).
5. Runtime-resilience tests (EffectTS interruption, retry, timeout behavior).

## 3) EffectTS-focused test approach
1. Inject all side effects through Effect services/layers.
2. Use test layers for fake clock, fake command runner, fake network client.
3. Use controlled schedulers to test retry/backoff deterministically.
4. Assert typed domain errors, not string matching.
5. Test cancellation/interruption for long-running checks and WS subscribers.

## 4) Unit test matrix
Reducer package (`packages/reducer/src`):
1. Green when all required checks + SoT pass + deps pass.
2. Yellow when partial degradation with core path available.
3. Red when critical check/dependency fails.
4. Unknown when evidence missing/stale TTL exceeded.
5. Deterministic `why[]` ordering and stable reason codes.

Checks package (`packages/checks/src`):
1. `cmd` normalization: exit code, stdout/stderr truncation, timeout.
2. `http` normalization: status, latency, network errors.
3. `dns` normalization: answer/no-answer/timeout/NXDOMAIN.
4. Redaction: secret tokens/known patterns never leak to evidence stream.

Schema and SoT (`packages/schema/src`, `packages/sot/src`):
1. Node/check schema validation success and failure cases.
2. Schema version checks and migration guardrails.
3. SoT drift detection for missing required docs/fields.

## 5) Integration test matrix
API (`apps/api/src`):
1. `GET /nodes` and `GET /nodes/:id/state` reflect reducer output.
2. `GET /nodes/:id/evidence` returns bounded, correctly ordered evidence.
3. WS stream emits transition and terminal events in expected order.

Persistence/telemetry:
1. SQLite snapshot updates are atomic for node state writes.
2. Loki write adapter handles transient failures and retries.
3. Prometheus metric exporter emits bounded label sets.

Failure behavior:
1. Command runner timeout produces typed timeout failure.
2. Retry policy respects max attempts and backoff schedule.
3. Cancellation during check run leaves no zombie process.

## 6) E2E smoke scenarios (Compose)
1. Baseline healthy: sample nodes all green.
2. Dependency degraded: upstream node red causes dependent yellow/red.
3. Stale evidence: stopped runner transitions node to unknown after TTL.
4. Command failure: failing check appears in terminal and tooltip evidence.
5. Restart recovery: API restart rebuilds snapshot and resumes stream.

## 7) CI gating policy
Required on every PR:
1. Unit tests for touched packages.
2. Integration tests for touched runtime boundaries.
3. Lint/type checks.

Required before merge to main:
1. Full unit + integration suite.
2. Contract tests for API/schema changes.
3. Minimal Compose smoke suite.

Nightly:
1. Soak tests (30-60 minutes).
2. Retry/cancellation stress tests.

## 8) Coverage and quality targets
1. Statements coverage = 100%.
2. Branch coverage = 100%.
3. Functions coverage = 100%.
4. Lines coverage = 100%.
5. Zero flaky tests allowed in required suites.

## 8.1) Coverage policy override for Akasha v0
1. Required metric target is 100% statements/branches/functions/lines for active packages.
2. Allowed exclusions must be explicit in test config and listed with reason.
3. Current exclusions:
   - `apps/api/src/index.js`: process bootstrap only (bind host/port and start server). Behavioral logic is covered through `buildServer` route tests.
   - `apps/web/src/main.jsx`: DOM bootstrap only (root lookup + React mount). App behavior is covered through component tests.

## 9) Test data and fixtures
1. Golden fixtures for node specs and evidence events.
2. Deterministic fixture clocks/timestamps.
3. Synthetic command outputs for success/failure/redaction cases.
4. Small topology fixtures (3-node and 10-node variants).

## 10) Immediate implementation order
1. Add reducer truth-table tests first.
2. Add check plugin normalization tests second.
3. Add API integration tests with fake layers third.
4. Add WS ordering and staleness tests fourth.
5. Add Compose smoke tests last.
