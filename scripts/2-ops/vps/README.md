# VPS Ops Runbook Scripts

Run these in order. All scripts are no-arg and opinionated.

Quick full run:
- `00-run-all.sh`
- Executes steps `01` through `06` in order and stops on first failure.

## Host and Runtime
1. `01-ansible-ping.sh`
- Confirms inventory parsing and SSH+sudo connectivity.

2. `02-bootstrap-host.sh`
- Baseline host setup (packages, firewall, fail2ban).

3. `03-install-runtime.sh`
- Installs Docker runtime, pins Docker Compose v2 plugin, and creates Pangolin directories.

## Pangolin-Server Deploy
4. `04-install-pangolin-server.sh`
- Stages official Pangolin installer on VPS and prints the interactive install command.

5. `05-capture-setup-token.sh`
- Scans installer/container logs for setup-token hints so they can be stored in 1Password.

6. `06-verify-pangolin-server.sh`
- Verifies Docker state, Pangolin-related containers, and endpoint reachability.

7. `07-rollback-pangolin-server.sh`
- Manual rollback step (not part of `00-run-all.sh`).

Canonical terminology and deployment guardrails:
- `docs/pangolin/0001-deploy-model.md`

## 1Password
- Store setup/admin tokens captured in step `05` into 1Password immediately.
- Keep secrets out of repo files.

## Config source split
- Hosts/IPs: `ops/ansible/inventory/*.ini`
- Automation vars: `ops/ansible/group_vars/*.yml`
- Hittable route catalog: `ops/network/routes.yml`
- Secrets: 1Password only
