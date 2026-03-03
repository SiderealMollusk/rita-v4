# External Dependencies

Validated: 2026-02-27

## Pangolin-Server Installer Source
- Dependency: `https://static.pangolin.net/get-installer.sh`
- Config var: `pangolin_installer_url` in `ops/ansible/group_vars/vps.yml`

Validation command (via runbook):
- `scripts/2-ops/vps/04-install-pangolin-server.sh`

Failure impact:
- `pangolin-server` install cannot proceed (`04-install-pangolin-server.sh`).

## Docker Compose v2 Plugin
- Dependency: `https://github.com/docker/compose/releases`
- Config var: `docker_compose_version` in `ops/ansible/group_vars/vps.yml`
- Reason: Pangolin-generated compose files use modern Compose features that fail under legacy `docker-compose` v1.

## Fossorial Helm Repo Status
- Dependency: `https://charts.fossorial.io`
- Observed on 2026-02-27:
  - `fossorial/newt` is published.
  - `fossorial/pangolin` is not listed.
- Impact:
  - Helm deploy path for `pangolin-server` is blocked upstream as of this date.
  - `newt` has an obvious first-party Helm/Kubernetes path.
  - `pangolin-server` does not have an obvious first-party Kubernetes/self-host chart path in the current validated evidence set for this repo.
