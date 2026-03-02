# System Map

This is the single navigation doc for operational truth.
It intentionally links to source files instead of duplicating values.

Use the latest relevant progress note in `docs/progress_log/` as the practical timestamp for how current the linked summaries are.

Reading order for uncertain state:
1. latest relevant progress note
2. machine-readable source files (`inventory`, `group_vars`, `routes`, scripts)
3. clue docs in `docs/`

Validated navigation model: 2026-02-28

## Pangolin Semantics (Pangolin-Server vs CLI vs Newt)
- Canonical reference: `docs/pangolin/0001-deploy-model.md`
- Folder index: `docs/pangolin/README.md`

## External Dependencies
- Source of truth: `docs/dependencies.md`

## Topology / Clusters / Access
- Topology clues: `docs/topology.md`
- Cluster boundaries: `docs/clusters.md`
- Login model and access policy: `docs/access-policy.md`

## Hosts and IPs
- Source of truth: `ops/ansible/inventory/`
- Current files:
  - `ops/ansible/inventory/proxmox.ini`
  - `ops/ansible/inventory/vps.ini`
  - `ops/ansible/inventory/ops-brain.ini`
  - `ops/ansible/inventory/platform.ini`
  - `ops/ansible/inventory/workload.ini`
  - `ops/ansible/inventory/workload-cluster.ini`
  - `ops/ansible/inventory/internal-cluster.ini`

## Automation Variables (domains, namespaces, deploy vars)
- Source of truth: `ops/ansible/group_vars/`
- Current files:
  - `ops/ansible/group_vars/vps.yml`
  - `ops/ansible/group_vars/ops_brain.yml`
  - `ops/ansible/group_vars/platform.yml`
  - `ops/ansible/group_vars/workload.yml`
  - `ops/ansible/group_vars/internal_cluster.yml`

## Hittable Routes (FQDN -> backend/ports/exposure)
- Source of truth: `ops/network/routes.yml`

## Node Inventory (human-readable clues)
- Entry point: `docs/lab-nodes.md`
- Node docs: `docs/nodes/`
- Service placement: `docs/service-placement.md`

## Cluster Boundaries
- Local simulation cluster:
  - Scripts: `scripts/1-session/` and `scripts/2-ops/devcontainer/`
  - Typical context: local k3d (`rita-local`)
- Public edge runtime:
  - Scripts: `scripts/2-ops/vps/`
- Internal ops cluster:
  - Scripts: `scripts/2-ops/ops-brain/` and `scripts/2-ops/worker/`
  - GitOps tree: `ops/gitops/clusters/internal/`

## Secrets (references only; never values)
- Runtime secret source: 1Password
- Pangolin setup/admin tokens are captured post-install and stored in 1Password
- Seed/bootstrap scripts:
  - `scripts/0-local-setup/03-vps/`
  - `scripts/0-local-setup/01-lan/`

## Deployment Runbooks
- Vocabulary/reference rules: `docs/vocabulary.md`
- Freshness/reference rules: `docs/freshness.md`
- Durable machine-onboarding contract: `docs/adding-a-machine.md`
- Current workload onboarding state: `docs/progress_log/0430-workload-node-joined-and-api-policy-extended.md`
- Host/operator-boundary runbooks: `scripts/2-ops/host/`
- VPS runbook scripts: `scripts/2-ops/vps/`
- Ops-brain runbook scripts: `scripts/2-ops/ops-brain/`
- Platform worker runbook scripts: `scripts/2-ops/worker/`
- Workload worker runbook scripts: `scripts/2-ops/workload/`
- NUC/Proxmox runbook scripts: `scripts/2-ops/nuc/`
- Ansible playbooks: `ops/ansible/playbooks/`
- GitOps manifests: `ops/gitops/`
- Human reset playbook: `docs/reset-vps.md`
- Current platform architecture plan: `docs/plans/0160-platform-flux-gitea-and-worker-expansion.md`
- Current platform execution plan: `docs/plans/0170-platform-worker-execution-plan.md`
- Earlier sequencing plan: `docs/plans/0110-ops-brain-platform-workload-sequencing.md`
- Detailed ops-brain plan: `docs/plans/0120-ops-brain-k3s-monitoring-stack.md`
- Detailed Pangolin CLI / access plan: `docs/plans/0130-pangolin-cli-route-management.md`
- Pangolin resource layer plan: `docs/plans/0150-pangolin-resource-management-for-ops-brain.md`
- Additional ops domains:
  - `scripts/2-ops/nuc/`
  - `scripts/2-ops/worker/`
  - `scripts/2-ops/gpu/`

## Current Ordered Capacity
1. Host lane:
- bootstrap identity
- write secrets
- apply Pangolin mutations with host-held auth
2. Devcontainer lane:
- validate repo-driven secrets/contracts
- run reproducible automation
3. Ops-brain lane:
- bootstrap Debian + k3s + Helm
- install Newt
- install monitoring
4. Pangolin resource layer:
- expose validated cluster-local targets from the site perspective

## Change Rule
1. Update canonical source files first.
2. Update this map when source locations or ownership boundaries change.
3. Prefer links and verification paths over duplicated state.
