# System Map

This is the single navigation doc for operational truth.
It intentionally links to source files instead of duplicating values.

Validated: 2026-02-27

## Pangolin Semantics (Pangolin-Server vs CLI vs Newt)
- Canonical reference: `docs/pangolin/0001-deploy-model.md`
- Folder index: `docs/pangolin/README.md`

## External Dependencies
- Source of truth: `docs/dependencies.md`

## Hosts and IPs
- Source of truth: `ops/ansible/inventory/`
- Current file: `ops/ansible/inventory/vps.ini`

## Automation Variables (domains, namespaces, deploy vars)
- Source of truth: `ops/ansible/group_vars/`
- Current file: `ops/ansible/group_vars/vps.yml`

## Hittable Routes (FQDN -> backend/ports/exposure)
- Source of truth: `ops/network/routes.yml`

## Cluster Boundaries
- Local simulation cluster:
  - Scripts: `scripts/1-session/` and `scripts/2-ops/local/`
  - Typical context: local k3d (`rita-local`)
- VPS edge runtime:
  - Scripts: `scripts/2-ops/vps/`
  - Automation: `ops/ansible/playbooks/` (host bootstrap and related tasks)

## Node Inventory (human-readable)
- Entry point: `docs/lab-nodes.md`
- Node docs: `docs/nodes/`
- Service placement: `docs/service-placement.md`

## Secrets (references only; never values)
- Runtime secret source: 1Password
- Pangolin setup/admin tokens are captured post-install and stored in 1Password.
- Seed/SSH bootstrap script: `scripts/0-local-setup/03-vps/01-seed-ssh-admin-from-op.sh`

## Deployment Runbooks
- VPS runbook scripts: `scripts/2-ops/vps/`
- Ansible playbooks: `ops/ansible/playbooks/`
- Human reset playbook: `docs/reset-vps.md`
- Current sequencing plan: `docs/plans/0110-ops-brain-platform-workload-sequencing.md`
- Detailed ops-brain plan: `docs/plans/0120-ops-brain-k3s-monitoring-stack.md`
- Detailed Pangolin CLI plan: `docs/plans/0130-pangolin-cli-route-management.md`
- Additional ops domains:
  - `scripts/2-ops/nuc/`
  - `scripts/2-ops/worker/`
  - `scripts/2-ops/gpu/`

## Change Rule
- Update canonical source files first.
- Update this map only when source file locations or ownership boundaries change.
