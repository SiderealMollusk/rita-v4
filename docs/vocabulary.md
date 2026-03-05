# Vocabulary

This doc defines the canonical language for this repo.

Use these terms consistently in docs, scripts, plans, and automation.

## Purpose
1. reduce naming drift
2. keep conceptual roles separate from implementation details
3. make it obvious when two files are talking about the same thing

## Naming Rules
1. Prefer one canonical term per concept.
2. If a short alias exists, use it only where the local implementation requires it.
3. Do not invent a new term when an existing repo term already covers the concept.
4. Historical docs may preserve older wording, but current navigation docs should use current canonical terms.

#### Deprecated Name
[Deprecated name: `ops-brain`. Use `observatory`.]

## Canonical Terms
### `observatory`
Meaning:
1. the 16 GB laptop
2. the internal k3s control-plane host
3. the monitoring home
4. the tolerated bootstrap/operator edge

Use it for:
1. node identity
2. cluster-control-plane placement
3. monitoring placement
4. docs and scripts about the laptop host

Do not replace it with:
1. `monitoring node`
2. `laptop`
3. `control plane`

Those may describe it, but they are not the canonical name.

### `platform-node`
Meaning:
1. the conceptual NUC role in the architecture
2. the internal platform-services node
3. the clean declarative platform lane in hardware terms

Use it for:
1. topology docs
2. node-role docs
3. service-placement docs
4. architecture discussions about the NUC role

Do not use it to mean:
1. an arbitrary cluster worker
2. any platform service namespace
3. a GitOps path name by default

### `platform`
Meaning:
1. the concrete worker VM/host identity when that hostname or inventory identity is actually named `platform`

Use it for:
1. VM hostname
2. inventory/group names when the automation explicitly uses `platform`
3. node labels/host-specific runbooks when the implementation uses that exact name

Do not use it as the main replacement for `platform-node` in architecture docs.

Rule:
1. `platform-node` is the conceptual role
2. `platform` is the concrete VM/host identity when applicable

### `platform-nuc`
Meaning:
1. the physical NUC running Proxmox for the platform-node substrate

Use it for:
1. physical host inventory identity
2. Proxmox access
3. VM lifecycle operations on that substrate

### `platform-vm-worker`
Meaning:
1. the worker VM hosted on `platform-nuc`
2. the VM that joins the internal cluster as platform worker capacity

Use it for:
1. inventory identity
2. worker-join automation
3. host-specific automation references

Rule:
1. inventory alias may be `platform-vm-worker`
2. in-guest hostname may still be `platform`

### `platform-vm-newt`
Meaning:
1. the Newt VM hosted on `platform-nuc`

Use it for:
1. inventory identity
2. VM-level references that must distinguish it from the worker VM

### `workload-pve`
Meaning:
1. the physical Proxmox substrate for the `workload-node` lane

Use it for:
1. physical host inventory identity
2. Proxmox inspection and VM lifecycle operations for the workload lane

### `workload-vm-worker`
Meaning:
1. the worker VM hosted on `workload-pve`
2. the future internal-cluster worker used for application and compute placement

Use it for:
1. inventory identity
2. workload worker onboarding automation
3. VM-level references that must distinguish it from `platform-vm-worker`

Rule:
1. inventory alias may be `workload-vm-worker`
2. in-guest hostname may still be `workload`

### `workload-node`
Meaning:
1. the conceptual server role for application and compute workloads

Use it for:
1. topology docs
2. service-placement docs
3. workload-isolation discussions

### `main-vps`
Meaning:
1. the public VPS role in this repo

Use it for:
1. topology docs
2. inventory discussion
3. edge placement discussion

### `public edge runtime`
Meaning:
1. the public-facing edge responsibility layer
2. currently hosted on `main-vps`

Use it when discussing function, not machine identity.

Rule:
1. `main-vps` is the node
2. `public edge runtime` is the role

## Cluster Terms
### `internal cluster`
Meaning:
1. the real internal k3s cluster rooted at `observatory`
2. the cluster that `platform-node` joins as worker capacity

Use it for:
1. cross-node cluster automation
2. cluster-wide inventories and playbooks
3. GitOps targeting for the real internal platform

### `local simulation cluster`
Meaning:
1. local devcontainer/host k8s experiments
2. non-canonical cluster testing contexts such as local k3d/minikube-style environments

Use it to distinguish local experiments from the real internal cluster.

## Execution-Layer Terms
### `worker`
Meaning:
1. the operational script domain for joining and managing non-control-plane k3s worker behavior

Use it for:
1. runbook/script domains like `scripts/2-ops/worker/`
2. generic cluster-worker operations that are not specific to one future machine

Do not use it as a replacement name for `platform-node`.

### `nuc`
Meaning:
1. the Proxmox host / hardware-management runbook domain for the NUC

Use it for:
1. Proxmox inspection
2. VM rebuild operations
3. host-level recovery on the NUC substrate

Rule:
1. `nuc` refers to the hardware/Proxmox layer
2. `platform` refers to the guest VM identity when applicable
3. `platform-node` refers to the architectural role

## Service Terms
### `Flux`
Meaning:
1. the GitOps controller for the internal cluster

Use it instead of:
1. `Argo`
2. `Argo CD`

for current-state docs and plans.

Historical docs may mention `Argo CD` as prior direction only.

### `Gitea`
Meaning:
1. the self-hosted Git forge planned for the internal cluster

### `platform-postgres`
Meaning:
1. the initial shared Postgres service for platform services and early app workloads

Use it for:
1. service identity
2. manifests
3. planning/docs for the shared DB instance

Do not use it to mean:
1. all future database strategy forever
2. a requirement that platform and app data can never split later

## Role Terms
### `bootstrap edge`
Meaning:
1. the tolerated messy, hand-rolled, operator-heavy boundary required to bring up cleaner automation

Current home:
1. primarily `observatory`
2. Mac host for operator-auth/session-bound mutations where appropriate

### `clean declarative lane`
Meaning:
1. the preferred place for GitOps-managed, reproducible platform services

Current home:
1. primarily `platform-node`

This is a style/placement concept, not a host name.

## Language To Avoid
Avoid these as primary terms in current docs:
1. `worker lane`
2. `CI/CD box`
3. `monitoring laptop`
4. `build server`
5. `platform server`

These may be conversationally understandable, but they blur distinctions the repo is trying to keep sharp.

## Precedence
If terms conflict:
1. inventory and current automation paths define implementation names
2. `docs/vocabulary.md` defines canonical repo language
3. current active plans define current intended architecture
4. older progress/history docs are historical, not normative
