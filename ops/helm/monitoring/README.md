# Monitoring Helm Config

This directory is the canonical home for the initial `ops-brain` monitoring stack.

Planned contents:
1. pinned chart/version references
2. committed values files for Prometheus, Grafana, Loki, and Alertmanager
3. first-pass storage/retention settings

Current policy:
1. use k3s local-path storage first
2. accept rebuild/data loss for now
3. target 7-day local log retention
4. keep secrets out of git
