# 0130 - Pangolin CLI Route Management
Status: 🟡 ACTIVE
Date: 2026-02-27

## Goal
Learn and use the actual Pangolin CLI correctly for route and blueprint management against the working `pangolin-server`.

## Context
This plan starts after `pangolin-server` is already working on the public edge VPS.

The target use case is not "install Pangolin with the CLI."  
The target use case is "manage routes and blueprint-like behavior intentionally once the server already exists."

## Core Questions
1. what the Pangolin CLI can actually manage
2. how blueprints are represented
3. whether route definitions can be expressed reproducibly
4. how to map monitoring services into Pangolin safely
5. which routes should remain internal-only

## Scope
This phase is about:
1. route management
2. reproducibility
3. documenting operator workflow

This phase is not about:
1. installing the VPS server
2. replacing the server installer path
3. exposing everything externally by default

## Desired End State
1. monitoring services have a clear exposure policy
2. Pangolin-managed routes are documented in repo
3. CLI operations are repeatable and understood
4. route creation/update/removal can be performed from documented commands or wrappers

## Route Exposure Policy
### Candidate Public Routes
These may eventually be Pangolin-routed if justified:
1. Grafana
2. Uptime Kuma
3. selected read-only or operator-only dashboards

### Candidate Internal-Only Services
These should default to internal-only until there is a reason otherwise:
1. Prometheus
2. Loki
3. Alertmanager
4. internal admin endpoints

### Principle
Expose the smallest useful surface area through Pangolin.

## Blueprint Questions
The CLI investigation should answer:
1. are blueprints repo-friendly artifacts?
2. can they be diffed/reviewed?
3. can they express access policies as well as routes?
4. should they become source-controlled non-secret objects?

## Deliverables
1. Pangolin CLI command reference for this lab
2. documented login/auth workflow
3. route-management runbook
4. updated `ops/network/routes.yml` with Pangolin-managed routes
5. decision on blueprint source-control strategy

## Research Tasks
1. confirm CLI auth flow against the working server
2. enumerate commands relevant to:
- route creation
- route update
- route deletion
- blueprint export/import
3. test one safe service first
- recommended first target: Grafana or Kuma
4. document failure/rollback behavior

## Suggested First Exercise
1. keep Prometheus/Loki internal-only
2. expose one operator-facing dashboard through Pangolin
3. verify route works
4. remove the route again
5. document the exact command sequence

## Pass Criteria
1. at least one monitoring route can be created intentionally through Pangolin tooling
2. that route can be removed cleanly
3. the route is documented in repo
4. the operator workflow is no longer ambiguous

## Guardrails
1. Do not expose every monitoring component just because Pangolin can route it.
2. Keep secrets/tokens out of repo.
3. Prefer documented CLI workflows over ad-hoc UI-only changes when reproducibility matters.

## Immediate Next Actions
1. log in with the Pangolin CLI against the working server
2. inventory available route/blueprint commands
3. choose first candidate service for exposure
4. update `ops/network/routes.yml` after the first successful managed route
