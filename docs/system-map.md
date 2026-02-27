# System Map

This is the single navigation doc for operational truth.
It intentionally links to source files instead of duplicating values.

Validated: 2026-02-27

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
- VPS edge cluster:
  - Scripts: `scripts/2-ops/vps/`
  - Automation: `ops/ansible/playbooks/`

## Kubernetes Resource Definitions
- Repo manifests: `manifests/`
- Ansible-rendered templates: `ops/ansible/templates/`

## Node Inventory (human-readable)
- Entry point: `docs/lab-nodes.md`
- Node docs: `docs/nodes/`

## Secrets (references only; never values)
- Runtime secret source: 1Password
- Service account scope: vault set by `op_vault_id` in `ops/ansible/group_vars/vps.yml`
- Seed/SSH bootstrap script: `scripts/0-local-setup/03-vps/01-seed-ssh-admin-from-op.sh`

## Deployment Runbooks
- VPS runbook scripts: `scripts/2-ops/vps/`
- Ansible playbooks: `ops/ansible/playbooks/`
- Additional ops domains:
  - `scripts/2-ops/nuc/`
  - `scripts/2-ops/worker/`
  - `scripts/2-ops/gpu/`

## Change Rule
- Update canonical source files first.
- Update this map only when source file locations or ownership boundaries change.
