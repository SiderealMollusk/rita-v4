# 0001 - Pangolin Deploy Model (Pangolin-Server vs CLI vs Newt)

Status: Accepted  
Validated: 2026-02-27

## Problem
The term "pangolin" appears in multiple contexts:
- self-hosted pangolin-server
- end-user CLI/client commands
- Newt site connector

This has caused repeated confusion in runbooks.

## Canonical Terms
1. **Pangolin-Server**: the public self-hosted Pangolin server/control plane endpoint (for example `pangolin.virgil.info`).
2. **CLI**: local client tool used for client workflows, not the source of truth for pangolin-server install path in this repo.
3. **Newt**: site connector/agent that can be installed separately (including via Kubernetes Helm flow).

## Deployment Truth for This Repo
1. VPS runbooks under `scripts/2-ops/vps` are for **pangolin-server infrastructure and operations**.
2. Pangolin-server deployment method must be explicit in runbooks and must not rely on ambiguous "pangolin up" assumptions.
3. `newt` may use a Kubernetes Helm flow; `pangolin-server` currently does not have an obvious first-party Kubernetes deployment path validated for this repo.

## Chart/Docs Facts to Anchor
1. Fossorial chart repository exists: `https://charts.fossorial.io`.
2. As of 2026-02-27, only `fossorial/newt` is listed; `fossorial/pangolin` is not discoverable via `helm search repo`.
3. Pangolin docs "Install Kubernetes" page is for **Newt/site** flows, not pangolin-server.
4. No obvious first-party pangolin-server Kubernetes/self-host chart path is validated in this repo's current evidence set.
5. Active pangolin-server path in this repo is installer/runtime flow, not Helm.
6. Active Kubernetes Helm path is for `newt`, not pangolin-server.

## Hard Guardrails
1. Do not merge runbook changes that use `pangolin up` as the only pangolin-server deployment step without explicit pangolin-server documentation backing.
2. Any Pangolin deploy script must state:
- target component (`pangolin-server` or `newt`)
- deploy method (`helm`, `compose`, or installer)
- verify command(s) and rollback command(s)
3. If upstream docs are ambiguous, record decision and link sources here before script changes.

## Linked Source Locations in Repo
- Routes/domain vars: `ops/network/routes.yml`
- Ops vars: `ops/ansible/group_vars/vps.yml`
- VPS runbooks: `scripts/2-ops/vps/`
- Ansible playbooks: `ops/ansible/playbooks/`

## Upstream References
- `https://github.com/fosrl/helm-charts`
- `https://charts.fossorial.io`
- `https://docs.pangolin.net/manage/sites/install-kubernetes`
- `https://docs.pangolin.net/self-host/quick-install`
