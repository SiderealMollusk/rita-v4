# 0090 - Pangolin-Server Working and Node Placement Locked
Date: 2026-02-27  
Status: ✅ COMPLETE

## Summary
`pangolin-server` is now running successfully on the VPS using the installer + Docker Compose v2 path.

Validated outcomes:
- Pangolin containers started successfully on the VPS
- setup token was generated
- initial setup completed
- organization `virgil-lab` was created
- HTTPS is working
- Mac client connectivity was established

This closes the main VPS edge goal: get a real Pangolin deployment working on the public VPS.

## Key Technical Findings
1. Helm path is not currently usable for `pangolin-server`
- `charts.fossorial.io` exposes `fossorial/newt`
- `fossorial/pangolin` was not discoverable via `helm search repo`
- result: VPS deployment strategy was correctly changed away from Kubernetes/Helm

2. Pangolin installer currently depends on modern Docker Compose
- generated `docker-compose.yml` uses modern Compose features
- legacy `docker-compose` v1 failed with:
  - `name does not match any of the regexes: '^x-'`
- fix: install Docker Compose v2 plugin

3. Host-key churn after VPS resets is routine
- VPS scripts were updated to refresh SSH host keys from inventory automatically
- this matches expected reset-heavy workflow

## Repo Changes Completed
1. VPS runbooks were retooled to:
- `01-ansible-ping.sh`
- `02-bootstrap-host.sh`
- `03-install-runtime.sh`
- `04-install-pangolin-server.sh`
- `05-capture-setup-token.sh`
- `06-verify-pangolin-server.sh`
- `07-rollback-pangolin-server.sh`

2. Runtime dependencies were codified:
- Pangolin installer source
- Docker Compose v2 plugin source/version

3. Human runbooks were added/updated:
- `docs/reset-vps.md`
- `docs/dependencies.md`
- `docs/pangolin/0001-deploy-model.md`

## Architecture Decision Locked
After additional planning and independent re-validation, service placement is now:

1. `ops-brain` = 16 GB laptop
- Prometheus
- Grafana
- Loki
- Alertmanager
- Uptime Kuma
- optional lightweight internal control plane

2. `platform-node` = 12 GB NUC
- Gitea
- CI runners
- Argo CD
- Zot
- platform support services

3. `workload-node` = 64 GB server
- workloads only

4. `main-vps` = public edge runtime
- `pangolin-server`
- Traefik/Gerbil as installed by Pangolin

## Operational Notes
1. The installer may still require a human-in-the-loop boundary.
- That is acceptable for now.
- Automation around it is now explicit and documented.

2. The known-good operator sequence is:
- seed SSH/admin access
- bootstrap host
- install runtime
- stage installer
- run installer on VPS
- capture/store setup token
- verify service

## Next Steps
1. Extract and review the known-good VPS Pangolin config (`docker-compose.yml`, `config/`)
2. Tighten `06-verify-pangolin-server.sh` based on actual healthy endpoint behavior
3. Stand up monitoring on the future `ops-brain`
4. Begin documenting/implementing `platform-node` services on the NUC
