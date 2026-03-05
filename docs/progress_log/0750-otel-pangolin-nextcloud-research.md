# 0750 - OTEL Research for Pangolin + Nextcloud (Environment Specific)

Date: 2026-03-05
Status: Completed

## Summary
Completed targeted OTEL research for Pangolin and Nextcloud, adapted to the current topology (`public-edge` Pangolin, observatory Prometheus/Loki stack, and official VM-first Nextcloud on `cloud.virgil.info`).

Output:
1. [0014-otel-for-pangolin-and-nextcloud-in-this-environment.md](/Users/virgil/Dev/rita-v4/docs/research/0014-otel-for-pangolin-and-nextcloud-in-this-environment.md)

## Key outcomes
1. Confirmed Pangolin supports OTEL metrics export via OTLP and Prometheus modes.
2. Identified phased rollout path that starts with Pangolin edge telemetry and minimal blast radius.
3. Clarified Nextcloud constraint: current pinned version `32.0.6` (no first-class `/metrics` endpoint from NC docs until v33).
4. Defined current Nextcloud telemetry strategy as logs + serverinfo, then OpenMetrics post-upgrade.
5. Added environment-specific rollout checklist and anti-patterns.
