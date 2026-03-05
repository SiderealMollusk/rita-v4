# 0620 - Pangolin Sites + Newt Canonical Model
Status: ACTIVE
Date: 2026-03-04

## Goal

Make Pangolin site lifecycle and VM Newt connector lifecycle first-class, repo-driven, and verifiable.

This plan defines:
1. canonical desired-state files in repo
2. canonical 1Password schema per site
3. script boundaries (host API vs Ansible VM config)
4. verification gates

## Why

Current behavior is split across:
1. manual Pangolin UI site creation
2. ad hoc credential ingestion
3. Newt deployment patterns that are not yet uniform across VM and k8s targets

That creates drift risk and weak idempotency.

## Canonical Sources Of Truth

### 1. Required site records
Add:
- `/Users/virgil/Dev/rita-v4/ops/pangolin/sites/required-sites.yaml`

Schema (one record per site):
1. `slug` (example: `nextcloud_vm`)
2. `display_name` (example: `nextcloud-vm`)
3. `host_alias` (inventory host alias, example: `nextcloud-vm`)
4. `inventory_file` (example: `ops/ansible/inventory/nextcloud.ini`)
5. `connector_mode` (`vm` or `k8s`)
6. `newt_enabled` (`true/false`)
7. `op_item_title` (example: `pangolin_site_nextcloud_vm`)
8. `rebuild_policy` (`reuse` or `rotate`)

### 2. OP item contract
One `Secure Note` per site (no shared site secret record).

Required fields:
1. `endpoint`
2. `name`
3. `identifier`
4. `site_slug`
5. `site_id`
6. `id`
7. `secret`

### 3. Network endpoint source
Use:
- `/Users/virgil/Dev/rita-v4/ops/network/routes.yml`
- key: `pangolin_endpoint`

Do not duplicate endpoint in multiple repo files.

## Script Boundaries

### Host/operator boundary (Pangolin API + OP writes)
Responsibilities:
1. read required sites from `required-sites.yaml`
2. read live sites from Pangolin API
3. create missing sites via API
4. write/update OP items in canonical schema

This remains a host runbook boundary because:
1. Pangolin auth/session and OP write privileges are operator-scoped
2. we want explicit mutation guardrails

### VM configuration boundary (Ansible)
Responsibilities:
1. install Pangolin client/Newt runtime on VM
2. install/manage systemd service
3. read OP site credentials and render runtime env
4. ensure service enabled and healthy

This belongs in Ansible because it is machine-state convergence.

## Required Scripts

### 1. Read-only state check
Add host script:
- `scripts/2-ops/host/26-pangolin-sites-readonly-check.sh`

Checks:
1. required sites file parses
2. live Pangolin site list fetch works
3. required-vs-live diff summary
4. OP item presence/schema check summary

No mutations.

### 2. Site reconcile (operator mutation)
Add host script:
- `scripts/2-ops/host/27-reconcile-pangolin-sites.sh`

Behavior:
1. create missing sites via API
2. for each created site, store canonical OP fields
3. optional `--allow-rotate` mode for controlled secret rotation
4. fail closed on ambiguous matches

### 3. VM Newt wiring
Add workload runbook:
- `scripts/2-ops/workload/21-wire-vm-newt-connectors.sh`

Backed by new playbook(s):
1. install `pangolin` client on VM
2. write connector env from OP-derived values
3. install `systemd` unit
4. start/enable service
5. verify service is active

### 4. End-to-end verification
Add host script:
- `scripts/2-ops/host/28-verify-pangolin-sites-and-newt.sh`

Checks:
1. required sites exist in Pangolin
2. OP schema valid for each required site
3. VM connector service active for `connector_mode: vm`
4. site online signal present in Pangolin status (as available from API)

## Operational Flow

1. `26` read-only check
2. `27` reconcile sites + OP schema
3. `21` wire VM Newt connectors
4. `28` end-to-end verify

## Guardrails

1. No destructive site deletion in first pass.
2. OP writes require operator human session (no service-account write path).
3. Site reconcile must be idempotent.
4. VM wiring must be idempotent.
5. Secrets never written to repo files.

## Acceptance Criteria

1. `required-sites.yaml` is authoritative for required sites.
2. Running `27` twice produces no unintended mutations on second run.
3. Each required site has one valid OP `Secure Note`.
4. Each required VM site has active Newt connector service.
5. `28` returns all-green without UI-only validation steps.

## Initial Scope

Start with:
1. `ops_brain`
2. `nextcloud_vm`
3. `talk_hpb_vm`

Expand only after this set is stable.
